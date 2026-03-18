# 10 — Semaphore

> **Package**: `golang.org/x/sync/semaphore` — Weighted semaphore cho concurrent access control.

---

## ① DEFINE

### Định nghĩa

**Semaphore** là cơ chế giới hạn số lượng goroutines truy cập đồng thời vào 1 resource. Khác với Mutex (chỉ cho 1), semaphore cho phép **tối đa N** goroutines đồng thời.

**`semaphore.Weighted`** là implementation trong Go x/ library — hỗ trợ weighted acquire (mỗi goroutine có thể "chiếm" nhiều hơn 1 slot).

### Phân biệt Semaphore vs Mutex vs Channel

| Cơ chế | Max concurrent | Weighted? | Blocking? | Context? |
|--------|---------------|-----------|-----------|----------|
| **Mutex** | 1 | ❌ | Lock block | ❌ |
| **Channel (buffered)** | N (buffer size) | ❌ | Send block khi full | ❌ |
| **semaphore.Weighted** | N (configurable) | ✅ | `Acquire` block | ✅ `ctx` |
| **errgroup.SetLimit** | N | ❌ | `Go` block | ✅ |

### Use cases

| Use case | Ví dụ |
|----------|-------|
| **Rate limiting** | Tối đa 10 concurrent HTTP requests đến external API |
| **Resource protection** | Tối đa 5 concurrent DB connections |
| **Weighted resources** | GPU tasks cần 2 slots, CPU tasks cần 1 slot |
| **Batch processing** | Xử lý 1000 files nhưng chỉ 20 cùng lúc |

### Invariants

- `Acquire(ctx, n)` block cho đến khi có ≥ n slots available
- `Release(n)` giải phóng n slots — **PHẢI** gọi đúng số đã Acquire
- `TryAcquire(n)` non-blocking — return false nếu không đủ slots
- Tổng slots released ≤ tổng slots acquired — vi phạm = panic

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Deadlock** | Acquire nhiều hơn max weight | Acquire ≤ max weight |
| **Resource leak** | Quên Release | `defer sem.Release(n)` |
| **Context expired** | Timeout trước khi acquire | Handle `ctx.Err()` |

---

## ② GRAPH

### Semaphore Flow

```
  Semaphore(3)        ← max 3 concurrent slots
  ┌──────────────┐
  │ ■ ■ ■        │    3 slots available
  └──────────────┘

  G1: Acquire(1)  → ■ □ □  (2 remaining)
  G2: Acquire(1)  → ■ ■ □  (1 remaining)
  G3: Acquire(1)  → ■ ■ ■  (0 remaining)
  G4: Acquire(1)  → BLOCK  (đợi Release)

  G1: Release(1)  → ■ ■ □  (1 available → G4 unblock)
  G4: acquired!   → ■ ■ ■  (0 remaining)
```

### Weighted Semaphore

```
  Semaphore(4)        ← 4 slots total

  GPU Task: Acquire(2)  → ■ ■ □ □   (cần 2 slots)
  CPU Task: Acquire(1)  → ■ ■ ■ □   (cần 1 slot)
  CPU Task: Acquire(1)  → ■ ■ ■ ■   (full)
  GPU Task: Acquire(2)  → BLOCK     (cần 2 nhưng chỉ có 0)

  CPU Release(1):       → ■ ■ ■ □   (1 available, GPU cần 2 → vẫn block)
  CPU Release(1):       → ■ ■ □ □   (2 available → GPU unblock!)
```

---

## ③ CODE

---

### Example 1: Basic — Giới hạn concurrent HTTP requests

**Mục tiêu**: Tối đa 5 concurrent requests đến external API. Có 20 URLs cần fetch, semaphore đảm bảo chỉ 5 goroutines chạy cùng lúc.

