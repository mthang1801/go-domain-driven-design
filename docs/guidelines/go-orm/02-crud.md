# 02 — CRUD Operations

> **Nền tảng**: Create, Read, Update, Delete — hai API styles: Traditional và Generics (v1.30+).

---

## ① DEFINE

### Traditional API vs Generics API

| Đặc điểm | Traditional API | Generics API (≥ v1.30) |
|-----------|----------------|----------------------|
| **Syntax** | `db.Create(&user)` | `gorm.G[User](db).Create(ctx, &user)` |
| **Type-safe** | ❌ (interface{}) | ✅ (generics) |
| **Context** | Optional | Required (first-class) |
| **Error** | `.Error` field | Return `error` |
| **Recommend** | Legacy projects | New projects |

### CRUD Overview

| Operation | Traditional | Generics |
|-----------|------------|---------|
| **Create** | `db.Create(&user)` | `gorm.G[User](db).Create(ctx, &user)` |
| **Read** | `db.First(&user, id)` | `gorm.G[User](db).First(ctx)` |
| **Update** | `db.Save(&user)` | `gorm.G[User](db).Updates(ctx, ...)` |
| **Delete** | `db.Delete(&user, id)` | `gorm.G[User](db).Delete(ctx)` |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Silent error** | Quên check `.Error` | Luôn: `if result.Error != nil` |
| **Zero-value skip** | Struct zero-value bị bỏ qua | Dùng `map[string]interface{}` hoặc `Select` |
| **Update all records** | Quên WHERE clause | GORM v2 block update/delete all mặc định |

---

## ② GRAPH

### GORM CRUD Flow

```
  Application                  GORM                    Database
      │                         │                         │
      │── db.Create(&user) ────▶│                         │
      │                         │── INSERT INTO users ───▶│
      │                         │◀── OK (id=1) ──────────│
      │◀── user.ID = 1 ────────│                         │
      │                         │                         │
      │── db.First(&user, 1) ──▶│                         │
      │                         │── SELECT * ... LIMIT 1 ▶│
      │                         │◀── row data ───────────│
      │◀── user populated ─────│                         │
      │                         │                         │
      │── db.Save(&user) ──────▶│                         │
      │                         │── UPDATE users SET ... ▶│
      │                         │◀── rows affected ──────│
      │                         │                         │
      │── db.Delete(&user) ────▶│                         │
      │                         │── UPDATE deleted_at ... ▶│ (soft delete)
      │                         │◀── OK ─────────────────│
```

---

## ③ CODE

---

### Example 1: Create — Insert records

**Mục tiêu**: Tạo records: single, batch, với associations, select/omit fields.

**Cần gì**: Đã kết nối DB + Models đã migrate.

```go
package main

import (
    "fmt"
    "log"
    "time"

    "gorm.io/gorm"
)

type User struct {
    gorm.Model
    Name     string  `gorm:"size:100;not null"`
    Email    string  `gorm:"uniqueIndex;size:255"`
    Age      uint8   `gorm:"default:0"`
    Phone    *string `gorm:"size:15"`
    Role     string  `gorm:"default:'user'"`
}

func demonstrateCreate(db *gorm.DB) {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 1. Create single record
    // GORM tự set ID, CreatedAt, UpdatedAt
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    user := User{Name: "Alice", Email: "alice@example.com", Age: 25}
    result := db.Create(&user) // ← pass pointer

    if result.Error != nil {
        log.Println("Create failed:", result.Error)
        return
    }
    fmt.Printf("Created user: ID=%d, RowsAffected=%d\n", user.ID, result.RowsAffected)
    // user.ID đã được auto-fill bởi GORM

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 2. Batch Insert — tạo nhiều records cùng lúc
    // Performance tốt hơn nhiều so với loop Create
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    users := []User{
        {Name: "Bob",     Email: "bob@example.com",     Age: 30},
        {Name: "Charlie", Email: "charlie@example.com", Age: 22},
        {Name: "Diana",   Email: "diana@example.com",   Age: 28},
    }
    result = db.Create(&users) // ← batch insert
    fmt.Printf("Batch created: %d users\n", result.RowsAffected)
    // Mỗi user trong slice đều có ID được set

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 3. Create with Select — chỉ insert specific fields
    // Fields không trong Select sẽ lấy default/zero value
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Select("Name", "Email").Create(&User{
        Name:  "Eve",
        Email: "eve@example.com",
        Age:   35, // ← BỊ BỎ QUA vì không trong Select
    })
    // SQL: INSERT INTO users (name, email) VALUES ('Eve', 'eve@example.com')

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 4. Create with Omit — loại trừ specific fields
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Omit("Age").Create(&User{
        Name:  "Frank",
        Email: "frank@example.com",
        Age:   40, // ← BỊ BỎ QUA vì trong Omit
    })

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 5. Create with Map — không cần struct
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Model(&User{}).Create(map[string]interface{}{
        "Name":  "Grace",
        "Email": "grace@example.com",
        "Age":   0, // ← zero-value ĐƯỢC insert khi dùng Map
    })

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 6. Batch Insert with batch size limit
    // Tránh query quá lớn → DB timeout
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var manyUsers []User
    for i := 0; i < 100; i++ {
        manyUsers = append(manyUsers, User{
            Name:  fmt.Sprintf("User_%d", i),
            Email: fmt.Sprintf("user%d@example.com", i),
        })
    }
    db.CreateInBatches(manyUsers, 20) // ← 20 records per INSERT
    // Tạo 5 INSERT statements thay vì 1 INSERT 100 rows
}
```

