# 05 — Transactions & Hooks

> **Nâng cao**: Transaction management, nested transactions, savepoints, lifecycle hooks.

---

## ① DEFINE

### Transactions

GORM mặc định wrap **mọi write operation** (Create, Update, Delete) trong transaction. Có thể tắt cho performance hoặc tự quản lý transaction.

| Method | Mô tả |
|--------|-------|
| `db.Transaction(func)` | Auto commit/rollback — return nil = commit, return error = rollback |
| `db.Begin()` | Manual transaction — tự commit/rollback |
| Nested `tx.Transaction(func)` | Savepoint — rollback không ảnh hưởng parent |

### Hooks (Lifecycle Callbacks)

| Hook | Khi nào | Use case |
|------|---------|---------|
| `BeforeCreate` | Trước INSERT | Validate, hash password, generate UUID |
| `AfterCreate` | Sau INSERT | Send welcome email, create audit log |
| `BeforeUpdate` | Trước UPDATE | Validate, set updated_by |
| `AfterUpdate` | Sau UPDATE | Sync cache, audit log |
| `BeforeDelete` | Trước DELETE | Check dependencies, archive |
| `AfterDelete` | Sau DELETE | Cleanup related resources |
| `BeforeSave` | Trước CREATE + UPDATE | Validate cả 2 |
| `AfterSave` | Sau CREATE + UPDATE | |
| `AfterFind` | Sau SELECT | Decrypt, compute derived fields |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Partial update** | Quên transaction | Wrap related operations trong tx |
| **Deadlock** | 2 transactions lock cùng rows | Consistent lock order, timeout |
| **Hook infinite loop** | Hook gọi Save → trigger hook lại | Dùng `db.Session(&gorm.Session{SkipHooks: true})` |

---

## ② GRAPH

### Transaction Flow

```
  db.Transaction(func(tx) error)
      │
      ├── BEGIN TRANSACTION
      │
      ├── tx.Create(&order)  ── OK
      │
      ├── tx.Create(&payment) ── ERROR!
      │       │
      │       └── return err
      │
      ├── ROLLBACK  ← tất cả changes revert
      │
      └── return error to caller
```

### Hook Execution Order

```
  db.Create(&user)

  BeforeSave ──▶ BeforeCreate ──▶ INSERT ──▶ AfterCreate ──▶ AfterSave

  db.Save(&user) (update)

  BeforeSave ──▶ BeforeUpdate ──▶ UPDATE ──▶ AfterUpdate ──▶ AfterSave
```

---

## ③ CODE

---

### Example 1: Transaction — Auto commit/rollback

**Mục tiêu**: Wrap multiple operations trong 1 transaction. Return nil = commit, return error = rollback toàn bộ.

**Cần gì**: GORM DB instance.

```go
package main

import (
    "fmt"

    "gorm.io/gorm"
)

func createOrderWithPayment(db *gorm.DB, userID uint, amount float64) error {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // db.Transaction: auto commit/rollback
    // - return nil   → COMMIT tất cả
    // - return error → ROLLBACK tất cả
    // ⚠ Dùng 'tx' bên trong, KHÔNG dùng 'db'
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    return db.Transaction(func(tx *gorm.DB) error {
        // Step 1: Create order
        order := Order{
            UserID:      userID,
            OrderNumber: fmt.Sprintf("ORD-%d", userID),
            TotalAmount: amount,
            Status:     "pending",
        }
        if err := tx.Create(&order).Error; err != nil {
            return err // ← ROLLBACK
        }

        // Step 2: Create payment
        payment := Payment{
            OrderID: order.ID,
            Amount:  amount,
            Method:  "credit_card",
            Status:  "processing",
        }
        if err := tx.Create(&payment).Error; err != nil {
            return err // ← ROLLBACK (order cũng bị revert)
        }

        // Step 3: Update user balance
        if err := tx.Model(&User{}).Where("id = ?", userID).
            Update("balance", gorm.Expr("balance - ?", amount)).Error; err != nil {
            return err // ← ROLLBACK
        }

        // Step 4: Validate — business logic check
        var user User
        if err := tx.First(&user, userID).Error; err != nil {
            return err
        }
        if user.Balance < 0 {
            return fmt.Errorf("insufficient balance") // ← ROLLBACK
        }

        return nil // ← COMMIT tất cả
    })
}

type Payment struct {
    gorm.Model
    OrderID uint
    Amount  float64
    Method  string
    Status  string
}
```

