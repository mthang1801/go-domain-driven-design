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