**Cần gì**: `golang.org/x/sync/semaphore`, `context`.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "sync"
    "time"

    "golang.org/x/sync/semaphore"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // semaphore.NewWeighted(5): tối đa 5 concurrent
    // Mỗi Acquire(ctx, 1) chiếm 1 slot
    // Mỗi Release(1) trả 1 slot
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sem := semaphore.NewWeighted(5)
    ctx := context.Background()

    urls := make([]string, 20)
    for i := range urls {
        urls[i] = fmt.Sprintf("https://api.example.com/data/%d", i+1)
    }

    var wg sync.WaitGroup
    var mu sync.Mutex
    results := make([]string, 0, 20)

    for _, url := range urls {
        wg.Add(1)
        go func(u string) {
            defer wg.Done()

            // ━━━ Acquire 1 slot — block nếu đã full ━━━
            if err := sem.Acquire(ctx, 1); err != nil {
                fmt.Printf("❌ Acquire failed for %s: %v\n", u, err)
                return
            }
            defer sem.Release(1) // ← LUÔN defer Release

            // Simulate HTTP request
            delay := time.Duration(100+rand.Intn(300)) * time.Millisecond
            time.Sleep(delay)

            result := fmt.Sprintf("✅ %s (took %v)", u, delay)

            mu.Lock()
            results = append(results, result)
            mu.Unlock()
        }(url)
    }

    wg.Wait()
    fmt.Printf("Fetched %d/%d URLs (max 5 concurrent)\n", len(results), len(urls))
}
```

**Kết quả đạt được**:
- 20 URLs nhưng chỉ 5 chạy cùng lúc — tránh overwhelm API.
- `Acquire` block goroutines thừa, tự unblock khi có slot.

**Lưu ý**:
- `defer sem.Release(1)` **ngay sau** Acquire — tránh leak slots.
- `Acquire(ctx, 1)` support context — cancel = unblock waiting goroutines.
- Khác với `errgroup.SetLimit(5)`: semaphore cho phép **weighted** access.

---

### Example 2: TryAcquire — Non-blocking check

**Mục tiêu**: Thử acquire mà không block — nếu không đủ slots, skip hoặc fallback.

**Cần gì**: `semaphore` package.

```go
package main

import (
    "fmt"
    "time"

    "golang.org/x/sync/semaphore"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Scenario: Request handler với rate limiting
    // Nếu tất cả slots busy → trả "429 Too Many Requests"
    // thay vì block caller (khác với Acquire)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sem := semaphore.NewWeighted(3) // max 3 concurrent handlers

    for i := 1; i <= 10; i++ {
        // ━━━ TryAcquire: return true/false ngay lập tức ━━━
        if !sem.TryAcquire(1) {
            fmt.Printf("Request %d: 🚫 429 Too Many Requests (all slots busy)\n", i)
            continue
        }

        go func(reqID int) {
            defer sem.Release(1)
            fmt.Printf("Request %d: ✅ Processing...\n", reqID)
            time.Sleep(500 * time.Millisecond) // simulate work
            fmt.Printf("Request %d: ✅ Done\n", reqID)
        }(i)

        time.Sleep(100 * time.Millisecond) // simulate request arrival rate
    }

    time.Sleep(2 * time.Second) // wait for processing
}
```

**Kết quả đạt được**:
- Requests 1-3: xử lý (3 slots available).
- Requests 4+: tùy timing — nếu slots busy → reject ngay (429).
- **Non-blocking**: caller không phải đợi.

**Lưu ý**:
- `TryAcquire` phù hợp cho **HTTP handlers** — trả 429/503 thay vì timeout.
- `Acquire` phù hợp cho **background workers** — đợi slot rảnh.

---

### Example 3: Weighted Semaphore — Khác nhau resource weights

**Mục tiêu**: Tasks có trọng số khác nhau: GPU task cần 2 slots, CPU task cần 1 slot. Tổng cộng 4 slots — phối hợp resource allocation.

**Cần gì**: `semaphore` package to demonstrate weighted allocation.

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"

    "golang.org/x/sync/semaphore"
)

type Task struct {
    Name   string
    Weight int64  // slots cần thiết
    Work   time.Duration
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Total capacity: 4 slots
    // GPU tasks: cần 2 slots mỗi task
    // CPU tasks: cần 1 slot mỗi task
    //
    // Scenario:
    //   2 GPU tasks (2 slots each) = 4 slots → full
    //   4 CPU tasks (1 slot each) = 4 slots → full
    //   1 GPU + 2 CPU = 2 + 2 = 4 slots → full
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sem := semaphore.NewWeighted(4)
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    tasks := []Task{
        {"GPU-Render-1", 2, 800 * time.Millisecond},
        {"CPU-Hash-1",   1, 300 * time.Millisecond},
        {"GPU-Train-1",  2, 1200 * time.Millisecond},
        {"CPU-Hash-2",   1, 200 * time.Millisecond},
        {"CPU-Hash-3",   1, 400 * time.Millisecond},
        {"GPU-Render-2", 2, 600 * time.Millisecond},
        {"CPU-Hash-4",   1, 150 * time.Millisecond},
    }

    var wg sync.WaitGroup
    for _, task := range tasks {
        wg.Add(1)
        go func(t Task) {
            defer wg.Done()

            fmt.Printf("[%s] ⏳ Waiting for %d slot(s)...\n", t.Name, t.Weight)

            // Acquire: đợi đủ slots (weight)
            if err := sem.Acquire(ctx, t.Weight); err != nil {
                fmt.Printf("[%s] ❌ Context cancelled: %v\n", t.Name, err)
                return
            }
            defer sem.Release(t.Weight) // ← release ĐÚNG SỐ đã acquire

            fmt.Printf("[%s] ▶️  Running (using %d slot(s))...\n", t.Name, t.Weight)
            time.Sleep(t.Work)
            fmt.Printf("[%s] ✅ Done\n", t.Name)
        }(task)
    }

    wg.Wait()
    fmt.Println("\nAll tasks completed!")
}
```

