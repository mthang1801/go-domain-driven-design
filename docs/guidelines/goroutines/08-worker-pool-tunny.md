# 08 — Worker Pool & Tunny

> **Pattern**: Giới hạn số goroutines xử lý song song. Tunny = worker pool library cho Go.

---

## ① DEFINE

### Worker Pool

**Worker Pool** là pattern tạo sẵn N worker goroutines, jobs được gửi qua channel, worker rảnh tự pick up job tiếp. Giới hạn concurrency để tránh overwhelm resources (CPU, memory, DB connections).

### Tunny

**[Tunny](https://github.com/Jeffail/tunny)** là Go library cung cấp worker pool với:
- **Fixed pool size**: N workers cố định
- **Blocking `Process()`**: caller block cho đến khi worker rảnh
- **Timeout `ProcessTimed()`**: trả error nếu không có worker rảnh trong thời gian chờ
- **Context `ProcessCtx()`**: hủy khi context cancel

### Phân biệt các cách tạo Worker Pool

| Cách | Pros | Cons |
|------|------|------|
| **Channel-based (DIY)** | Full control, no dependency | Phải tự handle nhiều thứ |
| **Tunny** | Production-ready, timeout, ctx | External dependency |
| **errgroup.SetLimit** | Built-in, error handling | Không reuse goroutines |
| **Semaphore (chan struct{})** | Simple | Không phải true pool |

### Invariants

- Pool size nên = **resources available** (CPU cores, DB pool size)
- `Process()` **synchronous** — caller block cho đến khi kết quả trả về
- Worker goroutines **reuse** — tạo 1 lần, xử lý nhiều jobs
- `defer pool.Close()` — giải phóng workers khi done

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Pool quá nhỏ** | Jobs queue up, latency tăng | Benchmark, tune pool size |
| **Pool quá lớn** | Context switch overhead, resource waste | Start với NumCPU, scale dần |
| **Quên Close()** | Workers leak forever | `defer pool.Close()` |
| **Process() timeout** | No worker available | Dùng `ProcessTimed()` hoặc `ProcessCtx()` |

---

## ② GRAPH

### Worker Pool Architecture

```
                    ┌────────────────────────────────────┐
                    │         Worker Pool (N=4)          │
                    │                                    │
  Job Queue   ──────┤  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │
  (channel)         │  │ W1   │ │ W2   │ │ W3   │ │ W4   │ │
                    │  │ busy │ │ idle │ │ busy │ │ idle │ │
  Process(job) ─────┤  └──────┘ └──────┘ └──────┘ └──────┘ │
  → block until     │         ▲                    ▲       │
    worker free     │         │ W2 picks up job    │       │
                    └─────────┼────────────────────┼───────┘
                              │                    │
                    Result ◀──┘      Result ◀──────┘
```

### Tunny vs DIY workflow

```
Tunny:
  caller ── pool.Process(data) ── [BLOCK] ── result
                     │
              worker picks up
              processes
              returns result

DIY (Channel):
  caller ── jobs <- data ── worker reads ── results <- output ── caller reads
            (may block)      (goroutine)     (need separate channel)
```

---

## ③ CODE

---

### Example 1: DIY Worker Pool — Channel-based

**Mục tiêu**: Xây worker pool từ đầu bằng channels. Hiểu core concept trước khi dùng library.

**Cần gì**: Go standard library.

```go
package main

import (
    "fmt"
    "math/rand"
    "sync"
    "time"
)

// Job mô tả 1 unit of work
type Job struct {
    ID    int
    Input int
}

// Result mô tả kết quả sau khi worker xử lý
type Result struct {
    JobID    int
    WorkerID int
    Output   int
    Duration time.Duration
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// worker: goroutine chạy liên tục
// - Đọc jobs từ channel (block khi hết jobs)
// - Xử lý → gửi result
// - Dừng khi jobs channel đóng (range tự stop)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func worker(id int, jobs <-chan Job, results chan<- Result, wg *sync.WaitGroup) {
    defer wg.Done()
    for job := range jobs {
        start := time.Now()

        // Simulate CPU work
        time.Sleep(time.Duration(50+rand.Intn(200)) * time.Millisecond)
        output := job.Input * job.Input

        results <- Result{
            JobID:    job.ID,
            WorkerID: id,
            Output:   output,
            Duration: time.Since(start),
        }
    }
    fmt.Printf("[Worker %d] No more jobs, exiting\n", id)
}

func main() {
    const numWorkers = 4
    const numJobs = 15

    jobs := make(chan Job, numJobs)
    results := make(chan Result, numJobs)

    // ━━━ Start worker pool ━━━
    var wg sync.WaitGroup
    for w := 1; w <= numWorkers; w++ {
        wg.Add(1)
        go worker(w, jobs, results, &wg)
    }

    // ━━━ Submit jobs ━━━
    for j := 1; j <= numJobs; j++ {
        jobs <- Job{ID: j, Input: j}
    }
    close(jobs) // ← signal workers: no more jobs

    // ━━━ Close results khi tất cả workers done ━━━
    go func() {
        wg.Wait()
        close(results)
    }()

    // ━━━ Consume results ━━━
    for r := range results {
        fmt.Printf("Job %2d: %d² = %3d  [Worker %d, %v]\n",
            r.JobID, r.JobID, r.Output, r.WorkerID, r.Duration)
    }
}
```

**Kết quả đạt được**:
- 15 jobs xử lý bởi 4 workers — mỗi worker xử lý ~4 jobs.
- Workers tự động pick up job tiếp khi rảnh — load balancing tự nhiên.
- Worker nào nhanh hơn → nhận nhiều jobs hơn.

**Lưu ý**:
- `close(jobs)` signal tất cả workers dừng (qua `range`).
- `close(results)` phải sau `wg.Wait()` — đợi workers gửi hết results.
- DIY pool tốt cho learning, nhưng Tunny tốt hơn cho production (timeout, ctx, etc.).

---

### Example 2: Tunny — Basic Usage

**Mục tiêu**: Dùng Tunny library tạo worker pool. So sánh API đơn giản hơn DIY nhiều.

**Cần gì**: `github.com/Jeffail/tunny`.

```go
package main

import (
    "fmt"
    "math/rand"
    "sync"
    "time"

    "github.com/Jeffail/tunny"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // tunny.NewFunc: tạo pool với function handler
    //   - Arg 1: pool size (số workers)
    //   - Arg 2: function xử lý mỗi job
    //   - Return interface{} → cần type assert
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    pool := tunny.NewFunc(4, func(payload interface{}) interface{} {
        n := payload.(int)
        // Simulate work
        time.Sleep(time.Duration(100+rand.Intn(200)) * time.Millisecond)
        return n * n
    })
    defer pool.Close() // ← QUAN TRỌNG: giải phóng workers

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // pool.Process(data):
    // - BLOCKING: caller đợi cho đến khi worker xong
    // - Nếu tất cả workers busy → caller đợi worker rảnh
    // - Return: result từ worker function
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var wg sync.WaitGroup
    for i := 1; i <= 20; i++ {
        wg.Add(1)
        go func(n int) {
            defer wg.Done()
            result := pool.Process(n) // ← blocking call
            fmt.Printf("%d² = %d\n", n, result.(int))
        }(i)
    }
    wg.Wait()

    fmt.Println("\nPool size:", pool.GetSize()) // 4
}
```

**Kết quả đạt được**:
- API đơn giản: `NewFunc` + `Process` + `Close`.
- 20 concurrent callers nhưng chỉ 4 workers chạy cùng lúc.
- `Process()` blocking — caller tự động đợi worker rảnh.

**Lưu ý**:
- `Process()` trả `interface{}` → phải type assert (type-unsafe).
- `pool.Close()` giải phóng worker goroutines — **LUÔN `defer Close()`**.
- Tunny workers **reuse** goroutines — không tạo mới cho mỗi job.

---

### Example 3: Tunny — ProcessCtx + ProcessTimed

**Mục tiêu**: Xử lý timeout và context cancellation với Tunny — tránh caller block mãi khi tất cả workers busy.

**Cần gì**: `github.com/Jeffail/tunny`, `context` package.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "time"

    "github.com/Jeffail/tunny"
)

