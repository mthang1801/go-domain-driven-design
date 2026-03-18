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

### Example 3: ETL Pipeline — GORM Extract → Transform → Batch Load

**Mục tiêu**: Xây dựng ETL pipeline thực tế: Extract data từ database bằng GORM (cursor pagination), Transform trong goroutine pipeline, Load bằng batch insert. Pattern phổ biến cho data migration, report generation, data sync.

**Cần gì**: `gorm.io/gorm`, `gorm.io/driver/postgres`, Go standard library.

**Có gì**: 2 tables — `raw_orders` (source) và `order_reports` (destination). Pipeline đọc từ source, transform, ghi batch vào destination.

```go
package main

import (
    "context"
    "fmt"
    "log"
    "strings"
    "time"

    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Models: Source (raw_orders) → Destination (order_reports)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type RawOrder struct {
    ID        uint      `gorm:"primarykey"`
    UserEmail string    `gorm:"column:user_email"`
    Product   string    `gorm:"column:product"`
    Amount    float64   `gorm:"column:amount"`
    Status    string    `gorm:"column:status"` // "pending", "completed", "cancelled"
    CreatedAt time.Time
}

type OrderReport struct {
    ID           uint    `gorm:"primarykey;autoIncrement"`
    UserDomain   string  `gorm:"column:user_domain;index"`  // extracted from email
    Product      string  `gorm:"column:product"`
    AmountUSD    float64 `gorm:"column:amount_usd"`          // converted
    IsCompleted  bool    `gorm:"column:is_completed"`
    ProcessedAt  time.Time
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stage 1: EXTRACT — Đọc từ DB bằng cursor pagination
// Tại sao cursor? Vì OFFSET chậm trên large tables.
// Mỗi batch đọc 100 rows, gửi từng row vào channel.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func extract(ctx context.Context, db *gorm.DB, batchSize int) <-chan RawOrder {
    out := make(chan RawOrder, batchSize) // ← buffered = batchSize → giảm blocking
    go func() {
        defer close(out)

        var lastID uint = 0
        for {
            var orders []RawOrder
            // Cursor pagination: WHERE id > lastID ORDER BY id LIMIT batch
            // Nhanh hơn OFFSET 1000x trên large tables (index scan vs full scan)
            result := db.WithContext(ctx).
                Where("id > ? AND status != ?", lastID, "cancelled").
                Order("id ASC").
                Limit(batchSize).
                Find(&orders)

            if result.Error != nil {
                log.Printf("[Extract] DB error: %v", result.Error)
                return
            }
            if len(orders) == 0 {
                log.Println("[Extract] No more rows — done")
                return
            }

            for _, order := range orders {
                select {
                case out <- order:
                case <-ctx.Done():
                    log.Println("[Extract] Cancelled")
                    return
                }
            }
            lastID = orders[len(orders)-1].ID
        }
    }()
    return out
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stage 2: TRANSFORM — Business logic transformation
// Pure function trong goroutine → dễ test, dễ thay đổi
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func transform(ctx context.Context, in <-chan RawOrder) <-chan OrderReport {
    out := make(chan OrderReport, 50)
    go func() {
        defer close(out)
        for order := range in {
            // Extract domain từ email: "user@company.com" → "company.com"
            domain := "unknown"
            parts := strings.Split(order.UserEmail, "@")
            if len(parts) == 2 {
                domain = parts[1]
            }

            report := OrderReport{
                UserDomain:  domain,
                Product:     strings.ToUpper(order.Product),
                AmountUSD:   order.Amount * 1.0, // currency conversion placeholder
                IsCompleted: order.Status == "completed",
                ProcessedAt: time.Now(),
            }

            select {
            case out <- report:
            case <-ctx.Done():
                return
            }
        }
    }()
    return out
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Stage 3: LOAD — Batch insert vào destination table
// CreateInBatches: 1 INSERT cho 100 rows thay vì 100 INSERTs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func load(ctx context.Context, db *gorm.DB, in <-chan OrderReport, batchSize int) error {
    batch := make([]OrderReport, 0, batchSize)
    totalLoaded := 0

    for report := range in {
        batch = append(batch, report)

        // Khi batch đầy → flush vào DB
        if len(batch) >= batchSize {
            if err := db.WithContext(ctx).CreateInBatches(batch, batchSize).Error; err != nil {
                return fmt.Errorf("batch insert failed at %d: %w", totalLoaded, err)
            }
            totalLoaded += len(batch)
            log.Printf("[Load] Inserted batch: %d (total: %d)", len(batch), totalLoaded)
            batch = batch[:0] // ← reset slice, keep capacity — no allocation
        }
    }

    // Flush remaining
    if len(batch) > 0 {
        if err := db.WithContext(ctx).CreateInBatches(batch, batchSize).Error; err != nil {
            return fmt.Errorf("final batch insert failed: %w", err)
        }
        totalLoaded += len(batch)
    }

    log.Printf("[Load] ETL complete: %d records loaded", totalLoaded)
    return nil
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Setup: GORM connection + context with timeout
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    dsn := "host=localhost user=app password=secret dbname=etl_db port=5432 sslmode=disable"
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
        Logger: logger.Default.LogMode(logger.Warn),
    })
    if err != nil {
        log.Fatal("DB connection failed:", err)
    }

    // Auto migrate destination table
    db.AutoMigrate(&OrderReport{})

    // ETL timeout: 5 phút cho toàn bộ pipeline
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
    defer cancel()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Kết nối pipeline: Extract → Transform → Load
    //
    //   [DB raw_orders]
    //        ↓ cursor pagination (100 rows/batch)
    //   [extract goroutine]
    //        ↓ chan RawOrder (buffered 100)
    //   [transform goroutine]
    //        ↓ chan OrderReport (buffered 50)
    //   [load — batch insert 100 rows/INSERT]
    //        ↓
    //   [DB order_reports]
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    rawOrders := extract(ctx, db, 100)
    reports := transform(ctx, rawOrders)

    if err := load(ctx, db, reports, 100); err != nil {
        log.Fatal("ETL failed:", err)
    }
}
```

