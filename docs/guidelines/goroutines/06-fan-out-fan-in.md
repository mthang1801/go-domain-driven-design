# 06 — Fan-out / Fan-in

> **Pattern**: Phân phối work ra nhiều workers (fan-out), gom kết quả lại 1 chỗ (fan-in).

---

## ① DEFINE

### Phân biệt Fan-out vs Fan-in

| Concept | Hướng | Mô tả |
|---------|-------|-------|
| **Fan-out** | 1 → N | 1 input channel → N worker goroutines xử lý song song |
| **Fan-in** | N → 1 | N source channels → merge vào 1 output channel |

### Use cases

- **Fan-out**: CPU-intensive tasks (image processing, hash), I/O-bound tasks (HTTP requests, DB queries)
- **Fan-in**: Aggregate kết quả từ nhiều sources, merge multiple log streams

### Invariants

- **Order** KHÔNG được bảo toàn — G nào xong trước push trước (non-deterministic)
- Output channel phải **đóng đúng thời điểm** — sau khi TẤT CẢ workers hoàn thành
- Dùng `sync.WaitGroup` hoặc `errgroup` để track workers

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Close output sớm** | Close trước khi worker xong → panic | `wg.Wait()` rồi mới `close()` |
| **Goroutine leak** | Worker block trên full output channel | Buffer output hoặc check ctx |
| **Memory spike** | Fan-out quá nhiều workers | Limit workers = `runtime.NumCPU()` |

---

## ② GRAPH

### Fan-out: 1 → N

```
                    Fan-out
                    ┌──────────▶ Worker 1 ──▶ result
                    │
  input channel ────┼──────────▶ Worker 2 ──▶ result
                    │
                    └──────────▶ Worker 3 ──▶ result

  1 channel, nhiều goroutines cùng đọc (Go channel safe cho multi-reader)
```

### Fan-in: N → 1

```
  Source 1 ────┐
               │
  Source 2 ────┼──────────▶ merge() ──▶ 1 output channel
               │
  Source 3 ────┘

  N channels → 1 goroutine merge → 1 output
```

### Kết hợp Fan-out + Fan-in

```
                   Fan-out                          Fan-in
               ┌──▶ Worker 1 ──┐
               │                │
  input ───────┼──▶ Worker 2 ──┼──── merge() ────▶ output
               │                │
               └──▶ Worker 3 ──┘

  Timing (non-deterministic):
  W1: ━━━━━━━━━━━ done (300ms)           output: W2, W3, W1
  W2: ━━━━━ done (150ms)                 (ai xong trước push trước)
  W3: ━━━━━━━ done (220ms)
```

---

## ③ CODE

---

### Example 1: Fan-out — Multiple workers đọc từ 1 channel

**Mục tiêu**: Phân phối jobs từ 1 input channel cho N workers xử lý song song. Đây là pattern đơn giản nhất của fan-out.

**Cần gì**: Go standard library.

```go
package main

import (
    "fmt"
    "math/rand"
    "sync"
    "time"
)

func worker(id int, jobs <-chan int, results chan<- string, wg *sync.WaitGroup) {
    defer wg.Done()
    for job := range jobs {
        // ━━━ Simulate CPU work ━━━
        duration := time.Duration(50+rand.Intn(200)) * time.Millisecond
        time.Sleep(duration)

        results <- fmt.Sprintf("Worker %d: job %d → %d² = %d (took %v)",
            id, job, job, job*job, duration)
    }
}

func main() {
    const numWorkers = 4
    const numJobs = 20

    jobs := make(chan int, numJobs)
    results := make(chan string, numJobs)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Fan-out: 4 workers cùng đọc từ 1 channel
    // Go channel thread-safe cho multi-reader:
    // mỗi job chỉ được ĐÚNG 1 worker xử lý
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var wg sync.WaitGroup
    for w := 1; w <= numWorkers; w++ {
        wg.Add(1)
        go worker(w, jobs, results, &wg)
    }

    // Producer: gửi 20 jobs
    for j := 1; j <= numJobs; j++ {
        jobs <- j
    }
    close(jobs) // ← signal workers dừng

    // Goroutine: đóng results khi tất cả workers xong
    go func() {
        wg.Wait()
        close(results)
    }()

    // Consumer: đọc kết quả
    for r := range results {
        fmt.Println(r)
    }
}
```

**Kết quả đạt được**:
- 20 jobs phân phối đều cho 4 workers (~5 jobs mỗi worker).
- Thứ tự output **non-deterministic** — worker nào xong trước in trước.
- Tổng thời gian ≈ 20 × avg_time / 4 workers.

**Lưu ý**:
- Go channel **goroutine-safe** — mỗi receive chỉ 1 goroutine nhận được.
- `close(jobs)` quan trọng: workers dùng `range` tự dừng khi channel đóng.
- `close(results)` phải **sau** `wg.Wait()` — tránh panic "send on closed channel".

---

### Example 2: Fan-in — Merge nhiều channels thành 1

**Mục tiêu**: Gom output từ nhiều sources (channels) vào 1 channel duy nhất. Đây là merge function kinh điển.

**Cần gì**: Go standard library.

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// merge: fan-in N channels → 1 output channel
//
// Cách hoạt động:
// - 1 goroutine cho mỗi source channel (đọc + gửi vào output)
// - WaitGroup đếm xong tất cả sources → close output
// - Output là <-chan: caller chỉ đọc, không ghi
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func merge(channels ...<-chan string) <-chan string {
    out := make(chan string)
    var wg sync.WaitGroup

    // 1 goroutine per source channel
    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan string) {
            defer wg.Done()
            for val := range c {
                out <- val // forward tất cả values vào output
            }
        }(ch)
    }

    // Goroutine: close output khi tất cả sources đã đóng
    go func() {
        wg.Wait()
        close(out)
    }()

    return out // ← return ngay, data stream lazy
}