**Kết quả đạt được**:
- 4 operations atomic: order + payment + balance update + validation.
- Bất kỳ step nào fail → tất cả revert.

**Lưu ý**:
- **Dùng `tx` bên trong**, KHÔNG dùng `db` — operations trên `db` nằm ngoài transaction.
- GORM v2 mặc định wrap mỗi Create/Update/Delete trong transaction → tắt bằng `SkipDefaultTransaction: true` cho performance.

---

### Example 2: Nested Transactions & Savepoints

**Mục tiêu**: Transaction lồng nhau — rollback inner transaction KHÔNG ảnh hưởng outer.

```go
func demonstrateNestedTx(db *gorm.DB) {
    db.Transaction(func(tx *gorm.DB) error {
        // ━━━ Outer: tạo user (sẽ commit) ━━━
        tx.Create(&User{Name: "Alice", Email: "alice@tx.com"})

        // ━━━ Inner transaction 1: tạo order — ROLLBACK ━━━
        tx.Transaction(func(tx2 *gorm.DB) error {
            tx2.Create(&Order{OrderNumber: "ORD-FAIL", TotalAmount: 999})
            return fmt.Errorf("rollback inner tx") // ← chỉ rollback ORDER
        })
        // User Alice vẫn tồn tại! Order bị rollback.

        // ━━━ Inner transaction 2: tạo profile — COMMIT ━━━
        tx.Transaction(func(tx3 *gorm.DB) error {
            tx3.Create(&Profile{Bio: "Developer"})
            return nil // ← commit profile
        })

        return nil // ← COMMIT outer (user + profile)
    })
    // Kết quả: Alice + Profile tồn tại, Order KHÔNG tồn tại

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Manual Savepoint
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    tx := db.Begin()
    tx.Create(&User{Name: "Bob", Email: "bob@tx.com"})

    tx.SavePoint("before_order")
    tx.Create(&Order{OrderNumber: "ORD-BOB", TotalAmount: 500})
    tx.RollbackTo("before_order") // ← rollback order only

    tx.Commit() // Bob exists, order does NOT
}
```

**Kết quả đạt được**:
- Nested transaction = SAVEPOINT trong SQL.
- Inner rollback KHÔNG ảnh hưởng outer transaction.

**Lưu ý**:
- Nested transactions dùng **SAVEPOINT** — một số DB drivers có thể không hỗ trợ.
- Manual `Begin/Commit/Rollback` cho full control nhưng dễ quên Commit/Rollback.

---

### Example 3: Hooks — Lifecycle Callbacks

**Mục tiêu**: Implement hooks cho auto-hash password, validate, audit log.

```go
package models

import (
    "errors"
    "fmt"
    "strings"
    "time"

    "golang.org/x/crypto/bcrypt"
    "gorm.io/gorm"
)

type User struct {
    gorm.Model
    Name     string `gorm:"size:100"`
    Email    string `gorm:"uniqueIndex"`
    Password string `gorm:"size:255"`
    Role     string `gorm:"default:'user'"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BeforeCreate: chạy TRƯỚC INSERT
