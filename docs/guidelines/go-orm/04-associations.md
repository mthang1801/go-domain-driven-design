# 04 — Associations

> **Nâng cao**: Has One, Has Many, Belongs To, Many2Many, Preload, Joins Preloading.

---

## ① DEFINE

### 4 Loại Association

| Association | Quan hệ | FK ở đâu | Ví dụ |
|-------------|---------|-----------|-------|
| **Belongs To** | N:1 | Ở model hiện tại | Order → User (order có `UserID`) |
| **Has One** | 1:1 | Ở model liên kết | User → Profile (profile có `UserID`) |
| **Has Many** | 1:N | Ở model liên kết | User → Orders (order có `UserID`) |
| **Many2Many** | N:M | Junction table | Order ↔ Products (qua `order_products`) |

### Preloading

| Method | Khi nào dùng | SQL |
|--------|-------------|-----|
| **Preload** | Eager load — 2 queries (N+1 safe) | `SELECT * FROM users; SELECT * FROM orders WHERE user_id IN (...)` |
| **Joins** | Single query — cần filter by association | `SELECT * FROM users LEFT JOIN orders ON ...` |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **N+1 queries** | Access association trong loop mà không Preload | Luôn `Preload` hoặc `Joins` |
| **Circular reference** | A has B, B has A → vòng lặp | Chỉ Preload 1 chiều |
| **FK mismatch** | Field name không match convention | Explicit `foreignKey` tag |

---

## ② GRAPH

### Association Types

```
  Belongs To (FK ở bên này)          Has One (FK ở bên kia)
  ┌─────────┐    FK    ┌───────┐    ┌───────┐   FK   ┌─────────┐
  │  Order  │──────────▶│ User │    │ User │◀─────────│ Profile │
  │ UserID  │           │      │    │      │          │ UserID  │
  └─────────┘           └───────┘    └───────┘         └─────────┘

  Has Many (FK ở bên kia)            Many2Many (junction table)
  ┌───────┐   FK    ┌─────────┐    ┌───────┐  ┌──────────┐  ┌─────────┐
  │ User │◀─────────│ Order   │    │ Order │◀▶│order_prod│◀▶│ Product │
  │      │          │ UserID  │    │       │  │order_id  │  │         │
  └───────┘         │ (many)  │    └───────┘  │product_id│  └─────────┘
                    └─────────┘               └──────────┘
```

---

## ③ CODE

---

### Example 1: Model Declarations with Associations

**Mục tiêu**: Khai báo models với đầy đủ 4 loại associations.

**Cần gì**: `gorm.io/gorm`.

```go
package models

import "gorm.io/gorm"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// User: trung tâm — có tất cả loại associations
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type User struct {
    gorm.Model
    Name    string  `gorm:"size:100"`
    Email   string  `gorm:"uniqueIndex"`

    // Has One: User <──1:1──> Profile
    // FK (UserID) ở Profile table
    Profile Profile

    // Has Many: User <──1:N──> Orders
    // FK (UserID) ở Order table
    Orders []Order

    // Many2Many: User <──N:M──> Roles
    // Junction table: user_roles (auto-created)
    Roles []Role `gorm:"many2many:user_roles;"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Profile: Belongs To User (1:1)
// FK UserID ở ĐÂY (bên profile)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Profile struct {
    gorm.Model
    UserID uint   `gorm:"uniqueIndex"` // FK — unique cho 1:1
    Bio    string `gorm:"type:text"`
    Avatar string `gorm:"size:500"`
    User   User   // ← Belongs To (access parent)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Order: Belongs To User (N:1)
// FK UserID ở ĐÂY (bên order)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Order struct {
    gorm.Model
    UserID      uint    `gorm:"index;not null"` // FK → users.id
    OrderNumber string  `gorm:"uniqueIndex"`
    TotalAmount float64 `gorm:"type:decimal(12,2)"`
    Status      string  `gorm:"default:'pending'"`

    User        User      // ← Belongs To
    Items       []OrderItem // Has Many
}

type OrderItem struct {
    gorm.Model
    OrderID   uint    `gorm:"index;not null"`
    ProductID uint    `gorm:"index;not null"`
    Quantity  int     `gorm:"not null"`
    Price     float64 `gorm:"type:decimal(12,2)"`

    Order   Order
    Product Product
}

