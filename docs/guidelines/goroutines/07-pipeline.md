# 07 — Pipeline Pattern

> **Pattern**: Chain of processing stages kết nối bằng channels — mỗi stage nhận input, xử lý, trả output.

---

## ① DEFINE

### Định nghĩa

**Pipeline** là chuỗi các **stages** nối tiếp nhau bằng channels. Mỗi stage:
1. Nhận data từ **inbound channel** (upstream)
2. Xử lý (transform, filter, aggregate)
3. Gửi kết quả đến **outbound channel** (downstream)

### Quy tắc Pipeline

| Quy tắc | Chi tiết |
|---------|---------|
| **Ownership** | Stage creates → stage closes outbound channel |
| **Cancellation** | Mọi stage phải check `ctx.Done()` |
| **Backpressure** | Stage chậm → upstream block (built-in nhờ channel) |
| **Composability** | Stages là functions, có thể tổ hợp tạo pipeline mới |

### Phân biệt Pipeline vs Fan-out/Fan-in

| | Pipeline | Fan-out/Fan-in |
|--|----------|---------------|
| **Flow** | A → B → C (sequential stages) | A → [B1,B2,B3] → C (parallel stage) |
| **Use case** | Transform chain | Parallel processing |
| **Kết hợp** | Pipeline stage CÓ THỂ là fan-out/fan-in |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Pipeline stall** | 1 stage chậm → chặn toàn bộ | Buffer channel hoặc fan-out stage chậm |
| **Goroutine leak** | Stage không check cancellation | Luôn `select { case <-ctx.Done() }` |
| **Data loss** | Close channel sớm | Chỉ close khi xác nhận hết data |

---

## ② GRAPH

### 3-Stage Pipeline

```
  Stage 1           Stage 2           Stage 3
  (Generate)        (Transform)       (Filter)

  ┌─────────┐   ch1  ┌─────────┐  ch2  ┌─────────┐   output
  │ gen()   │ ──────▶ │ square()│ ─────▶│ filter()│ ──────▶ consumer
  │ 1,2,3.. │        │ → n²    │       │ > 10    │
  └─────────┘        └─────────┘       └─────────┘

  Data flow: 1 → 1² = 1 (skip) → | 2 → 2² = 4 (skip) → | 4 → 4² = 16 ✅
```

### Pipeline with Backpressure

```
  Fast Stage          Slow Stage          Consumer
  (100 items/s)       (10 items/s)

  ┌─────────┐ ch(5) ┌──────────┐ ch(5)
  │gen()    │──────▶│transform()│──────▶ consumer
  └─────────┘       └──────────┘

  Buffer full (5/5) → gen() BLOCKS → tự động backpressure
  Không mất data, không overwhelm slow stage ✅
```

---

## ③ CODE

---

### Example 1: Cơ bản — 3-Stage Pipeline

**Mục tiêu**: Xây dựng pipeline function-based: generate → square → filter. Mỗi stage là 1 function trả về `<-chan`.

**Cần gì**: Go standard library.

```go
package main

import (
    "context"
    "fmt"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stage 1: Generate — tạo dãy số
// Rule: function tạo channel → function close channel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func generate(ctx context.Context, nums ...int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out) // ← OWNER closes
        for _, n := range nums {
            select {
            case <-ctx.Done():
                return // ← cancellation check
            case out <- n:
            }
        }
    }()
    return out
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stage 2: Square — transform mỗi số → n²
// Input: <-chan int (receive-only)
// Output: <-chan int (trả cho stage tiếp theo)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func square(ctx context.Context, in <-chan int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range in {
            select {
            case <-ctx.Done():
                return
            case out <- n * n:
            }
        }
    }()
    return out
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stage 3: Filter — chỉ giữ số > threshold
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func filter(ctx context.Context, in <-chan int, threshold int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out)
        for n := range in {
            select {
            case <-ctx.Done():
                return
            default:
            }
            if n > threshold {
                select {
                case <-ctx.Done():
                    return
                case out <- n:
                }
            }
        }
    }()
    return out
}

func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Pipeline composition: generate → square → filter
    // Đọc từ phải sang trái:
    //   filter(square(generate(1,2,3,4,5,6,7,8,9,10))) > 20
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    nums := generate(ctx, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
    squared := square(ctx, nums)
    result := filter(ctx, squared, 20)

    // Consumer: đọc kết quả cuối cùng
    fmt.Println("Numbers where n² > 20:")
    for v := range result {
        fmt.Printf("  %d\n", v) // 25, 36, 49, 64, 81, 100
    }
}
```

**Kết quả đạt được**:
- Pipeline: `[1..10] → [1,4,9,16,25,36,49,64,81,100] → [25,36,49,64,81,100]`
- Mỗi stage là **independent goroutine** — chạy concurrent.
- Composable: có thể thêm/xóa stages dễ dàng.