**Kết quả đạt được**:
- **Full ETL pipeline**: DB → Transform → DB, xử lý hàng triệu rows.
- **Cursor pagination**: Nhanh hơn OFFSET 1000x trên large tables.
- **Batch insert**: 1 INSERT/100 rows → giảm round-trips 100x.
- **Pipeline concurrency**: extract đọc batch tiếp trong khi transform xử lý batch trước — overlap I/O.

**Lưu ý**:
- **Buffer sizes matter**: extract buffer = batchSize → extract batch tiếp mà không chờ transform.
- **Error handling**: Load trả error, nhưng extract/transform chỉ log. Production nên dùng errgroup cho error propagation.
- **Memory**: buffered channels giữ data trong memory — batch quá lớn → OOM.
- Khi cần **parallel transform** (CPU-bound): fan-out transform stage bằng pattern Example 2.

---

### Example 4: Event-Driven Pipeline — Watermill Message Router

**Mục tiêu**: Xây dựng event-driven pipeline bằng Watermill: publish order events → enrich → send notification. Message router pattern — dễ swap Kafka/RabbitMQ/GoChannel backend. Áp dụng trong microservice event-driven architecture.

**Cần gì**: `github.com/ThreeDotsLabs/watermill`, `github.com/ThreeDotsLabs/watermill/message`, `github.com/ThreeDotsLabs/watermill/pubsub/gochannel`.

**Có gì**: Publisher tạo order events → Router enrich events → Handler gửi notification. GoChannel backend (in-memory, swap sang Kafka thêm 1 dòng config).

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "time"

    "github.com/ThreeDotsLabs/watermill"
    "github.com/ThreeDotsLabs/watermill/message"
    "github.com/ThreeDotsLabs/watermill/pubsub/gochannel"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Domain Events: messages truyền qua pipeline
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type OrderCreatedEvent struct {
    OrderID   string  `json:"order_id"`
    UserID    string  `json:"user_id"`
    Product   string  `json:"product"`
    Amount    float64 `json:"amount"`
    CreatedAt string  `json:"created_at"`
}