**Kết quả đạt được**:
- GPU tasks (weight=2) chiếm nhiều slots hơn CPU tasks (weight=1).
- Scheduler tự cân bằng: GPU task phải đợi lâu hơn nếu không đủ slots.
- Context timeout bảo vệ toàn bộ — tasks đợi quá lâu sẽ bị cancel.

**Lưu ý**:
- `Release(n)` phải = `Acquire(n)` — release thừa = **panic**.
- Weighted semaphore lý tưởng cho **mixed workloads** (GPU/CPU, heavy/light tasks).
- Nếu tất cả tasks cùng weight=1 → dùng channel semaphore hoặc `errgroup.SetLimit` đơn giản hơn.

---

### Example 4: Semaphore + Gin Middleware + GORM — API Rate Limiter

**Mục tiêu**: HTTP middleware dùng semaphore để giới hạn concurrent requests cho DB-heavy API routes. Routes nhẹ (health check) không bị giới hạn. Kết hợp semaphore + Gin + GORM cho real-world API server.

**Cần gì**: `golang.org/x/sync/semaphore`, `github.com/gin-gonic/gin`, `gorm.io/gorm`.

**Có gì**: API server với 2 routes: `/reports` (heavy — max 5 concurrent) và `/health` (lightweight — no limit). Middleware tự inject semaphore dựa trên route weight.

```go
package main

import (
    "context"
    "fmt"
    "log"
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    "golang.org/x/sync/semaphore"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// GORM Model
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Report struct {
    ID        uint      `gorm:"primarykey" json:"id"`
    Title     string    `gorm:"column:title" json:"title"`
    Data      string    `gorm:"column:data;type:text" json:"data"`
    CreatedAt time.Time `json:"created_at"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ConcurrencyLimiter Middleware