**Kết quả đạt được**:
- Single/batch create, select/omit fields, map-based create.
- `CreateInBatches` cho large datasets — tránh query size limit.

**Lưu ý**:
- **LUÔN pass pointer** (`&user`) — không pass value.
- **Batch insert** nhanh hơn loop create 10-50x (1 SQL vs N SQL).
- Zero-value (`Age: 0`) bị bỏ qua với struct → dùng **Map** nếu cần insert zero.

---

### Example 2: Read — Query records

**Mục tiêu**: Query: First, Find, Where conditions, struct/map/string conditions, advanced queries.

**Cần gì**: Đã có data trong DB (Example 1).

```go
func demonstrateRead(db *gorm.DB) {
    var user User
    var users []User

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // First: lấy 1 record đầu tiên (ORDER BY id LIMIT 1)
    // Return ErrRecordNotFound nếu không tìm thấy
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    result := db.First(&user)
    if result.Error != nil {
        if result.Error == gorm.ErrRecordNotFound {
            fmt.Println("User not found!")
        } else {
            fmt.Println("Query error:", result.Error)
        }
    }

    // ━━━ First by primary key ━━━
    db.First(&user, 1)              // SELECT * FROM users WHERE id = 1 LIMIT 1
    db.First(&user, "id = ?", "10") // String PK

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Find: lấy TẤT CẢ records matching conditions
    // KHÔNG return ErrRecordNotFound khi empty
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Find(&users) // SELECT * FROM users

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Where conditions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // String condition (parameterized — safe from SQL injection)
    db.Where("name = ?", "Alice").First(&user)
    db.Where("age >= ?", 25).Find(&users)
    db.Where("name LIKE ?", "%ali%").Find(&users)
    db.Where("name IN ?", []string{"Alice", "Bob"}).Find(&users)
    db.Where("created_at BETWEEN ? AND ?", time.Now().AddDate(0, -1, 0), time.Now()).Find(&users)

    // ━━━ Struct condition ━━━
    // ⚠ ZERO-VALUE fields bị bỏ qua!
    db.Where(&User{Name: "Alice", Age: 0}).Find(&users) // Age=0 → BỊ BỎ QUA
    // SQL: SELECT * FROM users WHERE name = 'Alice' (không có AND age = 0)

    // ━━━ Map condition — KHÔNG bỏ qua zero-value ━━━
    db.Where(map[string]interface{}{"name": "Alice", "age": 0}).Find(&users)
    // SQL: SELECT * FROM users WHERE name = 'Alice' AND age = 0 ✅

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Not, Or conditions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Not("name = ?", "Alice").Find(&users)
    db.Where("name = ?", "Alice").Or("name = ?", "Bob").Find(&users)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Select, Order, Limit, Offset
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Select("name", "email").Find(&users) // chỉ SELECT 2 columns
    db.Order("age desc, name").Find(&users) // ORDER BY age DESC, name
    db.Limit(10).Offset(20).Find(&users)    // LIMIT 10 OFFSET 20 (pagination)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Group, Having, Distinct, Count
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    type RoleCount struct {
        Role  string
        Count int
    }
    var roleCounts []RoleCount
    db.Model(&User{}).Select("role, count(*) as count").
        Group("role").Having("count(*) > ?", 1).Find(&roleCounts)

    var count int64
    db.Model(&User{}).Where("age > ?", 25).Count(&count)
    fmt.Printf("Users with age > 25: %d\n", count)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Joins
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    type UserWithProfile struct {
        UserName string
        Bio      string
    }
    db.Model(&User{}).
        Select("users.name as user_name, profiles.bio").
        Joins("LEFT JOIN profiles ON profiles.user_id = users.id").
        Scan(&UserWithProfile{})

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // FindInBatches — xử lý large dataset (tránh OOM)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Where("age > ?", 18).FindInBatches(&users, 100, func(tx *gorm.DB, batch int) error {
        for _, u := range users {
            fmt.Printf("Batch %d: Processing %s\n", batch, u.Name)
        }
        return nil // return error to stop
    })
}
```