type OrderEnrichedEvent struct {
    OrderCreatedEvent
    UserName  string `json:"user_name"`
    UserTier  string `json:"user_tier"` // "bronze", "silver", "gold"
    Discount  float64 `json:"discount"`
    FinalAmount float64 `json:"final_amount"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Handler 1: Enrich — nhận OrderCreated, lookup user info, publish OrderEnriched
// Pattern: mỗi handler = 1 pipeline stage
// Input topic:  "order.created"
// Output topic: "order.enriched"
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func enrichOrderHandler(pub message.Publisher) message.HandlerFunc {
    return func(msg *message.Message) ([]*message.Message, error) {
        // Deserialize incoming event
        var event OrderCreatedEvent
        if err := json.Unmarshal(msg.Payload, &event); err != nil {
            return nil, fmt.Errorf("unmarshal failed: %w", err)
        }

        // ━━━ Simulate user lookup (trong production: gọi User Service hoặc DB) ━━━
        tier := "bronze"
        discount := 0.0
        if event.Amount > 500 {
            tier = "gold"
            discount = 0.15
        } else if event.Amount > 100 {
            tier = "silver"
            discount = 0.05
        }

        enriched := OrderEnrichedEvent{
            OrderCreatedEvent: event,
            UserName:          "User-" + event.UserID,
            UserTier:          tier,
            Discount:          discount,
            FinalAmount:       event.Amount * (1 - discount),
        }

        payload, _ := json.Marshal(enriched)
        outMsg := message.NewMessage(watermill.NewUUID(), payload)

        log.Printf("[Enrich] Order %s: %s tier, %.0f%% discount → $%.2f",
            event.OrderID, tier, discount*100, enriched.FinalAmount)

        return []*message.Message{outMsg}, nil
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Handler 2: Notify — nhận OrderEnriched, gửi notification
// Terminal stage — không publish tiếp
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func notifyHandler(msg *message.Message) error {
    var event OrderEnrichedEvent
    if err := json.Unmarshal(msg.Payload, &event); err != nil {
        return err
    }

    // Simulate notification (email, push, webhook)
    log.Printf("[Notify] 📧 → %s: Order %s confirmed! Product=%s, Total=$%.2f (%s tier)",
        event.UserName, event.OrderID, event.Product, event.FinalAmount, event.UserTier)

    // msg.Ack() tự gọi khi return nil — message consumed thành công
    return nil
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Setup: Watermill logger + GoChannel PubSub
    // GoChannel: in-memory pub/sub cho dev/test
    // Production: swap sang Kafka, RabbitMQ, NATS
    //
    //   pubSub := kafka.NewPublisher(kafka.PublisherConfig{
    //       Brokers: []string{"localhost:9092"},
    //   }, logger)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    logger := watermill.NewStdLogger(false, false)
    pubSub := gochannel.NewGoChannel(
        gochannel.Config{Persistent: true}, // persistent = true → buffer messages
        logger,
    )

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Router: kết nối handlers thành pipeline
    //
    //   [Publisher]
    //       ↓ topic: "order.created"
    //   [enrichOrderHandler]
    //       ↓ topic: "order.enriched"
    //   [notifyHandler]
    //       ↓ (terminal — log/email)
    //
    // Router tự quản lý: subscription, ack/nack, retry, middleware
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    router, err := message.NewRouter(message.RouterConfig{}, logger)
    if err != nil {
        log.Fatal(err)
    }

    // Stage 1 → Stage 2: order.created → enrich → order.enriched
    router.AddHandler(
        "enrich_order",         // handler name (unique)
        "order.created",        // subscribe topic
        pubSub,                 // subscriber
        "order.enriched",       // publish topic
        pubSub,                 // publisher
        enrichOrderHandler(pubSub),
    )

    // Stage 2 → Terminal: order.enriched → notify (no output topic)
    router.AddNoPublisherHandler(
        "notify_user",
        "order.enriched",
        pubSub,
        notifyHandler,
    )

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Publisher: simulate order events
    // Trong production: API handler publish events
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    go func() {
        time.Sleep(500 * time.Millisecond) // chờ router start
        orders := []OrderCreatedEvent{
            {"ORD-001", "U100", "Laptop", 1200.0, time.Now().Format(time.RFC3339)},
            {"ORD-002", "U200", "Mouse", 25.0, time.Now().Format(time.RFC3339)},
            {"ORD-003", "U300", "Monitor", 350.0, time.Now().Format(time.RFC3339)},
        }

        for _, order := range orders {
            payload, _ := json.Marshal(order)
            msg := message.NewMessage(watermill.NewUUID(), payload)
            if err := pubSub.Publish("order.created", msg); err != nil {
                log.Printf("Publish failed: %v", err)
            }
            log.Printf("[Publisher] Published order %s ($%.0f)", order.OrderID, order.Amount)
        }
    }()

    // Router.Run blocks — graceful shutdown on SIGTERM
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    if err := router.Run(ctx); err != nil {
        log.Fatal(err)
    }
}
```

**Kết quả đạt được**:
- **Event-driven pipeline**: loosely coupled stages communicate qua topics.
- **Swap backend dễ dàng**: GoChannel → Kafka/RabbitMQ chỉ thay 1 dòng config.
- **Auto retry + ack/nack**: Watermill tự retry khi handler return error.
- **Router manages lifecycle**: subscription, middleware, graceful shutdown.

**Lưu ý**:
- **GoChannel** chỉ cho dev/test (in-memory, mất data khi restart). Production dùng Kafka/NATS.
- **Handler patterns**: `AddHandler` (input → output topic), `AddNoPublisherHandler` (terminal stage).
- **Idempotency**: consumers phải idempotent — messages có thể delivered > 1 lần (at-least-once).
- So sánh với channel pipeline: Watermill phù hợp **cross-service**, channel pipeline phù hợp **in-process**.

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

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **Reactive streams** | `reactivex/rxgo` | Observable pipeline pattern cho Go |
| **Event-driven pipeline** | `ThreeDotsLabs/watermill` | Message-driven architecture — Kafka, AMQP, GoChannel |
| **ETL pipeline** | Pipeline + GORM | Extract (query) → Transform (goroutine) → Load (batch insert) |
| **Backpressure** | Buffered channels giữa stages | Control flow rate, tránh OOM |
| **Monitoring** | Prometheus metrics per stage | Đo throughput, latency, queue depth mỗi stage |
| **Error pipeline** | `tee` channel cho error stream | Separate data flow vs error flow — xem [09-or-done-tee-channels.md](./09-or-done-tee-channels.md) |
