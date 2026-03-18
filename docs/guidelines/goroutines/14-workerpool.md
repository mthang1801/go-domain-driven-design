# 14 — Workerpool

> **Library**: `github.com/gammazero/workerpool` — Bounded worker pool đơn giản.

---

## ① DEFINE

### Định nghĩa

**Workerpool** là lightweight worker pool library — API cực kỳ đơn giản: `Submit(func())` và `StopWait()`. Phù hợp khi cần giới hạn concurrency mà không cần features phức tạp (timeout, results, weighted).

### Phân biệt Workerpool vs Ants vs Tunny

| Đặc điểm | Workerpool | Ants | Tunny |
|-----------|-----------|------|-------|
| **API** | Submit + StopWait | Submit + Release | Process (blocking) |
| **Return result** | ❌ | ❌ | ✅ |
| **Queue overflow** | Unbounded queue | Configurable | Block |
| **Goroutine reuse** | ✅ | ✅ | ✅ |
| **Complexity** | ⭐ Simplest | ⭐⭐⭐ | ⭐⭐ |
| **Best for** | Simple batch jobs | High-perf servers | Request-response |

### API

| Method | Mô tả |
|--------|-------|
| `New(maxWorkers)` | Tạo pool với N workers |
| `Submit(func())` | Submit task — queue nếu workers busy |
| `SubmitWait(func())` | Submit + block cho đến task xong |
| `StopWait()` | Đợi tất cả tasks xong, rồi stop pool |
| `Stop()` | Cancel pending tasks, stop immediately |
| `WaitingQueueSize()` | Số tasks đang đợi trong queue |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Memory leak** | Queue unbounded + submit nhanh | Monitor WaitingQueueSize |
| **Quên StopWait** | Goroutines leak | `defer pool.StopWait()` |

---

## ② GRAPH

```
  Workerpool (maxWorkers=3)

  Submit(t1) → Worker 1 ━━━━━ done → pick t4
  Submit(t2) → Worker 2 ━━━━━━━ done → pick t5
  Submit(t3) → Worker 3 ━━━━ done → pick t6
  Submit(t4) → Queue [t4] ← đợi worker rảnh
  Submit(t5) → Queue [t5]
  Submit(t6) → Queue [t6]

  StopWait() → đợi t1..t6 xong → stop all workers
```

---

## ③ CODE

---

### Example 1: Cơ bản — Batch file processing

**Mục tiêu**: Xử lý 50 files nhưng chỉ 5 concurrent — đơn giản nhất có thể.

**Cần gì**: `go get github.com/gammazero/workerpool`.

```go
package main

import (
    "fmt"
    "math/rand"
    "sync/atomic"
    "time"

    "github.com/gammazero/workerpool"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // New(5): max 5 concurrent workers
    // Submit(func()): queue task, worker picks up khi rảnh
    // StopWait(): đợi TẤT CẢ tasks hoàn thành
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    wp := workerpool.New(5)

    var processed atomic.Int64

    for i := 0; i < 50; i++ {
        fileID := i
        wp.Submit(func() {
            // Simulate file processing
            delay := time.Duration(50+rand.Intn(200)) * time.Millisecond
            time.Sleep(delay)
            processed.Add(1)

            if fileID < 5 {
                fmt.Printf("  File %d processed (%v)\n", fileID, delay)
            }
        })
    }

    fmt.Printf("Queued: %d tasks waiting\n", wp.WaitingQueueSize())

    // ━━━ StopWait: đợi tất cả xong rồi stop ━━━
    wp.StopWait()
    fmt.Printf("✅ Processed: %d files\n", processed.Load())
}
```

**Kết quả đạt được**:
- 50 files, 5 concurrent — đơn giản với 2 lines: `Submit` + `StopWait`.
- Queue tự động buffer tasks khi workers busy.

**Lưu ý**:
- `Submit` **không block** — task được queue. Workers pick up tự động.
- `StopWait()` block cho đến khi TẤT CẢ tasks (cả queued) hoàn thành.
- `Stop()` khác `StopWait()`: `Stop()` **cancel pending** tasks trong queue.

---

### Example 2: SubmitWait + Monitoring

**Mục tiêu**: `SubmitWait` cho synchronous execution, kết hợp monitoring queue size.

```go
package main

import (
    "fmt"
    "time"

    "github.com/gammazero/workerpool"
)

func main() {
    wp := workerpool.New(3)

    // ━━━ Submit nhiều tasks trước ━━━
    for i := 0; i < 20; i++ {
        i := i
        wp.Submit(func() {
            time.Sleep(200 * time.Millisecond)
            fmt.Printf("  Background task %d done\n", i)
        })
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // SubmitWait: submit + BLOCK cho đến task này xong
    // Hữu ích khi cần kết quả ngay
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Printf("Queue size before SubmitWait: %d\n", wp.WaitingQueueSize())

    wp.SubmitWait(func() {
        fmt.Println("  🔴 PRIORITY task executing! (blocking caller)")
        time.Sleep(100 * time.Millisecond)
    })
    fmt.Println("  🔴 PRIORITY task done (caller unblocked)")

    // ━━━ Monitoring loop ━━━
    go func() {
        for {
            qs := wp.WaitingQueueSize()
            if qs == 0 {
                break
            }
            fmt.Printf("  📊 Queue: %d tasks waiting\n", qs)
            time.Sleep(500 * time.Millisecond)
        }
    }()

    wp.StopWait()
    fmt.Println("✅ All done!")
}
```

**Kết quả đạt được**:
- `SubmitWait`: caller block cho đến khi task xong — useful cho priority tasks.
- Monitoring: `WaitingQueueSize()` cho queue depth.

**Lưu ý**:
- `SubmitWait` task vẫn phải đợi **queue position** — không bypass queue.
- Queue **unbounded** — nếu submit nhanh hơn process → memory grow. Monitor!

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên StopWait** | Workers + goroutines leak | `defer wp.StopWait()` |
| 2 | **Unbounded queue** | Memory grow vô hạn | Monitor WaitingQueueSize, backpressure |
| 3 | **Submit sau Stop** | Panic | Check pool state |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Workerpool GitHub | https://github.com/gammazero/workerpool |
| Workerpool GoDoc | https://pkg.go.dev/github.com/gammazero/workerpool |

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **Need results** | Tunny `Process()` | Return values từ workers — xem [08](./08-worker-pool-tunny.md) |
| **High-perf** | Ants | Auto-scale, pre-allocate — xem [12-ants.md](./12-ants.md) |
| **Type-safe** | `sourcegraph/conc` | Generic ResultPool — xem [13-conc.md](./13-conc.md) |
| **Distributed** | Asynq | Redis-backed task queue — xem [15-asynq.md](./15-asynq.md) |
| **Backpressure** | Monitor WaitingQueueSize | Alert khi queue quá lớn |
| **Batch + GORM** | Workerpool + GORM batch insert | Background data import — xem [go-orm/02](../go-orm/02-crud.md) |