// Giới hạn concurrent requests bằng weighted semaphore
//
// Tại sao semaphore thay vì rate limiter?
// - Rate limiter: giới hạn REQUESTS PER SECOND (throughput)
// - Semaphore: giới hạn CONCURRENT REQUESTS (concurrency)
// - DB-heavy routes: cần limit concurrency (tránh connection exhaustion)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func ConcurrencyLimiter(sem *semaphore.Weighted, weight int64, timeout time.Duration) gin.HandlerFunc {
    return func(c *gin.Context) {
        // Context with timeout cho acquire
        ctx, cancel := context.WithTimeout(c.Request.Context(), timeout)
        defer cancel()

        // ━━━ Try Acquire — nếu quá timeout → 503 ━━━
        if err := sem.Acquire(ctx, weight); err != nil {
            c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{
                "error":   "server busy",
                "message": "too many concurrent requests, please retry",
            })
            log.Printf("🚫 Request rejected (semaphore full): %s %s", c.Request.Method, c.Request.URL.Path)
            return
        }

        // ━━━ Release khi response xong ━━━
        defer sem.Release(weight)

        c.Next()
    }
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Setup: GORM + Gin + Semaphore
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    dsn := "host=localhost user=app dbname=api port=5432 sslmode=disable"
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatal(err)
    }
    db.AutoMigrate(&Report{})

    // Semaphore: max 5 concurrent DB-heavy requests
    // Tại sao 5? DB connection pool = 10 connections
    // 5 report queries (mỗi cái cần ~2 connections) = 10 connections max
    dbSem := semaphore.NewWeighted(5)

    r := gin.Default()

    // ━━━ Route 1: Health check — NO semaphore (luôn available) ━━━
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "ok"})
    })

    // ━━━ Route 2: Reports — Semaphore protected (max 5 concurrent) ━━━
    reports := r.Group("/reports")
    reports.Use(ConcurrencyLimiter(dbSem, 1, 5*time.Second))
    {
        // GET /reports — list all reports (DB-heavy: full table scan)
        reports.GET("", func(c *gin.Context) {
            var reportList []Report
            if err := db.WithContext(c.Request.Context()).
                Order("created_at DESC").
                Limit(100).
                Find(&reportList).Error; err != nil {
                c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
                return
            }

            c.JSON(http.StatusOK, reportList)
        })

        // POST /reports — generate report (VERY heavy: aggregation query)
        reports.POST("", func(c *gin.Context) {
            // Simulate heavy DB aggregation
            var report Report
            if err := c.ShouldBindJSON(&report); err != nil {
                c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
                return
            }

            // Heavy query simulation
            time.Sleep(2 * time.Second)

            if err := db.WithContext(c.Request.Context()).Create(&report).Error; err != nil {
                c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
                return
            }

            c.JSON(http.StatusCreated, report)
        })
    }

    // ━━━ Route 3: Export — weighted=2 (cần nhiều resources hơn) ━━━
    r.GET("/export", ConcurrencyLimiter(dbSem, 2, 10*time.Second), func(c *gin.Context) {
        // Export chiếm 2 slots — nặng gấp đôi report thường
        var allReports []Report
        db.WithContext(c.Request.Context()).Find(&allReports)

        // Format as CSV, PDF, etc.
        c.JSON(http.StatusOK, gin.H{
            "count":   len(allReports),
            "message": "export complete",
        })
    })

    fmt.Println("Server running on :8080")
    fmt.Println("  GET  /health  — no limit")
    fmt.Println("  GET  /reports — max 5 concurrent (weight=1)")
    fmt.Println("  POST /reports — max 5 concurrent (weight=1)")
    fmt.Println("  GET  /export  — max 5 concurrent (weight=2)")
    r.Run(":8080")
}
```

**Kết quả đạt được**:
- **Per-route concurrency control**: heavy routes (reports, export) bị giới hạn, lightweight (health) không.
- **Weighted limiting**: `/export` chiếm 2 slots → tối đa 2 exports đồng thời (hoặc 1 export + 3 reports).
- **503 thay vì timeout**: client nhận response nhanh với retry hint.
- **GORM + context**: cancel propagation từ HTTP request → DB query.

**Lưu ý**:
- **Timeout trong middleware**: 5s acquire timeout → nếu server quá busy, client nhận 503 trong 5s thay vì đợi mãi.
- **Weighted semaphore lợi thế**: `/export` (weight=2) tự nhiên giới hạn ít concurrent hơn `/reports` (weight=1).
- **Production**: thêm Prometheus metrics cho `sem` occupancy, 503 count.
- So sánh với `rate.Limiter` (`x/time/rate`): rate limiter giới hạn requests/second, semaphore giới hạn concurrent. Chọn theo use case.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Release != Acquire** | Release ĐÚNG SỐ đã Acquire — thừa = panic |
| 2 | **Quên Release** | `defer sem.Release(n)` ngay sau Acquire |
| 3 | **Acquire > max weight** | Acquire(10) với max=5 → deadlock forever |
| 4 | **Không check ctx error** | `Acquire` return error khi ctx cancel — phải handle |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| semaphore package | https://pkg.go.dev/golang.org/x/sync/semaphore |
| Go x/sync repo | https://github.com/golang/sync |

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **Simple limiting** | `errgroup.SetLimit(n)` | Đơn giản hơn khi không cần weighted — xem [05-errgroup.md](./05-errgroup.md) |
| **Buffered channel** | `make(chan struct{}, N)` | Lightweight semaphore cho simple cases |
| **Rate limiter** | `x/time/rate` | Token bucket — giới hạn rate, không chỉ concurrency |
| **HTTP middleware** | Semaphore + Gin/Echo middleware | Limit concurrent requests per route |
| **DB connection** | Semaphore + GORM | Limit concurrent DB queries — xem [go-orm/01](../go-orm/01-models-and-connection.md) |
| **Kết hợp Ants** | Ants pool (built-in limiting) | Worker pool = semaphore + goroutine reuse — xem [12-ants.md](./12-ants.md) |