// Use case: validate, hash password, normalize data
// Return error → CANCEL create operation
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (u *User) BeforeCreate(tx *gorm.DB) error {
    // Validate email
    if !strings.Contains(u.Email, "@") {
        return errors.New("invalid email format")
    }

    // Hash password
    if u.Password != "" {
        hashed, err := bcrypt.GenerateFromPassword([]byte(u.Password), bcrypt.DefaultCost)
        if err != nil {
            return fmt.Errorf("failed to hash password: %w", err)
        }
        u.Password = string(hashed)
    }

    // Normalize email
    u.Email = strings.ToLower(strings.TrimSpace(u.Email))

    return nil // ← proceed with create
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AfterCreate: chạy SAU INSERT
// Use case: audit log, send notification
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (u *User) AfterCreate(tx *gorm.DB) error {
    // Create audit log
    return tx.Create(&AuditLog{
        Action:    "user_created",
        EntityID:  u.ID,
        Entity:    "users",
        CreatedAt: time.Now(),
    }).Error
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BeforeUpdate: validate trước khi update
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (u *User) BeforeUpdate(tx *gorm.DB) error {
    if u.Email != "" && !strings.Contains(u.Email, "@") {
        return errors.New("invalid email format")
    }
    return nil
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AfterFind: chạy SAU mỗi SELECT
// Use case: decrypt, compute derived fields
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (u *User) AfterFind(tx *gorm.DB) error {
    // Mask password in logs
    u.Password = "[REDACTED]"
    return nil
}

type AuditLog struct {
    gorm.Model
    Action    string
    EntityID  uint
    Entity    string
    CreatedAt time.Time
}
```

**Kết quả đạt được**:
- Password auto-hash trước INSERT (BeforeCreate).
- Audit log tự tạo sau INSERT (AfterCreate).
- Email validation trước Create + Update.
- Password masked sau SELECT (AfterFind).

**Lưu ý**:
- Hook return error → **cancel operation** + rollback nếu trong transaction.
- **AfterFind** chạy mỗi lần query — cẩn thận performance.
- Để skip hooks: `db.Session(&gorm.Session{SkipHooks: true}).Create(&user)`.
- **Tránh** gọi `Save` trong hook → infinite loop.

---

### Example 4: Transaction + Asynq + Domain Events — Order Saga Pattern

**Mục tiêu**: Place order transaction: create order + deduct balance + log domain event — tất cả atomic trong 1 transaction. Sau commit, GORM AfterCreate hook enqueue Asynq task cho confirmation email. Pattern: transactional outbox + async processing.

**Cần gì**: `gorm.io/gorm`, `github.com/hibiken/asynq`.

**Có gì**: `PlaceOrder()` atomic transaction → 3 DB writes → domain event log → AfterCreate hook → Asynq enqueue.

```go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "time"

    "github.com/hibiken/asynq"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Models
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type User struct {
    gorm.Model
    Name    string  `gorm:"size:100"`
    Email   string  `gorm:"uniqueIndex"`
    Balance float64 `gorm:"type:decimal(12,2);default:0"`
}

type Order struct {
    gorm.Model
    UserID      uint    `gorm:"index;not null"`
    OrderNumber string  `gorm:"uniqueIndex;size:50"`
    TotalAmount float64 `gorm:"type:decimal(12,2);not null"`
    Status      string  `gorm:"type:varchar(20);default:'pending';index"`
    User        User    `gorm:"foreignKey:UserID"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DomainEvent: transactional outbox — log events trong cùng tx
// ĐẢM BẢO event và data thay đổi đồng bộ
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type DomainEvent struct {
    gorm.Model
    EventType string `gorm:"size:100;index;not null"`
    EntityID  uint   `gorm:"index;not null"`
    EntityType string `gorm:"size:50;index;not null"`
    Payload   string `gorm:"type:jsonb;not null"`
    Processed bool   `gorm:"default:false;index"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AfterCreate hook: enqueue Asynq task SAU khi tx commit
// ⚠ Hook chạy TRONG transaction — nếu enqueue fail, order vẫn tạo
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
var AsynqClient *asynq.Client

func (o *Order) AfterCreate(tx *gorm.DB) error {
    if AsynqClient == nil {
        return nil
    }

    payload, _ := json.Marshal(map[string]interface{}{
        "order_id":     o.ID,
        "user_id":      o.UserID,
        "order_number": o.OrderNumber,
        "total_amount": o.TotalAmount,
    })

    task := asynq.NewTask("order:confirmation_email", payload,
        asynq.MaxRetry(5),
        asynq.Timeout(30*time.Second),
        asynq.Queue("emails"),
    )

    _, err := AsynqClient.Enqueue(task)
    if err != nil {
        log.Printf("⚠️ Failed to enqueue email for order %s: %v", o.OrderNumber, err)
        // KHÔNG return error → order vẫn tạo thành công
        // Email sẽ gửi qua mechanism khác (DomainEvent polling)
    }
    return nil
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PlaceOrder: atomic transaction
//   Step 1: Validate balance (SELECT FOR UPDATE)
//   Step 2: Create order
//   Step 3: Deduct balance
//   Step 4: Log domain event
//   Commit → AfterCreate hook → Asynq enqueue
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func PlaceOrder(ctx context.Context, db *gorm.DB, userID uint, amount float64, items string) (*Order, error) {
    var order Order

    err := db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
        // ━━━ Step 1: Lock user row + validate balance ━━━
        var user User
        if err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
            First(&user, userID).Error; err != nil {
            return fmt.Errorf("user not found: %w", err)
        }

        if user.Balance < amount {
            return fmt.Errorf("insufficient balance: have %.2f, need %.2f",
                user.Balance, amount)
        }

        // ━━━ Step 2: Create order ━━━
        order = Order{
            UserID:      userID,
            OrderNumber: fmt.Sprintf("ORD-%d-%d", userID, time.Now().UnixMilli()),
            TotalAmount: amount,
            Status:      "confirmed",
        }
        if err := tx.Create(&order).Error; err != nil {
            return fmt.Errorf("create order: %w", err)
        }

        // ━━━ Step 3: Deduct balance (atomic) ━━━
        result := tx.Model(&User{}).Where("id = ?", userID).
            Update("balance", gorm.Expr("balance - ?", amount))
        if result.Error != nil {
            return fmt.Errorf("deduct balance: %w", result.Error)
        }

        // ━━━ Step 4: Log domain event (transactional outbox) ━━━
        eventPayload, _ := json.Marshal(map[string]interface{}{
            "order_id":     order.ID,
            "order_number": order.OrderNumber,
            "user_id":      userID,
            "amount":       amount,
            "items":        items,
        })

        event := DomainEvent{
            EventType:  "order.placed",
            EntityID:   order.ID,
            EntityType: "order",
            Payload:    string(eventPayload),
            Processed:  false,
        }
        if err := tx.Create(&event).Error; err != nil {
            return fmt.Errorf("log event: %w", err)
        }

        log.Printf("✅ Order %s placed: $%.2f deducted from user %d",
            order.OrderNumber, amount, userID)
        return nil // ← COMMIT: order + balance + event
    })

    if err != nil {
        return nil, err
    }

    return &order, nil
}

func main() {
    dsn := "host=localhost user=app dbname=shop port=5432 sslmode=disable"
    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatal(err)
    }
    db.AutoMigrate(&User{}, &Order{}, &DomainEvent{})

    // Setup Asynq
    AsynqClient = asynq.NewClient(asynq.RedisClientOpt{Addr: "localhost:6379"})
    defer AsynqClient.Close()

    // Seed user
    db.Create(&User{Name: "Alice", Email: "alice@shop.com", Balance: 1000})

    // Place order
    ctx := context.Background()
    order, err := PlaceOrder(ctx, db, 1, 299.99, "Widget Pro × 1")
    if err != nil {
        log.Fatal(err)
    }
    fmt.Printf("Order placed: %s (ID=%d)\n", order.OrderNumber, order.ID)
}
```

> ⚠ **Import**: thêm `"gorm.io/gorm/clause"` cho `clause.Locking`.

**Kết quả đạt được**:
- **Atomic transaction**: order + balance deduction + domain event — all or nothing.
- **Pessimistic lock**: `FOR UPDATE` trên user row → tránh concurrent balance conflict.
- **Transactional outbox**: domain event ghi cùng tx → guaranteed delivery (poll later).
- **Async processing**: AfterCreate hook → Asynq email → không block transaction.

**Lưu ý**:
- **Hook KHÔNG return error** cho enqueue failure: order creation quan trọng hơn email.
- **Domain events**: nếu Asynq fail, poll `domain_events WHERE processed = false` → retry.
- **FOR UPDATE**: lock row → prevent double-spending. Production: thêm `NOWAIT` nếu cần fail fast.
- **Idempotency**: `OrderNumber` unique → retry `PlaceOrder` safe nếu dùng idempotency key.
- Kết hợp với semaphore middleware cho API rate limiting — xem [goroutines/10](../goroutines/10-semaphore.md).

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Dùng `db` thay `tx` trong transaction** | Luôn dùng `tx` parameter |
| 2 | **Quên Commit/Rollback** (manual tx) | Dùng `db.Transaction(func)` thay vì `Begin` |
| 3 | **Hook infinite loop** | Không gọi Save/Create trong hook, hoặc SkipHooks |
| 4 | **AfterFind heavy** | Query N rows → hook chạy N lần | Keep lightweight |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| GORM — Transactions | https://gorm.io/docs/transactions.html |
| GORM — Hooks | https://gorm.io/docs/hooks.html |

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **Async after commit** | Asynq + AfterCreate hook | Enqueue background task sau DB commit — xem [goroutines/15](../goroutines/15-asynq.md) |
| **Saga pattern** | Distributed transactions via Asynq | Compensating transactions cho microservices |
| **Event sourcing** | Hooks + channel + pipeline | Publish domain events — xem [goroutines/07](../goroutines/07-pipeline.md) |
| **Retry** | `avast/retry-go` + Transaction | Retry failed transactions với backoff |
| **Idempotency** | Unique constraint + Upsert | Idempotent handlers cho at-least-once delivery |
| **Testing** | `Transaction` wrapper trong test | Rollback after each test — clean state |
