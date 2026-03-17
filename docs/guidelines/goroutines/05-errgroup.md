# 05 — Errgroup

> **Nền tảng**: Quản lý nhóm goroutines với error propagation + context cancellation.

---

## ① DEFINE

### Định nghĩa

**`errgroup.Group`** (từ `golang.org/x/sync/errgroup`) quản lý một nhóm goroutines chạy subtasks của một task lớn. Khi **bất kỳ goroutine nào return error** → context tự cancel → các goroutines khác nhận signal dừng.

### Phân biệt WaitGroup vs Errgroup

| Đặc điểm | sync.WaitGroup | errgroup.Group |
|-----------|---------------|----------------|
| **Error handling** | ❌ Không | ✅ Return first error |
| **Context cancel** | ❌ Không | ✅ Cancel khi error |
| **API** | `Add(n)`, `Done()`, `Wait()` | `Go(func)`, `Wait() error` |
| **Goroutine limit** | ❌ Không | ✅ `SetLimit(n)` (Go 1.20+) |

### Invariants

- `eg.Wait()` **block** cho đến khi tất cả goroutines hoàn thành
- `eg.Wait()` trả **error đầu tiên** (first non-nil error)
- `errgroup.WithContext(ctx)` → khi 1 goroutine error → ctx auto cancel
- `eg.SetLimit(n)` giới hạn N goroutines chạy đồng thời (Go 1.20+)

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Bỏ lỡ error** | Không check `eg.Wait()` return | Luôn handle error từ Wait |
| **Goroutine leak** | Goroutine không check ctx.Done() | Luôn check ctx trong loop |
| **Quá nhiều goroutines** | Không dùng SetLimit | Dùng `eg.SetLimit(n)` |

---

## ② GRAPH

### Errgroup Flow

```
                    ┌──────────────────┐
                    │  errgroup.Group  │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
         eg.Go(G1)      eg.Go(G2)      eg.Go(G3)
              │              │              │
              │              │         return error ← G3 fails!
              │              │              │
              │         ctx cancel ◀────────┘  (auto)
              │              │
         ctx.Done() ◀────────┘     G1 và G2 nhận cancel signal
              │
              ▼
         eg.Wait() → returns G3's error (first error)
```

### Errgroup with SetLimit

```
eg.SetLimit(3)      ← tối đa 3 goroutines cùng lúc

  eg.Go(G1) → start  ━━━━━━━━━━━━━ done
  eg.Go(G2) → start  ━━━━━━━━━━━ done
  eg.Go(G3) → start  ━━━━━━━ done
  eg.Go(G4) → WAIT ──────── start ━━━━━━━ done    (đợi G3 xong)
  eg.Go(G5) → WAIT ─────────── start ━━━━━ done   (đợi G1 xong)
```

---

## ③ CODE

---

### Example 1: Cơ bản — Parallel API calls

**Mục tiêu**: Gọi 3 services song song, nếu bất kỳ service nào fail → cancel tất cả, trả error.

**Cần gì**: `golang.org/x/sync/errgroup`, `context` package.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "time"

    "golang.org/x/sync/errgroup"
)

func fetchFromService(ctx context.Context, name string) (string, error) {
    // Simulate API call: 100-500ms
    delay := time.Duration(100+rand.Intn(400)) * time.Millisecond

    select {
    case <-ctx.Done():
        return "", ctx.Err() // ← bị cancel bởi errgroup
    case <-time.After(delay):
        // 20% chance fail
        if rand.Float32() < 0.2 {
            return "", fmt.Errorf("%s: service unavailable", name)
        }
        return fmt.Sprintf("%s: OK (%v)", name, delay), nil
    }
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // errgroup.WithContext:
    // - Tạo derived context
    // - Khi 1 goroutine return error → ctx auto cancel
    // - Tất cả goroutines khác nhận cancel signal
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    eg, ctx := errgroup.WithContext(context.Background())

    services := []string{"UserService", "OrderService", "PaymentService"}
    results := make([]string, len(services))

    for i, svc := range services {
        i, svc := i, svc // capture loop variable
        eg.Go(func() error {
            result, err := fetchFromService(ctx, svc)
            if err != nil {
                return err // ← errgroup cancel ctx khi nhận error
            }
            results[i] = result // ← safe: mỗi goroutine ghi index khác nhau
            return nil
        })
    }

    // Wait: block cho đến khi tất cả hoàn thành
    if err := eg.Wait(); err != nil {
        fmt.Println("❌ Failed:", err)
        return
    }

    fmt.Println("✅ All services responded:")
    for _, r := range results {
        fmt.Println(" ", r)
    }
}
```

**Kết quả đạt được**:
- 3 services gọi song song (nhanh hơn sequential 3x).
- 1 service fail → cancel tất cả, trả error đầu tiên.

**Lưu ý**:
- `results[i]` safe vì mỗi goroutine ghi index riêng — **KHÔNG cần mutex**.
- Nếu cần **tất cả errors** (không chỉ first): dùng `multierr` package hoặc collect vào slice.
- Loop variable capture: `i, svc := i, svc` (Go < 1.22). Go 1.22+ tự fix.

---

### Example 2: SetLimit — Giới hạn concurrency

**Mục tiêu**: Xử lý 50 tasks nhưng chỉ cho tối đa 5 goroutines chạy đồng thời — tránh overwhelm resource.

**Cần gì**: `errgroup` (Go 1.20+).

```go
package main