// Simulate 1 data source
func source(name string, count int, interval time.Duration) <-chan string {
    ch := make(chan string)
    go func() {
        defer close(ch)
        for i := 1; i <= count; i++ {
            time.Sleep(interval)
            ch <- fmt.Sprintf("[%s] item %d", name, i)
        }
    }()
    return ch
}

func main() {
    // ━━━ 3 sources với tốc độ khác nhau ━━━
    fast := source("Fast", 5, 50*time.Millisecond)     // 50ms/item
    medium := source("Medium", 3, 150*time.Millisecond) // 150ms/item
    slow := source("Slow", 2, 300*time.Millisecond)     // 300ms/item

    // ━━━ Fan-in: merge tất cả vào 1 stream ━━━
    merged := merge(fast, medium, slow)

    for msg := range merged {
        fmt.Println(msg)
    }
    fmt.Println("\nAll sources drained!")
}
```

**Kết quả đạt được**:
- 3 sources merge vào 1 output — consumer đọc từ 1 chỗ.
- Output interleaved: `Fast` items đến trước do interval ngắn hơn.
- `merge()` trả **lazy channel** — data stream khi ready.

**Lưu ý**:
- `merge()` là **reusable** — dùng cho bất kỳ `<-chan string`.
- N sources = N goroutines trong merge — cẩn thận với số lượng lớn.
- `range merged` tự dừng khi tất cả sources đã đóng + WaitGroup done.

---

### Example 3: Fan-out + Fan-in — Complete pipeline

**Mục tiêu**: Kết hợp fan-out (phân phối work) + fan-in (gom kết quả) trong 1 pipeline hoàn chỉnh. Đây là pattern phổ biến nhất trong Go concurrency.

**Cần gì**: Go standard library + `context` cho cancellation.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "runtime"
    "sync"
    "time"
)

// stage1: generate URLs to crawl
func generateURLs(ctx context.Context) <-chan string {
    out := make(chan string)
    go func() {
        defer close(out)
        urls := []string{
            "https://api.example.com/users",
            "https://api.example.com/orders",
            "https://api.example.com/products",
            "https://api.example.com/categories",
            "https://api.example.com/reviews",
            "https://api.example.com/inventory",
            "https://api.example.com/payments",
            "https://api.example.com/shipping",
        }
        for _, url := range urls {
            select {
            case <-ctx.Done():
                return
            case out <- url:
            }
        }
    }()
    return out
}

// stage2: fan-out — N workers fetch URLs đồng thời
func fetchAll(ctx context.Context, urls <-chan string, numWorkers int) <-chan string {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Mỗi worker tạo 1 output channel riêng
    // Sau đó merge tất cả vào 1 channel (fan-in)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var channels []<-chan string

    // Fan-out: create N workers
    for i := 0; i < numWorkers; i++ {
        ch := make(chan string)
        channels = append(channels, ch)
        go func(workerID int, out chan<- string) {
            defer close(out)
            for url := range urls {
                select {
                case <-ctx.Done():
                    return
                default:
                }

                // Simulate HTTP fetch
                delay := time.Duration(100+rand.Intn(300)) * time.Millisecond
                time.Sleep(delay)
                out <- fmt.Sprintf("[W%d] Fetched %s (%v)", workerID, url, delay)
            }
        }(i+1, ch)
    }

    // Fan-in: merge all worker outputs
    return mergeChannels(channels...)
}

// mergeChannels: fan-in helper — merge N channels vào 1
func mergeChannels(channels ...<-chan string) <-chan string {
    out := make(chan string)
    var wg sync.WaitGroup
    for _, ch := range channels {
        wg.Add(1)
        go func(c <-chan string) {
            defer wg.Done()
            for v := range c {
                out <- v
            }
        }(ch)
    }
    go func() {
        wg.Wait()
        close(out)
    }()
    return out
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    // Pipeline: generate → fan-out/fan-in fetch → consume results
    numWorkers := runtime.NumCPU()
    fmt.Printf("Starting pipeline with %d workers\n\n", numWorkers)

    urls := generateURLs(ctx)
    results := fetchAll(ctx, urls, numWorkers)

    // Consume results
    count := 0
    for result := range results {
        count++
        fmt.Printf("#%d %s\n", count, result)
    }
    fmt.Printf("\nTotal: %d URLs fetched\n", count)
}
```

**Kết quả đạt được**:
- 8 URLs phân phối cho `NumCPU()` workers song song.
- Tổng thời gian ≈ 8 × avg_delay / NumCPU (e.g. 4 CPUs → ~2× nhanh hơn sequential).
- Context timeout bảo vệ toàn bộ pipeline.

**Lưu ý**:
- **`runtime.NumCPU()`** là worker count mặc định tốt cho CPU-bound work.
- Cho I/O-bound work: workers có thể >> NumCPU (e.g. 50-100).
- Thứ tự output **non-deterministic** — nếu cần order, dùng index + sort.
- Pattern này là nền tảng cho Pipeline (xem `07-pipeline.md`).

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Close output trước wg.Wait()** | Luôn: `wg.Wait()` → `close(out)` |
| 2 | **Worker block trên full output** | Buffer output channel hoặc check ctx.Done() |
| 3 | **Quá nhiều workers** | CPU-bound: `NumCPU()` · I/O-bound: benchmark |
| 4 | **Quên cancel context** | Workers leak nếu context không cancel |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Go Blog — Pipelines and Cancellation | https://go.dev/blog/pipelines |
| Go Concurrency Patterns (Rob Pike) | https://go.dev/talks/2012/concurrency.slide |
| Concurrency in Go (O'Reilly) | ISBN: 978-1491941195 |
