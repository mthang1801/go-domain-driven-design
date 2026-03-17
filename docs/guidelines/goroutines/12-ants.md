# 12 — Ants

> **Library**: `github.com/panjf2000/ants` — High-performance goroutine pool với auto-scaling.

---

## ① DEFINE

### Định nghĩa

**Ants** là goroutine pool library hiệu năng cao nhất cho Go. Thay vì tạo goroutine mới cho mỗi task → **tái sử dụng** goroutine pool. Giảm overhead tạo/hủy goroutines, giới hạn memory consumption.

### Phân biệt Ants vs Tunny vs errgroup

| Đặc điểm | Ants | Tunny | errgroup.SetLimit |
|-----------|------|-------|-------------------|
| **Pool type** | Dynamic (auto-scale) | Fixed | Fixed |
| **Goroutine reuse** | ✅ (core feature) | ✅ | ❌ (tạo mới) |
| **Return result** | ❌ (fire-and-forget) | ✅ Process() | ❌ |
| **Panic recovery** | ✅ Built-in | ❌ | ❌ |
| **Pre-allocate** | ✅ `PreAlloc` option | ✅ | ❌ |
| **Expiry cleanup** | ✅ Auto-purge idle | ❌ Fixed | N/A |
| **Performance** | ⚡ Fastest | Moderate | Good |

### 2 Pool Types

| Type | API | Use case |
|------|-----|---------|
| **`ants.Pool`** | `Submit(func())` | Fire-and-forget tasks |
| **`ants.PoolWithFunc`** | `Invoke(args)` | Mỗi task nhận args |

### Invariants

- Pool tự động shrink khi idle (configurable expiry)
- `Submit()` block khi pool full — hoặc return error nếu tắt blocking
- `Release()` phải gọi khi done — giải phóng goroutines
- Panic trong task → recovered, pool tiếp tục hoạt động

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Pool exhaustion** | Submit quá nhanh | Buffer, tăng pool size |
| **Memory spike** | Pool quá lớn | Tune pool size = 2× CPU |
| **Quên Release** | Pool goroutines leak | `defer pool.Release()` |

---

## ② GRAPH

### Ants Pool Architecture

```
  Tasks ──▶ Submit(task) ──▶ ┌───────────────────────────────┐
                             │       Ants Pool (N=4)         │
                             │                               │
                             │  ┌────┐ ┌────┐ ┌────┐ ┌────┐│
                             │  │ G1 │ │ G2 │ │ G3 │ │ G4 ││
                             │  │busy│ │idle│ │busy│ │idle ││
                             │  └────┘ └────┘ └────┘ └────┘│
                             │      ↑                  ↑    │
                             │      │   Reuse!    Reuse!    │
                             │      │                  │    │
                             │  Task done → G available    │
                             │  New task → assign to idle G│
                             └───────────────────────────────┘
                                        │
                             Idle timeout (5s) → purge G
                             (auto-scale to save memory)
```

---

## ③ CODE

---

### Example 1: Cơ bản — ants.Pool

**Mục tiêu**: Tạo pool với N goroutines, submit fire-and-forget tasks.

**Cần gì**: `go get github.com/panjf2000/ants/v2`.

```go
package main

import (
    "fmt"
    "sync"
    "sync/atomic"
    "time"

    "github.com/panjf2000/ants/v2"
)

func main() {
    var taskCount atomic.Int64

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ants.NewPool: tạo pool với tối đa 10 goroutines
    // Goroutines được tái sử dụng — không tạo mới mỗi task
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    pool, err := ants.NewPool(10,
        ants.WithPreAlloc(true),                         // Pre-allocate goroutines
        ants.WithExpiryDuration(5*time.Second),          // Idle goroutine timeout
        ants.WithPanicHandler(func(p interface{}) {      // Handle panics
            fmt.Printf("🔥 Panic recovered: %v\n", p)
        }),
    )
    if err != nil {
        panic(err)
    }
    defer pool.Release() // ← LUÔN Release khi done

    var wg sync.WaitGroup

    // Submit 100 tasks — chỉ 10 chạy cùng lúc
    for i := 0; i < 100; i++ {
        wg.Add(1)
        err := pool.Submit(func() {
            defer wg.Done()
            taskCount.Add(1)
            time.Sleep(50 * time.Millisecond) // simulate work
        })
        if err != nil {
            wg.Done()
            fmt.Printf("Submit failed: %v\n", err)
        }
    }

    wg.Wait()

    fmt.Printf("Tasks completed: %d\n", taskCount.Load())
    fmt.Printf("Pool running: %d\n", pool.Running())
    fmt.Printf("Pool free: %d\n", pool.Free())
    fmt.Printf("Pool cap: %d\n", pool.Cap())
}
```

**Kết quả đạt được**:
- 100 tasks xử lý bởi 10 reused goroutines.
- Pre-allocate: goroutines tạo sẵn (tránh allocation khi submit).
- Panic recovery: task panic → pool vẫn hoạt động.

**Lưu ý**:
- `Submit` trả error nếu pool đã release hoặc task bị reject.
- `pool.Release()` giải phóng TẤT CẢ goroutines — gọi 1 lần khi app shutdown.
- `Running()`, `Free()`, `Cap()` cho monitoring.

---

### Example 2: PoolWithFunc — Tasks có arguments

**Mục tiêu**: Pool với fixed function — mỗi task gọi `Invoke(args)` thay vì `Submit(func())`. Hiệu quả hơn khi tất cả tasks cùng logic.