func main() {
    // Pool nhỏ (2 workers) để dễ thấy timeout/busy
    pool := tunny.NewFunc(2, func(payload interface{}) interface{} {
        n := payload.(int)
        // Simulate heavy work: 500ms - 2s
        duration := time.Duration(500+rand.Intn(1500)) * time.Millisecond
        time.Sleep(duration)
        return fmt.Sprintf("%d² = %d (took %v)", n, n*n, duration)
    })
    defer pool.Close()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ProcessTimed: timeout nếu không có worker rảnh trong N ms
    // Return error nếu timeout
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("=== ProcessTimed (timeout 1s) ===")
    for i := 1; i <= 5; i++ {
        go func(n int) {
            result, err := pool.ProcessTimed(n, time.Second)
            if err != nil {
                fmt.Printf("❌ Job %d: %v\n", n, err) // timeout
                return
            }
            fmt.Printf("✅ Job %d: %s\n", n, result.(string))
        }(i)
    }
    time.Sleep(3 * time.Second) // đợi xong

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ProcessCtx: cancel qua context
    // Tích hợp với HTTP request context, parent context...
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("\n=== ProcessCtx (context timeout 800ms) ===")
    ctx, cancel := context.WithTimeout(context.Background(), 800*time.Millisecond)
    defer cancel()

    result, err := pool.ProcessCtx(ctx, 42)
    if err != nil {
        fmt.Printf("❌ ProcessCtx: %v\n", err) // context deadline exceeded
    } else {
        fmt.Printf("✅ ProcessCtx: %s\n", result.(string))
    }
}
```

**Kết quả đạt được**:
- `ProcessTimed`: jobs vượt 1s timeout → trả error, không block mãi.
- `ProcessCtx`: tích hợp context — HTTP handler cancel → worker stop.

**Lưu ý**:
- **`ProcessTimed` vs `ProcessCtx`**: Dùng `ProcessCtx` trong HTTP handlers (có `r.Context()`).
- Timeout = **tổng thời gian** (đợi worker + xử lý), không chỉ thời gian đợi.
- Worker goroutine **vẫn chạy** sau khi caller timeout — chỉ kết quả bị bỏ qua.

---

### Example 4: Worker Pool Manager — Tunny + sync.Pool + Errgroup

**Mục tiêu**: Pattern production: Tunny pool cho concurrency limit, sync.Pool cho buffer reuse, errgroup cho error handling. 3 thành phần phối hợp.

**Cần gì**: `tunny`, `errgroup`, `sync` packages.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "sync"
    "time"

    "github.com/Jeffail/tunny"
    "golang.org/x/sync/errgroup"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PoolManager: quản lý worker pool + buffer pool
// - Tunny: giới hạn concurrency
// - sync.Pool: reuse buffers (giảm GC)
// - Errgroup: error propagation + context cancel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type PoolManager struct {
    workerPool *tunny.Pool
    bufferPool *sync.Pool
}

func NewPoolManager(workerCount int, bufferSize int) *PoolManager {
    pm := &PoolManager{
        bufferPool: &sync.Pool{
            New: func() interface{} {
                return make([]byte, bufferSize)
            },
        },
    }

    pm.workerPool = tunny.NewFunc(workerCount, func(payload interface{}) interface{} {
        task := payload.(Task)

        // GET buffer từ pool
        buf := pm.bufferPool.Get().([]byte)
        defer pm.bufferPool.Put(buf) // PUT lại khi xong

        // Simulate processing with buffer
        copy(buf, []byte(fmt.Sprintf("task-%d-data", task.ID)))
        time.Sleep(time.Duration(50+rand.Intn(200)) * time.Millisecond)

        // 3% chance of error
        if rand.Float32() < 0.03 {
            return TaskResult{ID: task.ID, Error: fmt.Errorf("processing failed")}
        }

        return TaskResult{
            ID:     task.ID,
            Output: fmt.Sprintf("Processed: %s", buf[:20]),
        }
    })

    return pm
}

func (pm *PoolManager) Close() {
    pm.workerPool.Close()
}

type Task struct {
    ID int
}

type TaskResult struct {
    ID     int
    Output string
    Error  error
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    // ━━━ Tạo Pool Manager: 4 workers, 1KB buffers ━━━
    pm := NewPoolManager(4, 1024)
    defer pm.Close()

    eg, ctx := errgroup.WithContext(ctx)
    results := make(chan TaskResult, 50)

    // ━━━ Submit 30 tasks qua errgroup ━━━
    for i := 1; i <= 30; i++ {
        i := i
        eg.Go(func() error {
            // ProcessCtx: cancel khi context cancel
            raw, err := pm.workerPool.ProcessCtx(ctx, Task{ID: i})
            if err != nil {
                return fmt.Errorf("task %d: %w", i, err)
            }

            result := raw.(TaskResult)
            if result.Error != nil {
                return fmt.Errorf("task %d: %w", i, result.Error)
            }

            results <- result
            return nil
        })
    }

    // ━━━ Collect results ━━━
    go func() {
        eg.Wait()
        close(results)
    }()

    // ━━━ Print results ━━━
    success := 0
    for r := range results {
        success++
        if success <= 5 {
            fmt.Printf("✅ Task %2d: %s\n", r.ID, r.Output)
        }
    }

    if err := eg.Wait(); err != nil {
        fmt.Printf("\n❌ Pipeline error: %v\n", err)
    }
    fmt.Printf("\n📊 Results: %d/%d tasks succeeded\n", success, 30)
}
```

**Kết quả đạt được**:
- `PoolManager` gói gọn: Tunny (concurrency) + sync.Pool (memory) + errgroup (errors).
- 30 tasks, 4 concurrent, buffer reuse, context-aware.
- Production pattern cho image processing, batch jobs, API aggregation.

**Lưu ý**:
- `PoolManager` nên là **singleton** hoặc **dependency-injected** — tạo 1 lần, dùng nhiều lần.
- `pm.Close()` giải phóng worker goroutines — **LUÔN cleanup**.
- Kết hợp 3 patterns: pool size limits concurrency, sync.Pool limits allocation, errgroup limits error impact.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên `pool.Close()`** | Worker goroutines leak forever |
| 2 | **Pool size quá lớn** | Overhead > benefit | Start NumCPU, benchmark |
| 3 | **Process() block mãi** | Dùng ProcessTimed hoặc ProcessCtx |
| 4 | **Type assertion fail** | Tunny trả interface{} | Check type hoặc dùng wrapper |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Tunny GitHub | https://github.com/Jeffail/tunny |
| Tunny GoDoc | https://pkg.go.dev/github.com/Jeffail/tunny |
| Go Worker Pool Pattern | https://gobyexample.com/worker-pools |
