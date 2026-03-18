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

### Example 3: Singleflight + Scopes + Cursor Pagination — Production API Pattern

**Mục tiêu**: API endpoint `/products` với: singleflight dedup cho hot queries, reusable GORM scopes cho filtering, cursor-based pagination thay vì OFFSET (performance tốt hơn cho large datasets).

**Cần gì**: `gorm.io/gorm`, `golang.org/x/sync/singleflight`.

**Có gì**: Product listing API — 1M products, filter theo category/price, cursor-based pagination, singleflight prevent duplicate DB queries.

```go
package main

import (
    "context"
    "crypto/sha256"
    "encoding/json"
    "fmt"
    "log"
    "time"

    "golang.org/x/sync/singleflight"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

type Product struct {
    ID        uint      `gorm:"primarykey" json:"id"`
    Name      string    `gorm:"size:200;index" json:"name"`
    Price     float64   `gorm:"type:decimal(12,2);index" json:"price"`
    Category  string    `gorm:"size:100;index" json:"category"`
    Stock     int       `json:"stock"`
    CreatedAt time.Time `gorm:"index" json:"created_at"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Scopes: reusable query conditions — composable
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CategoryFilter(category string) func(*gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        if category == "" {
            return db
        }
        return db.Where("category = ?", category)
    }
}

func PriceRange(min, max float64) func(*gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        if min > 0 {
            db = db.Where("price >= ?", min)
        }
        if max > 0 {
            db = db.Where("price <= ?", max)
        }
        return db
    }
}

func InStock(db *gorm.DB) *gorm.DB {
    return db.Where("stock > 0")
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CursorPaginate: cursor-based pagination
// Tại sao cursor thay vì OFFSET?
// - OFFSET(10000): DB scan 10000 rows rồi bỏ qua → O(N) chậm
// - Cursor(id > 10000): DB skip trực tiếp → O(1) nhanh
// - 1M records: OFFSET ~500ms, Cursor ~5ms
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CursorPaginate(cursor uint, limit int) func(*gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        if cursor > 0 {
            db = db.Where("id > ?", cursor)
        }
        if limit <= 0 || limit > 100 {
            limit = 20 // default + max cap
        }
        return db.Order("id ASC").Limit(limit)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ProductService: singleflight + GORM queries
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type ProductService struct {
    db    *gorm.DB
    group singleflight.Group
}

type ListParams struct {
    Category string
    MinPrice float64
    MaxPrice float64
    Cursor   uint
    Limit    int
}

type ListResult struct {
    Products   []Product `json:"products"`
    NextCursor uint      `json:"next_cursor"` // 0 = no more pages
    HasMore    bool      `json:"has_more"`
}

func (s *ProductService) ListProducts(ctx context.Context, params ListParams) (*ListResult, error) {
    // ━━━ Singleflight key: hash params để dedup identical queries ━━━
    keyData, _ := json.Marshal(params)
    key := fmt.Sprintf("products:%x", sha256.Sum256(keyData))

    val, err, shared := s.group.Do(key, func() (interface{}, error) {
        var products []Product

        // ━━━ Compose Scopes: category + price + in-stock + cursor pagination ━━━
        result := s.db.WithContext(ctx).
            Scopes(
                CategoryFilter(params.Category),
                PriceRange(params.MinPrice, params.MaxPrice),
                InStock,
                CursorPaginate(params.Cursor, params.Limit+1), // +1 to check hasMore
            ).
            Find(&products)

        if result.Error != nil {
            return nil, result.Error
        }

        // ━━━ Determine pagination ━━━
        hasMore := len(products) > params.Limit
        if hasMore {
            products = products[:params.Limit] // trim extra
        }

        var nextCursor uint
        if hasMore && len(products) > 0 {
            nextCursor = products[len(products)-1].ID
        }

        return &ListResult{
            Products:   products,
            NextCursor: nextCursor,
            HasMore:    hasMore,
        }, nil
    })

    if err != nil {
        return nil, err
    }

    if shared {
        log.Printf("[Singleflight] Query deduplicated: %s", key[:16])
    }

    return val.(*ListResult), nil
}

func main() {
    dsn := "host=localhost user=app dbname=shop port=5432 sslmode=disable"
    db, _ := gorm.Open(postgres.Open(dsn), &gorm.Config{PrepareStmt: true})
    db.AutoMigrate(&Product{})

    svc := &ProductService{db: db}

    // Page 1: electronics, $100-$500
    result, _ := svc.ListProducts(context.Background(), ListParams{
        Category: "electronics",
        MinPrice: 100,
        MaxPrice: 500,
        Cursor:   0,
        Limit:    20,
    })
    fmt.Printf("Page 1: %d products, next_cursor=%d, has_more=%v\n",
        len(result.Products), result.NextCursor, result.HasMore)

    // Page 2: tiếp tục từ cursor
    if result.HasMore {
        result2, _ := svc.ListProducts(context.Background(), ListParams{
            Category: "electronics",
            MinPrice: 100,
            MaxPrice: 500,
            Cursor:   result.NextCursor,
            Limit:    20,
        })
        fmt.Printf("Page 2: %d products\n", len(result2.Products))
    }
}
```

**Kết quả đạt được**:
- **Cursor pagination**: O(1) performance thay vì O(N) OFFSET — 100× nhanh hơn cho page 500+.
- **Singleflight**: 100 concurrent requests cùng params → 1 DB query.
- **Composable Scopes**: `CategoryFilter` + `PriceRange` + `InStock` — DRY, reusable.
- **Limit+1 trick**: query N+1 records để biết `hasMore` mà không cần COUNT query riêng.

**Lưu ý**:
- **Cursor pagination yêu cầu ORDER BY column có index** — `id ASC` luôn có PK index.
- **Singleflight key = hash(params)** — mỗi params combo khác nhau = key khác nhau.
- **PrepareStmt**: GORM cache prepared statements → ~15% nhanh hơn cho repeated queries.
- Kết hợp Redis cache cho hot categories — xem [goroutines/11](../goroutines/11-singleflight.md).

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

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **Cache queries** | Singleflight + GORM | Deduplicate concurrent reads — xem [goroutines/11](../goroutines/11-singleflight.md) |
| **Parallel queries** | `errgroup` + multiple GORM queries | Fan-out queries — xem [goroutines/06](../goroutines/06-fan-out-fan-in.md) |
| **Full-text search** | PostgreSQL GIN index + `db.Where("ts @@ ...")` | Built-in FTS thay vì Elasticsearch |
| **Query builder** | `squirrel` / `goqu` | Typed SQL builder khi GORM Scopes không đủ |
| **Pagination** | Cursor-based + keyset | Performance tốt hơn OFFSET cho large datasets |
| **Read replica** | GORM DBResolver plugin | Tự route reads → replica, writes → primary |