**Cần gì**: `ants/v2`.

```go
package main

import (
    "fmt"
    "math"
    "sync"
    "time"

    "github.com/panjf2000/ants/v2"
)

type ImageTask struct {
    ID     int
    Width  int
    Height int
}

type ImageResult struct {
    TaskID   int
    Resized  string
    Duration time.Duration
}

func main() {
    results := make(chan ImageResult, 50)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // PoolWithFunc: tất cả tasks dùng CÙNG 1 function
    // Invoke(args) gọi function với args
    // Hiệu quả hơn Pool vì function compiled 1 lần
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    pool, err := ants.NewPoolWithFunc(4, func(payload interface{}) {
        task := payload.(ImageTask)
        start := time.Now()

        // Simulate image resize
        pixels := task.Width * task.Height
        time.Sleep(time.Duration(pixels/10000) * time.Millisecond)

        results <- ImageResult{
            TaskID:   task.ID,
            Resized:  fmt.Sprintf("%dx%d → %dx%d", task.Width, task.Height,
                task.Width/2, task.Height/2),
            Duration: time.Since(start),
        }
    })
    if err != nil {
        panic(err)
    }
    defer pool.Release()

    // Submit image tasks
    tasks := []ImageTask{
        {1, 1920, 1080}, {2, 3840, 2160}, {3, 1280, 720},
        {4, 2560, 1440}, {5, 800, 600},   {6, 4096, 2160},
        {7, 1024, 768},  {8, 1600, 900},
    }

    var wg sync.WaitGroup
    for _, task := range tasks {
        wg.Add(1)
        go func(t ImageTask) {
            defer wg.Done()
            pool.Invoke(t) // ← block cho đến có goroutine rảnh
        }(task)
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    for r := range results {
        fmt.Printf("Task %d: %s (%v)\n", r.TaskID, r.Resized, r.Duration)
    }

    _ = math.Abs(0) // suppress unused import
}
```

**Kết quả đạt được**:
- 8 image tasks, 4 workers — xử lý song song.
- `Invoke(payload)` truyền args trực tiếp — không cần wrap trong closure.

**Lưu ý**:
- `PoolWithFunc` tốt hơn `Pool` khi TẤT CẢ tasks cùng logic (ít allocation).
- `Invoke()` blocking — caller đợi có goroutine rảnh.
- Payload là `interface{}` → cần type assertion bên trong function.

---

### Example 3: Options nâng cao — Monitoring & Tuning

**Mục tiêu**: Config pool cho production: custom logger, nonblocking, max blocking tasks.

```go
package main

import (
    "fmt"
    "log"
    "time"

    "github.com/panjf2000/ants/v2"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Production options
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    pool, err := ants.NewPool(10,
        // Pre-allocate goroutines (avoid runtime allocation)
        ants.WithPreAlloc(true),

        // Idle goroutine expiry (auto-scale down)
        ants.WithExpiryDuration(10*time.Second),

        // Non-blocking: Submit return error thay vì block
        ants.WithNonblocking(true),

        // Max blocking tasks: tối đa 100 tasks đợi trong queue
        // Vượt quá → Submit return error
        ants.WithMaxBlockingTasks(100),

        // Panic handler
        ants.WithPanicHandler(func(p interface{}) {
            log.Printf("🔥 Worker panic: %v", p)
        }),

        // Custom logger
        ants.WithLogger(log.Default()),
    )
    if err != nil {
        panic(err)
    }
    defer pool.Release()

    // ━━━ Monitoring ━━━
    go func() {
        for {
            fmt.Printf("📊 Running: %d | Free: %d | Cap: %d\n",
                pool.Running(), pool.Free(), pool.Cap())
            time.Sleep(1 * time.Second)
        }
    }()

    // Submit tasks
    for i := 0; i < 50; i++ {
        err := pool.Submit(func() {
            time.Sleep(500 * time.Millisecond)
        })
        if err != nil {
            fmt.Printf("❌ Submit rejected: %v\n", err) // NonBlocking = true
        }
    }

    time.Sleep(3 * time.Second)

    // ━━━ Resize pool at runtime ━━━
    pool.Tune(20) // scale up to 20
    fmt.Printf("Pool resized to cap: %d\n", pool.Cap())

    // ━━━ Reboot pool (reset all workers) ━━━
    pool.Reboot()
    fmt.Println("Pool rebooted!")
}
```

**Kết quả đạt được**:
- `NonBlocking`: Submit trả error thay vì block → tốt cho HTTP handlers.
- `Tune(n)`: resize pool at runtime — auto-scale.
- `Reboot()`: reset pool — tạo lại workers.

**Lưu ý**:
- **NonBlocking** + `WithMaxBlockingTasks`: combine cho backpressure control.
- `Tune()` cho phép runtime scaling — adjust pool size dựa trên load.
- Ants **benchmark**: 10x ít memory hơn tạo goroutine trực tiếp cho workloads lớn.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên `pool.Release()`** | Goroutines leak | `defer pool.Release()` |
| 2 | **Submit sau Release** | Panic | Check `pool.IsClosed()` |
| 3 | **Pool quá nhỏ** | Tasks queue up → latency | Monitor + Tune() |
| 4 | **interface{} args** | PoolWithFunc type unsafe | Wrap trong typed function |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Ants GitHub | https://github.com/panjf2000/ants |
| Ants GoDoc | https://pkg.go.dev/github.com/panjf2000/ants/v2 |
| Ants Benchmark | https://github.com/panjf2000/ants#-benchmarks |
