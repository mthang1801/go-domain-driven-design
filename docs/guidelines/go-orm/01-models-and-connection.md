# 01 — Models & Connection

> **Nền tảng**: Khai báo models (struct → table), kết nối database, conventions GORM.

---

## ① DEFINE

### GORM Model

**GORM Model** = Go struct được map sang database table. GORM dùng **conventions** (quy ước tên) để tự động suy ra table name, column name, primary key.

### Conventions

| Quy ước | Chi tiết | Ví dụ |
|---------|---------|-------|
| **Primary Key** | Field tên `ID` tự động là PK | `ID uint` |
| **Table Name** | Struct name → snake_case + plural | `User` → `users` |
| **Column Name** | Field name → snake_case | `CreatedAt` → `created_at` |
| **Timestamps** | `CreatedAt` + `UpdatedAt` tự động track | `time.Time` |
| **Soft Delete** | `DeletedAt` (gorm.DeletedAt) — đánh dấu xóa, không xóa thật | `gorm:"index"` |

### gorm.Model

GORM cung cấp struct `gorm.Model` chứa 4 fields phổ biến:

```go
type Model struct {
    ID        uint           `gorm:"primaryKey"`
    CreatedAt time.Time
    UpdatedAt time.Time
    DeletedAt gorm.DeletedAt `gorm:"index"`
}
```

### GORM Tags quan trọng

| Tag | Ý nghĩa | Ví dụ |
|-----|---------|-------|
| `primaryKey` | Đánh dấu PK | `gorm:"primaryKey"` |
| `column` | Custom column name | `gorm:"column:user_name"` |
| `type` | Custom column type | `gorm:"type:varchar(100)"` |
| `size` | Column size | `gorm:"size:256"` |
| `not null` | NOT NULL constraint | `gorm:"not null"` |
| `uniqueIndex` | Unique index | `gorm:"uniqueIndex"` |
| `index` | Index | `gorm:"index"` |
| `default` | Default value | `gorm:"default:0"` |
| `embedded` | Embed struct | `gorm:"embedded"` |
| `embeddedPrefix` | Prefix cho embedded | `gorm:"embedded;embeddedPrefix:addr_"` |
| `-` | Ignore field | `gorm:"-"` |
| `<-:create` | Write only on create | `gorm:"<-:create"` |
| `->` | Read-only | `gorm:"->"` |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Connection leak** | Quên set connection pool | Config `SetMaxOpenConns`, `SetMaxIdleConns` |
| **Slow queries** | Thiếu indexes | Dùng `gorm:"index"` cho fields hay query |
| **Silent errors** | GORM default không panic | Luôn check `.Error` |

---

## ② GRAPH

### GORM Architecture

```
  Go Struct (Model)          GORM Engine            Database
  ┌──────────────┐     ┌──────────────────┐    ┌──────────────┐
  │ type User    │     │  gorm.DB         │    │  PostgreSQL  │
  │   ID   uint  │◄───▶│  - Model mapping │◄──▶│  users table │
  │   Name string│     │  - Query builder │    │  id, name,   │
  │   Email      │     │  - Hooks         │    │  email, ...  │
  └──────────────┘     │  - Transactions  │    └──────────────┘
                       │  - Migrations    │
                       └──────────────────┘
```

### Model → Table Mapping

```
  Go Struct                              Database Table
  ──────────                             ──────────────
  type User struct {                     TABLE users (
      ID        uint                         id BIGINT PK,
      Name      string                      name VARCHAR(255),
      Email     *string                     email VARCHAR(255) NULL,
      Age       uint8                       age SMALLINT,
      CreatedAt time.Time                   created_at TIMESTAMP,
      UpdatedAt time.Time                   updated_at TIMESTAMP,
      DeletedAt gorm.DeletedAt              deleted_at TIMESTAMP NULL INDEX
  }                                      )
```

---

## ③ CODE

---

### Example 1: Kết nối PostgreSQL

**Mục tiêu**: Kết nối GORM tới PostgreSQL với connection pooling và config tối ưu.

**Cần gì**: `gorm.io/gorm`, `gorm.io/driver/postgres`.

