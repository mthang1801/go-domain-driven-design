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

### Example 4: HTTP API Fanout + GORM — Aggregate Data từ Multiple Services

**Mục tiêu**: Gọi song song 3 external APIs để lấy data, aggregate kết quả, và lưu vào DB bằng GORM. Pattern phổ biến trong API gateway, dashboard aggregation, BFF (Backend-for-Frontend).

**Cần gì**: `errgroup`, `net/http`, `gorm.io/gorm`.

**Có gì**: 3 services (User, Order, Payment) → aggregate → save DashboardSnapshot.

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "time"

    "golang.org/x/sync/errgroup"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Models: API responses + GORM destination
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type UserStats struct {
    TotalUsers  int `json:"total_users"`
    ActiveUsers int `json:"active_users"`
}

type OrderStats struct {
    TotalOrders   int     `json:"total_orders"`
    TotalRevenue  float64 `json:"total_revenue"`
}

type PaymentStats struct {
    PendingCount  int     `json:"pending_count"`
    FailedCount   int     `json:"failed_count"`
    SuccessRate   float64 `json:"success_rate"`
}

// DashboardSnapshot: aggregated result → lưu vào DB
type DashboardSnapshot struct {
    ID            uint      `gorm:"primarykey;autoIncrement"`
    TotalUsers    int       `gorm:"column:total_users"`
    ActiveUsers   int       `gorm:"column:active_users"`
    TotalOrders   int       `gorm:"column:total_orders"`
    TotalRevenue  float64   `gorm:"column:total_revenue"`
    PaymentSucc   float64   `gorm:"column:payment_success_rate"`
    PendingPay    int       `gorm:"column:pending_payments"`
    SnapshotAt    time.Time `gorm:"column:snapshot_at;index"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// fetchJSON: generic HTTP GET + JSON decode
// Reusable cho mọi API call — DRY principle
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func fetchJSON[T any](ctx context.Context, client *http.Client, url string) (T, error) {
    var result T
    req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
    if err != nil {
        return result, fmt.Errorf("create request: %w", err)
    }

    resp, err := client.Do(req)
    if err != nil {
        return result, fmt.Errorf("fetch %s: %w", url, err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return result, fmt.Errorf("API %s returned %d", url, resp.StatusCode)
    }

    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return result, fmt.Errorf("decode %s: %w", url, err)
    }
    return result, nil
}

func aggregateDashboard(ctx context.Context, db *gorm.DB) error {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // errgroup.WithContext: cancel tất cả nếu 1 API fail
    // SetLimit(3): chỉ 3 goroutines (1 per API call)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    eg, egCtx := errgroup.WithContext(ctx)
    eg.SetLimit(3)

    client := &http.Client{Timeout: 5 * time.Second}

    // Results — mỗi goroutine ghi vào biến riêng → NO RACE
    var users UserStats
    var orders OrderStats
    var payments PaymentStats

    // ━━━ Goroutine 1: Fetch User Stats ━━━
    eg.Go(func() error {
        var err error
        users, err = fetchJSON[UserStats](egCtx, client, "http://user-service:8080/api/stats")
        if err != nil {
            return fmt.Errorf("user service: %w", err)
        }
        log.Printf("[Users] Total=%d, Active=%d", users.TotalUsers, users.ActiveUsers)
        return nil
    })

    // ━━━ Goroutine 2: Fetch Order Stats ━━━
    eg.Go(func() error {
        var err error
        orders, err = fetchJSON[OrderStats](egCtx, client, "http://order-service:8080/api/stats")
        if err != nil {
            return fmt.Errorf("order service: %w", err)
        }
        log.Printf("[Orders] Total=%d, Revenue=$%.2f", orders.TotalOrders, orders.TotalRevenue)
        return nil
    })

    // ━━━ Goroutine 3: Fetch Payment Stats ━━━
    eg.Go(func() error {
        var err error
        payments, err = fetchJSON[PaymentStats](egCtx, client, "http://payment-service:8080/api/stats")
        if err != nil {
            return fmt.Errorf("payment service: %w", err)
        }
        log.Printf("[Payments] Success=%.1f%%, Pending=%d", payments.SuccessRate*100, payments.PendingCount)
        return nil
    })

    // ━━━ Wait: tất cả 3 goroutines xong (hoặc 1 fail → cancel rest) ━━━
    if err := eg.Wait(); err != nil {
        return fmt.Errorf("aggregate failed: %w", err)
    }

    // ━━━ Save aggregated result vào DB ━━━
    snapshot := DashboardSnapshot{
        TotalUsers:   users.TotalUsers,
        ActiveUsers:  users.ActiveUsers,
        TotalOrders:  orders.TotalOrders,
        TotalRevenue: orders.TotalRevenue,
        PaymentSucc:  payments.SuccessRate,
        PendingPay:   payments.PendingCount,
        SnapshotAt:   time.Now(),
    }

    if err := db.WithContext(ctx).Create(&snapshot).Error; err != nil {
        return fmt.Errorf("save snapshot: %w", err)
    }

    log.Printf("✅ Dashboard snapshot saved (ID: %d)", snapshot.ID)
    return nil
}

func main() {
    dsn := "host=localhost user=app dbname=dashboard port=5432 sslmode=disable"
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatal(err)
    }
    db.AutoMigrate(&DashboardSnapshot{})

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    if err := aggregateDashboard(ctx, db); err != nil {
        log.Fatal("❌", err)
    }
}
```

**Kết quả đạt được**:
- 3 API calls chạy **song song** (thay vì sequential) → latency = max(3 calls) thay vì sum.
- **Error propagation**: 1 service fail → cancel 2 services còn lại ngay lập tức.
- **Context truyền end-to-end**: HTTP request → errgroup → API calls → GORM → DB.
- **No race condition**: mỗi goroutine ghi vào biến riêng (`users`, `orders`, `payments`).

**Lưu ý**:
- **SetLimit(3)**: trong trường hợp này = 3 (1 per API). Nếu fan-out 100 APIs → SetLimit(10) để tránh overload.
- **http.Client shared**: Go `http.Client` thread-safe — share giữa goroutines.
- **Retry**: errgroup cancel khi 1 fail. Nếu cần retry individual → wrap mỗi call với `avast/retry-go`.
- Pattern mở rộng: thêm `sync.Pool` cho JSON decoder buffers nếu call volume lớn.

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

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **Type-safe alternative** | `sourcegraph/conc` ErrorPool | Collect ALL errors + panic recovery — xem [13-conc.md](./13-conc.md) |
| **Limit concurrency** | `errgroup.SetLimit(n)` | Thay thế semaphore cho simple cases |
| **Advanced limiting** | `x/sync/semaphore` | Weighted semaphore cho mixed workloads — xem [10-semaphore.md](./10-semaphore.md) |
| **GORM batch** | errgroup + `db.CreateInBatches` | Parallel batch insert — xem [go-orm/02-crud.md](../go-orm/02-crud.md) |
| **HTTP fanout** | errgroup + `http.Client` | Parallel API calls với shared error handling |
| **Distributed** | Asynq task groups | Cross-process error propagation — xem [15-asynq.md](./15-asynq.md) |