import (
    "context"
    "fmt"
    "time"

    "golang.org/x/sync/errgroup"
)

func main() {
    eg, ctx := errgroup.WithContext(context.Background())

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // SetLimit: tối đa 5 goroutines đồng thời
    // eg.Go() sẽ BLOCK nếu đã đạt limit
    // Thay thế cho custom semaphore/worker pool
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    eg.SetLimit(5)

    for i := 0; i < 50; i++ {
        i := i
        eg.Go(func() error { // ← block nếu đã có 5 goroutines đang chạy
            select {
            case <-ctx.Done():
                return ctx.Err()
            default:
            }

            fmt.Printf("[Task %2d] Processing...\n", i)
            time.Sleep(200 * time.Millisecond)
            fmt.Printf("[Task %2d] Done ✅\n", i)
            return nil
        })
    }

    if err := eg.Wait(); err != nil {
        fmt.Println("Error:", err)
        return
    }
    fmt.Println("All 50 tasks completed!")
}
```

**Kết quả đạt được**:
- 50 tasks nhưng chỉ 5 chạy cùng lúc.
- Tự động throttle — không cần custom semaphore.

**Lưu ý**:
- `SetLimit` phải gọi **trước** `Go()`.
- `SetLimit(-1)` = no limit (default behavior).
- Đây là **built-in thay thế** cho Tunny worker pool cho nhiều use cases.

---

### Example 3: Errgroup + Context + Channels — Production Pattern

**Mục tiêu**: Pattern phổ biến: producer → errgroup workers → consumer. Kết hợp errgroup cho error handling + context cho cancellation + channels cho data flow.

**Cần gì**: `errgroup`, `context`, channels.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "time"

    "golang.org/x/sync/errgroup"
)

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
    defer cancel()

    input := make(chan int, 10)
    output := make(chan string, 10)

    eg, ctx := errgroup.WithContext(ctx)

    // ━━━━━ Producer: tạo 30 jobs ━━━━━
    eg.Go(func() error {
        defer close(input)
        for i := 0; i < 30; i++ {
            select {
            case <-ctx.Done():
                return ctx.Err()
            case input <- i:
            }
        }
        return nil
    })

    // ━━━━━ Workers: 4 goroutines xử lý song song ━━━━━
    // Dùng closure để share WaitGroup cho workers
    workerEg, workerCtx := errgroup.WithContext(ctx)
    workerEg.SetLimit(4)

    eg.Go(func() error {
        for num := range input {
            num := num
            workerEg.Go(func() error {
                select {
                case <-workerCtx.Done():
                    return workerCtx.Err()
                default:
                }

                // Simulate work
                duration := time.Duration(50+rand.Intn(200)) * time.Millisecond
                time.Sleep(duration)

                // 5% chance of error
                if rand.Float32() < 0.05 {
                    return fmt.Errorf("worker error processing %d", num)
                }

                result := fmt.Sprintf("%d² = %d (took %v)", num, num*num, duration)
                select {
                case <-workerCtx.Done():
                    return workerCtx.Err()
                case output <- result:
                }
                return nil
            })
        }

        // Đợi tất cả workers hoàn thành rồi close output
        err := workerEg.Wait()
        close(output)
        return err
    })

    // ━━━━━ Consumer: đọc và in kết quả ━━━━━
    eg.Go(func() error {
        for result := range output {
            fmt.Println("✅", result)
        }
        return nil
    })

    // ━━━━━ Wait for all ━━━━━
    if err := eg.Wait(); err != nil {
        fmt.Println("\n❌ Pipeline error:", err)
    } else {
        fmt.Println("\n✅ Pipeline completed successfully!")
    }
}
```

**Kết quả đạt được**:
- Producer → Workers (4 concurrent) → Consumer — full pipeline.
- Error propagation: 1 worker error → cancel tất cả.
- Timeout: 3s context timeout bảo vệ toàn bộ pipeline.

**Lưu ý**:
- **Nested errgroup**: outer group cho pipeline structure, inner group cho workers.
- `close(output)` **phải** sau `workerEg.Wait()` — đợi tất cả workers gửi xong.
- Pattern này là **production-ready** — dùng cho image processing, batch jobs, ETL.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên handle Wait() error** | Luôn: `if err := eg.Wait(); err != nil` |
| 2 | **Goroutine không check ctx** | Luôn `select { case <-ctx.Done() }` trong loop |
| 3 | **Close channel quá sớm** | Close sau `egWorkers.Wait()` |
| 4 | **Race trên shared slice** | Mỗi G ghi index riêng, hoặc dùng mutex |
| 5 | **SetLimit quá lớn** | Match với resource capacity (CPU, DB connections) |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| errgroup package | https://pkg.go.dev/golang.org/x/sync/errgroup |
| Go Blog — Pipelines | https://go.dev/blog/pipelines |
| errgroup source code | https://cs.opensource.google/go/x/sync/+/master:errgroup/ |