```go
package main

import (
    "fmt"
    "log"
    "time"

    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // DSN (Data Source Name) cho PostgreSQL
    // Format: host=... user=... password=... dbname=... port=... sslmode=...
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    dsn := "host=localhost user=postgres password=postgres dbname=myapp port=5432 sslmode=disable TimeZone=Asia/Ho_Chi_Minh"

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
        // ━━━ Logger: hiển thị SQL queries ━━━
        Logger: logger.Default.LogMode(logger.Info), // Info = log all SQL
        // Đổi thành logger.Silent cho production

        // ━━━ Tắt default transaction cho performance ━━━
        // GORM mặc định wrap mọi write operation trong transaction
        // Tắt nếu bạn tự quản lý transactions
        // SkipDefaultTransaction: true,

        // ━━━ Tắt auto-pluralize table names ━━━
        // NamingStrategy: schema.NamingStrategy{
        //     SingularTable: true, // user thay vì users
        // },
    })
    if err != nil {
        log.Fatal("Failed to connect database:", err)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Connection Pool Configuration
    // QUAN TRỌNG cho production — tránh connection leak
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sqlDB, err := db.DB()
    if err != nil {
        log.Fatal("Failed to get underlying DB:", err)
    }

    sqlDB.SetMaxOpenConns(25)                 // Max connections mở cùng lúc
    sqlDB.SetMaxIdleConns(10)                 // Max connections idle (sẵn sàng)
    sqlDB.SetConnMaxLifetime(5 * time.Minute) // Max thời gian 1 connection sống

    // ━━━ Verify connection ━━━
    if err := sqlDB.Ping(); err != nil {
        log.Fatal("Failed to ping database:", err)
    }

    fmt.Println("✅ Connected to PostgreSQL!")
}
```

**Kết quả đạt được**:
- Kết nối PostgreSQL với connection pooling.
- Logger hiển thị SQL queries cho debugging.

**Lưu ý**:
- **Connection pool** rất quan trọng: quên config → connection leak trong production.
- `logger.Info` cho dev, `logger.Silent` cho production.
- `SkipDefaultTransaction: true` tăng ~30% performance cho write operations.

---

### Example 2: Khai báo Models

**Mục tiêu**: Khai báo models với đầy đủ GORM tags: PK, indexes, constraints, embedded struct, timestamps.

**Cần gì**: `gorm.io/gorm` package.