**Kết quả đạt được**:
- Tất cả query patterns: conditions, pagination, group, joins.
- `FindInBatches` cho large datasets — tránh load 1M records vào memory.

**Lưu ý**:
- **`First` vs `Find`**: `First` return `ErrRecordNotFound`, `Find` return empty slice.
- **Struct condition bỏ qua zero-value** — đây là pitfall #1 của GORM!
- Luôn dùng `?` placeholder — KHÔNG string concatenation (SQL injection risk).

---

### Example 3: Update & Delete

**Mục tiêu**: Update: single field, multiple fields, batch update. Delete: soft delete, hard delete, batch delete.

**Cần gì**: Đã có data trong DB.

```go
func demonstrateUpdateDelete(db *gorm.DB) {
    var user User
    db.First(&user, 1)

    // ━━━━━━━━━ UPDATE ━━━━━━━━━

    // 1. Update single field
    db.Model(&user).Update("name", "Alice Updated")
    // SQL: UPDATE users SET name='Alice Updated', updated_at=NOW() WHERE id = 1

    // 2. Update multiple fields with struct
    // ⚠ Zero-value BỊ BỎ QUA! (Age=0 → không update)
    db.Model(&user).Updates(User{Name: "Alice V2", Age: 0})
    // SQL: UPDATE users SET name='Alice V2' WHERE id = 1 (THIẾU age!)

    // 3. Update multiple fields with Map — KHÔNG bỏ qua zero-value
    db.Model(&user).Updates(map[string]interface{}{
        "name": "Alice V3",
        "age":  0, // ← ĐƯỢC UPDATE thành 0 ✅
    })

    // 4. Update với conditions (batch update)
    db.Model(&User{}).Where("role = ?", "user").
        Updates(map[string]interface{}{"role": "member"})
    // SQL: UPDATE users SET role='member' WHERE role = 'user'

    // 5. Update with Select — chỉ update fields trong Select
    db.Model(&user).Select("Name", "Age").Updates(User{Name: "Alice V4", Age: 26})

    // 6. Update with expression (SQL expression)
    db.Model(&user).Update("age", gorm.Expr("age + ?", 1))
    // SQL: UPDATE users SET age = age + 1 WHERE id = 1

    // ━━━━━━━━━ DELETE ━━━━━━━━━

    // 1. Soft Delete (mặc định nếu có DeletedAt field)
    db.Delete(&user) // ← SET deleted_at = NOW(), KHÔNG xóa row
    // SQL: UPDATE users SET deleted_at = NOW() WHERE id = 1

    // 2. Sau soft delete: query bình thường KHÔNG trả về record đã xóa
    var found User
    result := db.First(&found, user.ID)
    fmt.Println("Found after soft delete:", result.Error) // RecordNotFound

    // 3. Query bao gồm soft deleted records
    db.Unscoped().First(&found, user.ID)
    fmt.Println("Unscoped found:", found.Name) // ← tìm thấy!

    // 4. Hard Delete (xóa thật khỏi DB)
    db.Unscoped().Delete(&user)
    // SQL: DELETE FROM users WHERE id = 1 (thật sự xóa)

    // 5. Batch delete với conditions
    db.Where("age < ?", 18).Delete(&User{})
    // SQL: UPDATE users SET deleted_at = NOW() WHERE age < 18

    // 6. Block delete all (GORM v2 default — safety)
    // db.Delete(&User{}) ← ❌ ERROR: WHERE conditions required
    // Must use: db.Where("1 = 1").Delete(&User{}) để xoá tất cả
}
```

**Kết quả đạt được**:
- Update: single, multiple, batch, SQL expression.
- Delete: soft delete (default), hard delete (Unscoped), batch.

**Lưu ý**:
- **Struct update bỏ qua zero-value** — dùng Map hoặc `Select`.
- **Soft delete** mặc định nếu model có `DeletedAt` — queries tự filter.
- **`Unscoped()`** bỏ qua soft delete — dùng cho admin queries hoặc hard delete.
- GORM v2 **block delete all** mặc định — tránh xóa nhầm toàn bộ table.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Zero-value bị skip** | Dùng Map thay struct, hoặc `Select` |
| 2 | **Quên check .Error** | Luôn: `if result.Error != nil` |
| 3 | **SQL injection** | Dùng `?` placeholder, KHÔNG concat string |
| 4 | **N+1 query** | Dùng `Preload` hoặc `Joins` (xem 04-associations) |
| 5 | **Delete all** | GORM v2 block mặc định — cần WHERE clause |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| GORM — Create | https://gorm.io/docs/create.html |
| GORM — Query | https://gorm.io/docs/query.html |
| GORM — Update | https://gorm.io/docs/update.html |
| GORM — Delete | https://gorm.io/docs/delete.html |