type Product struct {
    gorm.Model
    Name  string  `gorm:"size:200;not null"`
    Price float64 `gorm:"type:decimal(12,2)"`
    SKU   string  `gorm:"uniqueIndex"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Role: Many2Many with User
// Junction table "user_roles" tự tạo
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Role struct {
    gorm.Model
    Name  string `gorm:"size:50;uniqueIndex"`
    Users []User `gorm:"many2many:user_roles;"` // ← inverse side
}
```

**Kết quả đạt được**:
- Models khai báo đầy đủ 4 loại: Belongs To, Has One, Has Many, Many2Many.
- GORM tự tạo FK constraints + junction table khi AutoMigrate.

**Lưu ý**:
- **Convention**: FK name = `{AssociationModel}ID` (e.g. `UserID`).
- Nếu FK name khác convention → dùng tag: `gorm:"foreignKey:AuthorID"`.
- **Many2Many** cần `gorm:"many2many:table_name;"` ở CẢ 2 phía.

---

### Example 2: Preload — Eager Loading associations

**Mục tiêu**: Load associations cùng lúc với parent — tránh N+1 query problem.

**Cần gì**: Models đã có data.

```go
func demonstratePreload(db *gorm.DB) {
    var users []User

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ❌ N+1 Problem — KHÔNG dùng Preload
    // 1 query cho users + N queries cho mỗi user's orders
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Find(&users)
    for _, u := range users {
        // Mỗi access orders → 1 query riêng → N+1 queries!
        fmt.Println(u.Name, "has orders:", len(u.Orders)) // ← Orders RỖNG!
        // GORM không tự load associations — cần explicit Preload
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ✅ Preload — 2 queries (users + orders) thay vì N+1
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Preload("Orders").Find(&users)
    // SQL 1: SELECT * FROM users
    // SQL 2: SELECT * FROM orders WHERE user_id IN (1,2,3...)
    for _, u := range users {
        fmt.Printf("%s has %d orders\n", u.Name, len(u.Orders))
    }

    // ━━━ Preload Multiple associations ━━━
    db.Preload("Orders").Preload("Profile").Preload("Roles").Find(&users)

    // ━━━ Nested Preload ━━━
    db.Preload("Orders.Items.Product").Find(&users)
    // Load: users → orders → order_items → products (4 queries)

    // ━━━ Preload với conditions ━━━
    db.Preload("Orders", "status = ?", "pending").Find(&users)
    // Chỉ load orders có status = pending

    // ━━━ Preload với custom function ━━━
    db.Preload("Orders", func(db *gorm.DB) *gorm.DB {
        return db.Where("total_amount > ?", 100000).
            Order("created_at DESC").
            Limit(5)
    }).Find(&users)
    // Chỉ load top 5 orders > 100k, sắp xếp mới nhất

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Preload All — load TẤT CẢ associations
    // ⚠ Cẩn thận performance! Có thể load quá nhiều data
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Preload(clause.Associations).Find(&users)
}
```

**Kết quả đạt được**:
- N+1 fixed: 2 queries thay vì N+1.
- Nested preload, conditional preload, custom preload function.

**Lưu ý**:
- **KHÔNG có lazy loading** — GORM cần explicit `Preload`.
- `Preload("All")` load 1 level — nested associations cần explicit `Preload("A.B.C")`.
- Conditional preload: `Preload("Orders", "status = ?", "active")`.

---

### Example 3: Joins Preloading & Association Mode

**Mục tiêu**: (1) Joins preloading — single query thay vì 2 queries. (2) Association Mode — thêm/xóa associations.

```go
import "gorm.io/gorm/clause"

func demonstrateJoinsAndAssocMode(db *gorm.DB) {
    var users []User

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Joins Preloading: 1 query thay vì 2
    // Phù hợp cho 1:1 associations (Has One, Belongs To)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Joins("Profile").Find(&users)
    // SQL: SELECT users.*, profiles.* FROM users
    //      LEFT JOIN profiles ON profiles.user_id = users.id

    // Joins với conditions
    db.Joins("Profile", db.Where(&Profile{Bio: "Developer"})).Find(&users)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Association Mode: manage associations trực tiếp
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var user User
    db.First(&user, 1)

    // Find associations
    var orders []Order
    db.Model(&user).Association("Orders").Find(&orders)
    fmt.Printf("User %s has %d orders\n", user.Name, len(orders))

    // Append: thêm association
    newOrder := Order{OrderNumber: "ORD-100", TotalAmount: 250000}
    db.Model(&user).Association("Orders").Append(&newOrder)

    // Replace: thay thế tất cả associations
    newRoles := []Role{{Name: "admin"}, {Name: "manager"}}
    db.Model(&user).Association("Roles").Replace(&newRoles)

    // Delete: xóa association (chỉ xóa FK, không xóa record)
    db.Model(&user).Association("Roles").Delete(&Role{Name: "manager"})

    // Clear: xóa tất cả associations
    db.Model(&user).Association("Roles").Clear()

    // Count
    count := db.Model(&user).Association("Orders").Count()
    fmt.Printf("Order count: %d\n", count)
}
```

**Kết quả đạt được**:
- Joins preloading: 1 SQL query, tốt cho 1:1 relations.
- Association Mode: CRUD trực tiếp trên associations.

**Lưu ý**:
- **Joins Preloading** chỉ tốt cho 1:1 — cho 1:N dùng `Preload` (tránh duplicate rows).
- **Association Delete** chỉ xóa FK reference — KHÔNG xóa record. Dùng `Unscoped` để xóa thật.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **N+1 queries** | Luôn `Preload` hoặc `Joins` cho associations |
| 2 | **Joins cho 1:N** | Dùng `Preload` — Joins tạo duplicate rows |
| 3 | **Quên FK convention** | `{Model}ID` hoặc explicit `foreignKey` tag |
| 4 | **Circular preload** | Chỉ Preload 1 chiều |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| GORM — Associations | https://gorm.io/docs/associations.html |
| GORM — Has One | https://gorm.io/docs/has_one.html |
| GORM — Has Many | https://gorm.io/docs/has_many.html |
| GORM — Many2Many | https://gorm.io/docs/many_to_many.html |
| GORM — Preloading | https://gorm.io/docs/preload.html |