```go
package models

import (
    "time"

    "gorm.io/gorm"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// User: Embed gorm.Model để tự động có ID, CreatedAt, UpdatedAt, DeletedAt
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type User struct {
    gorm.Model                                     // ID, CreatedAt, UpdatedAt, DeletedAt
    Name     string  `gorm:"size:100;not null"`    // VARCHAR(100) NOT NULL
    Email    string  `gorm:"uniqueIndex;size:255"` // UNIQUE INDEX
    Phone    *string `gorm:"size:15"`              // Pointer = NULLABLE
    Age      uint8   `gorm:"default:0"`            // DEFAULT 0
    Role     string  `gorm:"type:varchar(20);default:'user'"` // Custom type + default
    IsActive bool    `gorm:"default:true;index"`   // INDEX cho quick filter

    // ━━━ Associations ━━━
    Profile  Profile   // Has One
    Orders   []Order   // Has Many
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Profile: Belongs To User (1:1)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Profile struct {
    gorm.Model
    UserID   uint   `gorm:"uniqueIndex"` // FK → users.id, unique (1:1)
    Bio      string `gorm:"type:text"`
    Avatar   string `gorm:"size:500"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Order: Belongs To User (1:N)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Order struct {
    gorm.Model
    UserID      uint           `gorm:"index;not null"`     // FK → users.id
    OrderNumber string         `gorm:"uniqueIndex;size:50"`
    Status      string         `gorm:"type:varchar(20);default:'pending';index"`
    TotalAmount float64        `gorm:"type:decimal(12,2);not null"`

    // ━━━ Embedded struct: address fields ━━━
    Address     Address        `gorm:"embedded;embeddedPrefix:shipping_"`

    // ━━━ Many2Many ━━━
    Products    []Product      `gorm:"many2many:order_products;"`

    // ━━━ Timestamps ━━━
    PaidAt      *time.Time     // Nullable — chưa thanh toán = nil
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Address: Embedded struct (không tạo table riêng)
// Fields được flatten vào parent table
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Address struct {
    Street  string `gorm:"size:255"`
    City    string `gorm:"size:100"`
    Country string `gorm:"size:50"`
    ZipCode string `gorm:"size:10"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Product: Many2Many với Order
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Product struct {
    gorm.Model
    Name        string    `gorm:"size:200;not null;index"`
    Description string    `gorm:"type:text"`
    Price       float64   `gorm:"type:decimal(12,2);not null"`
    SKU         string    `gorm:"uniqueIndex;size:50"`
    CategoryID  uint      `gorm:"index"`

    Category    Category
    Orders      []Order   `gorm:"many2many:order_products;"`
}

// Category: BelongsTo cho Product
type Category struct {
    gorm.Model
    Name     string    `gorm:"size:100;uniqueIndex"`
    Slug     string    `gorm:"size:100;uniqueIndex"`
    Products []Product // Has Many
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Custom Table Name: override convention
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (User) TableName() string {
    return "app_users" // custom table name thay vì "users"
}
```

**Kết quả đạt được**:
- Models đầy đủ: PK, FK, indexes, unique constraints, default values.
- Embedded struct (Address) → flatten vào parent table.
- Associations: Has One, Has Many, Many2Many.

**Lưu ý**:
- **Pointer fields** (`*string`, `*time.Time`) = nullable trong DB.
- **`gorm.Model`** cho ID, timestamps, soft delete — đủ cho hầu hết cases.
- Custom `TableName()` override convention — hữu ích khi DB có naming convention khác.
- Struct tag **zero-value**: GORM bỏ qua zero-value khi query với struct (dùng Map nếu cần query zero).

---

### Example 3: AutoMigrate

**Mục tiêu**: Tự động tạo/update tables từ Go structs. GORM so sánh struct với DB và ALTER table nếu cần.

**Cần gì**: Đã kết nối DB (Example 1) + Models (Example 2).

```go
func main() {
    // ... (connect DB như Example 1)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // AutoMigrate: tạo table nếu chưa có, thêm columns/indexes mới
    //
    // ⚠ AutoMigrate KHÔNG:
    // - Xóa columns
    // - Đổi column types
    // - Xóa indexes
    // → Dùng migration tools (golang-migrate) cho production
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    err := db.AutoMigrate(
        &User{},
        &Profile{},
        &Order{},
        &Product{},
        &Category{},
    )
    if err != nil {
        log.Fatal("Migration failed:", err)
    }

    fmt.Println("✅ Migration completed!")

    // ━━━ Kiểm tra table đã tạo ━━━
    migrator := db.Migrator()
    fmt.Println("users exists:", migrator.HasTable(&User{}))
    fmt.Println("orders exists:", migrator.HasTable(&Order{}))
}
```

**Kết quả đạt được**:
- Tables tự động tạo từ Go structs.
- Indexes, constraints, foreign keys tự động tạo.

**Lưu ý**:
- **AutoMigrate chỉ cho dev** — production dùng migration tools (golang-migrate, goose).
- AutoMigrate **KHÔNG xóa** columns hoặc tables — chỉ ADD.
- Thứ tự migrate quan trọng: parent tables trước (Category → Product → Order).

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Thiếu connection pool** | `SetMaxOpenConns(25)`, `SetMaxIdleConns(10)` |
| 2 | **AutoMigrate trong production** | Dùng golang-migrate hoặc goose |
| 3 | **Quên index** | Thêm `gorm:"index"` cho fields hay WHERE |
| 4 | **Zero-value bị bỏ qua** | Dùng Map thay Struct cho query zero-values |
| 5 | **Soft delete không mong muốn** | Bỏ `gorm.Model`, tự khai báo ID + timestamps |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| GORM Docs — Models | https://gorm.io/docs/models.html |
| GORM Docs — Connecting | https://gorm.io/docs/connecting_to_a_database.html |
| GORM Docs — Conventions | https://gorm.io/docs/conventions.html |
