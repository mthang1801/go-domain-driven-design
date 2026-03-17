# 03 — Querying (Advanced)

> **Nâng cao**: Scopes, SubQuery, Raw SQL, Pluck, Scan, smart pagination.

---

## ① DEFINE

### Advanced Query Features

| Feature | Mô tả |
|---------|-------|
| **Scopes** | Reusable query conditions (chainable) |
| **SubQuery** | Nested queries |
| **Raw SQL** | Escape hatch cho complex queries |
| **Pluck** | Lấy single column vào slice |
| **Scan** | Map result vào custom struct |

---

## ② GRAPH

### Scope Composition

```
  db.Scopes(Active, AgeOver(18), Paginate(1, 10)).Find(&users)

  Active ──┐
           │
  AgeOver ─┼──▶ Combined WHERE ──▶ SQL
           │
  Paginate ┘

  SQL: SELECT * FROM users
       WHERE is_active = true
       AND age > 18
       LIMIT 10 OFFSET 0
```

---

## ③ CODE

---

### Example 1: Scopes — Reusable Query Builders

**Mục tiêu**: Tạo reusable query conditions (Scopes) có thể chain với nhau. DRY cho repeated conditions.

**Cần gì**: GORM DB instance.

```go
package main

import (
    "fmt"

    "gorm.io/gorm"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Scope: reusable query condition
// Signature: func(db *gorm.DB) *gorm.DB
// Composable: chain nhiều scopes với nhau
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func Active(db *gorm.DB) *gorm.DB {
    return db.Where("is_active = ?", true)
}

func AgeOver(age int) func(db *gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        return db.Where("age > ?", age)
    }
}

func RoleIs(role string) func(db *gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        return db.Where("role = ?", role)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Paginate: reusable pagination scope
// Tính OFFSET từ page number + page size
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func Paginate(page, pageSize int) func(db *gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        if page <= 0 {
            page = 1
        }
        if pageSize <= 0 {
            pageSize = 10
        }
        offset := (page - 1) * pageSize
        return db.Offset(offset).Limit(pageSize)
    }
}

func demonstrateScopes(db *gorm.DB) {
    var users []User

    // Compose scopes: Active + AgeOver(25) + page 1
    db.Scopes(Active, AgeOver(25), Paginate(1, 10)).Find(&users)
    // SQL: SELECT * FROM users
    //      WHERE is_active = true AND age > 25
    //      LIMIT 10 OFFSET 0

    // Khác scope combo: role admin + active
    db.Scopes(Active, RoleIs("admin")).Find(&users)
    // SQL: SELECT * FROM users
    //      WHERE is_active = true AND role = 'admin'

    fmt.Printf("Found %d users\n", len(users))
}
```

**Kết quả đạt được**:
- Scopes = DRY patterns cho queries — tái sử dụng ở nhiều nơi.
- Composable: chain nhiều scopes với `db.Scopes(A, B, C)`.

**Lưu ý**:
- Scopes **chainable** — mỗi scope nhận `*gorm.DB` và trả `*gorm.DB`.
- Dùng scope factory (function trả function) cho parameterized scopes: `AgeOver(25)`.
- Scopes KHÔNG modify original DB instance — safe cho concurrent use.

---

### Example 2: SubQuery, Raw SQL, Pluck

**Mục tiêu**: Query nâng cao: subquery, raw SQL cho complex queries, pluck cho single column.

**Cần gì**: GORM DB instance.

```go
func demonstrateAdvancedQueries(db *gorm.DB) {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // SubQuery: query lồng nhau
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var users []User

    // Users có đơn hàng > 500k
    db.Where("id IN (?)",
        db.Table("orders").Select("user_id").Where("total_amount > ?", 500000),
    ).Find(&users)
    // SQL: SELECT * FROM users WHERE id IN
    //      (SELECT user_id FROM orders WHERE total_amount > 500000)

    // Users có tuổi > tuổi trung bình
    db.Where("age > (?)",
        db.Table("users").Select("AVG(age)"),
    ).Find(&users)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Pluck: lấy 1 column vào slice
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var emails []string
    db.Model(&User{}).Where("is_active = ?", true).Pluck("email", &emails)
    // emails = ["alice@..", "bob@..", ...]

    var ages []int
    db.Model(&User{}).Pluck("age", &ages)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Scan: map results vào custom struct
    // Hữu ích cho aggregate queries
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    type UserStats struct {
        TotalUsers  int64
        AvgAge      float64
        MaxAge      int
        MinAge      int
    }
    var stats UserStats
    db.Model(&User{}).Select(
        "COUNT(*) as total_users",
        "AVG(age) as avg_age",
        "MAX(age) as max_age",
        "MIN(age) as min_age",
    ).Scan(&stats)
    fmt.Printf("Stats: %+v\n", stats)

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Raw SQL: escape hatch cho complex queries
    // Dùng khi GORM query builder không đủ
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Raw("SELECT * FROM users WHERE age > ? AND role = ?", 25, "admin").Scan(&users)

    // Raw với named params
    db.Raw("SELECT * FROM users WHERE name = @name AND age = @age",
        map[string]interface{}{"name": "Alice", "age": 25},
    ).Scan(&users)

    // Exec cho non-SELECT queries
    db.Exec("UPDATE users SET age = age + 1 WHERE role = ?", "user")

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // DryRun Mode: xem SQL mà không execute
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    stmt := db.Session(&gorm.Session{DryRun: true}).
        Where("name = ?", "jinzhu").Find(&User{}).Statement
    fmt.Println("SQL:", stmt.SQL.String())
    fmt.Println("Vars:", stmt.Vars)
}
```

**Kết quả đạt được**:
- SubQuery cho complex filtering.
- Pluck cho single-column extraction.
- Scan cho custom aggregate structs.
- Raw SQL cho queries GORM builder không cover.

**Lưu ý**:
- **Raw SQL = last resort** — ưu tiên GORM builder cho maintainability.
- `DryRun` mode hữu ích cho debugging — xem SQL generated mà không execute.
- Luôn dùng `?` parameterization trong Raw SQL — tránh SQL injection.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Scope mutate db** | Scopes nhận + trả `*gorm.DB`, không mutate |
| 2 | **Raw SQL injection** | Luôn dùng `?` placeholder |
| 3 | **SubQuery performance** | Check EXPLAIN plan, thêm indexes |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| GORM — Advanced Query | https://gorm.io/docs/advanced_query.html |
| GORM — Scopes | https://gorm.io/docs/scopes.html |
| GORM — Raw SQL | https://gorm.io/docs/sql_builder.html |