**Lưu ý**:
- **Quy ước**: function tạo channel → function close channel (ownership).
- Mọi stage check `ctx.Done()` — cancel ở bất kỳ đâu → toàn bộ pipeline dừng.
- Pipeline stages chạy **concurrent** — stage 2 bắt đầu ngay khi stage 1 gửi item đầu tiên.

---

### Example 2: Pipeline with Fan-out stage — Image Processing

**Mục tiêu**: Pipeline xử lý ảnh: list files → fan-out resize (CPU-intensive) → fan-in save. Stage giữa dùng fan-out để tăng throughput.

**Cần gì**: Go standard library + `sync` package.

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

type Image struct {
    Name string
    Size int // KB
}

type ProcessedImage struct {
    Name     string
    Original int // KB
    Resized  int // KB
    Duration time.Duration
}

// Stage 1: List images
func listImages(ctx context.Context) <-chan Image {
    out := make(chan Image)
    go func() {
        defer close(out)
        images := []Image{
            {"photo1.jpg", 2400}, {"photo2.jpg", 3100},
            {"photo3.png", 5200}, {"photo4.jpg", 1800},
            {"banner.png", 8000}, {"avatar.jpg", 900},
            {"thumb1.jpg", 450},  {"thumb2.jpg", 520},
            {"cover.png", 6300},  {"hero.jpg", 4500},
        }
        for _, img := range images {
            select {
            case <-ctx.Done():
                return
            case out <- img:
            }
        }
    }()
    return out
}

// Stage 2: Resize (fan-out — CPU intensive, nhiều workers)
func resize(ctx context.Context, images <-chan Image, numWorkers int) <-chan ProcessedImage {
    out := make(chan ProcessedImage)
    var wg sync.WaitGroup

    // ━━━ Fan-out: N workers cùng đọc từ images channel ━━━
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()
            for img := range images {
                select {
                case <-ctx.Done():
                    return
                default:
                }

                // Simulate resize: proportional to original size
                duration := time.Duration(img.Size/10) * time.Millisecond
                time.Sleep(duration)

                resized := img.Size / 4 // resize to 25%
                out <- ProcessedImage{
                    Name:     img.Name,
                    Original: img.Size,
                    Resized:  resized,
                    Duration: duration,
                }
            }
        }(i + 1)
    }

    // Fan-in: close output khi tất cả workers done
    go func() {
        wg.Wait()
        close(out)
    }()

    return out
}

// Stage 3: Save results
func save(ctx context.Context, images <-chan ProcessedImage) <-chan string {
    out := make(chan string)
    go func() {
        defer close(out)
        for img := range images {
            select {
            case <-ctx.Done():
                return
            default:
            }
            // Simulate disk write
            time.Sleep(10 * time.Millisecond)
            out <- fmt.Sprintf("✅ %s: %dKB → %dKB (resize took %v)",
                img.Name, img.Original, img.Resized, img.Duration)
        }
    }()
    return out
}

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    start := time.Now()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Pipeline: list → resize (fan-out) → save
    // Fan-out ở stage 2: NumCPU workers song song
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    numWorkers := runtime.NumCPU()
    fmt.Printf("Pipeline: list → resize (%d workers) → save\n\n", numWorkers)

    images := listImages(ctx)
    processed := resize(ctx, images, numWorkers)
    saved := save(ctx, processed)

    for result := range saved {
        fmt.Println(result)
    }

    _ = rand.Int() // suppress unused import
    fmt.Printf("\n⏱ Total: %v\n", time.Since(start))
}
```

**Kết quả đạt được**:
- 10 images xử lý: fan-out ở resize stage → ~NumCPU× nhanh hơn single worker.
- Pipeline stages overlap: save bắt đầu ngay khi resize xong image đầu tiên.
- Context timeout bảo vệ entire pipeline.

**Lưu ý**:
- **CPU-bound stages** dùng fan-out với `NumCPU()` workers.
- **I/O-bound stages** (save) thường 1 worker đủ, hoặc fan-out thêm nếu I/O chậm.
- Pipeline tự có **backpressure**: save chậm → resize channel đầy → resize workers block.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Stage không close output** | Owner tạo → owner close |
| 2 | **Thiếu ctx.Done() check** | Cancel không dừng pipeline → goroutine leak |
| 3 | **Unbuffered giữa stages** | Backpressure quá mạnh → dùng buffered channel |
| 4 | **Quá nhiều stages** | Mỗi stage = goroutine overhead | Merge stages đơn giản |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Go Blog — Pipelines and Cancellation | https://go.dev/blog/pipelines |
| Go Concurrency Patterns | https://go.dev/talks/2012/concurrency.slide |
| Advanced Go Concurrency Patterns | https://go.dev/talks/2013/advconc.slide |
