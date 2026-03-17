# 06 — Migration & Advanced

> **Nâng cao**: AutoMigrate vs manual migration, Scopes pattern, connection pool, performance tips, Upsert, Locking.

---

## ① DEFINE

### Migration Strategies

| Strategy | Use case | Pros | Cons |
|----------|---------|------|------|
| **AutoMigrate** | Dev, prototyping | Zero config | Chỉ ADD, không DELETE/ALTER |
| **golang-migrate** | Production | Full DDL control | Setup phức tạp hơn |
| **goose** | Production | Go-based, simple API | Ít flexible |
| **Atlas** | Production | Declarative, modern | Learning curve |

### Performance Tips

| Technique | Impact | How |
|-----------|--------|-----|
| **SkipDefaultTransaction** | +30% write speed | `gorm.Config{SkipDefaultTransaction: true}` |
| **PrepareStmt** | Cache prepared stmt | `gorm.Config{PrepareStmt: true}` |
| **Connection Pool** | Tránh connection leak | `SetMaxOpenConns`, `SetMaxIdleConns` |
| **Batch operations** | Giảm round-trips | `CreateInBatches`, `FindInBatches` |
| **Select specific cols** | Giảm bandwidth | `db.Select("id", "name")` |
| **Index** | Tăng query speed | `gorm:"index"` |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Migration drift** | AutoMigrate khác manual migration | Chọn 1 strategy, không mix |
| **Connection exhaustion** | Pool quá nhỏ, query chậm | Tune pool size, add indexes |
| **Deadlock** | Concurrent updates cùng rows | Row-level lock, consistent order |

---

## ② GRAPH

### Connection Pool

```
  Application
      │
      ├── goroutine 1 ──▶ ┌─────────────────────┐ ──▶ DB
      ├── goroutine 2 ──▶ │   Connection Pool    │ ──▶ Connection
      ├── goroutine 3 ──▶ │   MaxOpen: 25        │ ──▶ Connection
      ├── goroutine 4 ──▶ │   MaxIdle: 10        │ ──▶ Connection
      └── goroutine 5 ──▶ │   MaxLifetime: 5min  │ ──▶ Connection
                          └─────────────────────┘
                          ↑                     ↑
                     Idle connections      Active connections
                     (reusable)           (in-use)

  goroutine 26: ← BLOCKED (đợi connection release khi MaxOpen=25)
```

---

## ③ CODE

---

### Example 1: Production-grade Connection Setup

**Mục tiêu**: Config GORM cho production: connection pool, logger, performance options.

**Cần gì**: `gorm.io/gorm`, `gorm.io/driver/postgres`.

```go
package database

import (
    "fmt"
    "log"
    "os"
    "time"

    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Config: database configuration
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Config struct {
    Host     string
    Port     int
    User     string
    Password string
    DBName   string
    SSLMode  string
    TimeZone string
}

func NewConnection(cfg Config) (*gorm.DB, error) {
    dsn := fmt.Sprintf(
        "host=%s port=%d user=%s password=%s dbname=%s sslmode=%s TimeZone=%s",
        cfg.Host, cfg.Port, cfg.User, cfg.Password, cfg.DBName, cfg.SSLMode, cfg.TimeZone,
    )

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Logger: khác nhau cho dev vs production
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var logLevel logger.LogLevel
    if os.Getenv("APP_ENV") == "production" {
        logLevel = logger.Warn // production: chỉ log warnings
    } else {
        logLevel = logger.Info // dev: log tất cả SQL
    }

    newLogger := logger.New(
        log.New(os.Stdout, "\r\n", log.LstdFlags),
        logger.Config{
            SlowThreshold:             200 * time.Millisecond, // Slow query threshold
            LogLevel:                  logLevel,
            IgnoreRecordNotFoundError: true, // Không log ErrRecordNotFound
            Colorful:                  true,
        },
    )

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
        Logger: newLogger,

        // ━━━ Performance: tắt default transaction cho writes ━━━
        // GORM v2 mặc định wrap mỗi write trong tx → overhead ~30%
        // Tắt và tự quản lý tx khi cần
        SkipDefaultTransaction: true,

        // ━━━ PrepareStmt: cache prepared statements ━━━
        // Tăng performance cho repeated queries (~15-20%)
        PrepareStmt: true,
    })
    if err != nil {
        return nil, fmt.Errorf("failed to connect database: %w", err)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Connection Pool Configuration
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sqlDB, err := db.DB()
    if err != nil {
        return nil, fmt.Errorf("failed to get underlying DB: %w", err)
    }

    // MaxOpenConns: max connections mở cùng lúc
    // Rule of thumb: 2-3 × CPU cores (DB server)
    // PostgreSQL default max_connections = 100
    sqlDB.SetMaxOpenConns(25)

    // MaxIdleConns: connections giữ sẵn (idle)
    // Tránh tốn thời gian tạo connection mới
    sqlDB.SetMaxIdleConns(10)

    // ConnMaxLifetime: thời gian max 1 connection sống
    // Tránh stale connections → nên < DB server timeout
    sqlDB.SetConnMaxLifetime(5 * time.Minute)

    // ConnMaxIdleTime: thời gian max connection idle được giữ
    sqlDB.SetConnMaxIdleTime(1 * time.Minute)

    return db, nil
}
```

**Kết quả đạt được**:
- Production-ready connection: pool, logger, performance tuning.
- Environment-aware: dev log SQL, production chỉ warnings.

**Lưu ý**:
- **Pool size phụ thuộc DB** — PostgreSQL default `max_connections = 100`, chia cho N app instances.
- `SkipDefaultTransaction: true` + `PrepareStmt: true` → ~40-50% faster writes.
- `SlowThreshold` giúp phát hiện slow queries trong dev.

---

### Example 2: Upsert (Insert or Update)

**Mục tiêu**: Insert nếu chưa có, update nếu đã có — tránh duplicate key errors.

```go
import "gorm.io/gorm/clause"

func demonstrateUpsert(db *gorm.DB) {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Upsert: Insert or Update on conflict
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // 1. On conflict DO NOTHING (skip if exists)
    db.Clauses(clause.OnConflict{DoNothing: true}).
        Create(&User{Email: "alice@example.com", Name: "Alice"})
    // SQL: INSERT INTO users (...) VALUES (...)
    //      ON CONFLICT DO NOTHING

    // 2. On conflict UPDATE specific columns
    db.Clauses(clause.OnConflict{
        Columns:   []clause.Column{{Name: "email"}},           // conflict key
        DoUpdates: clause.AssignmentColumns([]string{"name", "role"}), // update these
    }).Create(&User{
        Email: "alice@example.com",
        Name:  "Alice Updated",
        Role:  "admin",
    })
    // SQL: INSERT INTO users (email, name, role) VALUES (...)
    //      ON CONFLICT (email) DO UPDATE SET name=..., role=...

    // 3. On conflict UPDATE ALL columns
    db.Clauses(clause.OnConflict{
        Columns:   []clause.Column{{Name: "sku"}},
        UpdateAll: true,
    }).Create(&Product{SKU: "PROD-001", Name: "Widget", Price: 29.99})

    // 4. Batch upsert
    products := []Product{
        {SKU: "P1", Name: "Product 1", Price: 10},
        {SKU: "P2", Name: "Product 2", Price: 20},
        {SKU: "P3", Name: "Product 3", Price: 30},
    }
    db.Clauses(clause.OnConflict{
        Columns:   []clause.Column{{Name: "sku"}},
        DoUpdates: clause.AssignmentColumns([]string{"name", "price"}),
    }).CreateInBatches(products, 100)
}
```

**Kết quả đạt được**:
- Upsert: insert mới hoặc update nếu conflict.
- Batch upsert cho sync data từ external sources.

**Lưu ý**:
- Conflict column phải có **UNIQUE constraint** hoặc **PRIMARY KEY**.
- `UpdateAll: true` update tất cả non-PK columns — cẩn thận với timestamps.

---

### Example 3: Row-Level Locking

**Mục tiêu**: Pessimistic locking cho concurrent access — tránh race conditions trên database level.

```go
func demonstrateLocking(db *gorm.DB) {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // FOR UPDATE: lock row cho write (pessimistic lock)
    // Goroutine khác phải đợi cho đến khi tx commit/rollback
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    db.Transaction(func(tx *gorm.DB) error {
        var user User
        // Lock row — chỉ tx này có thể update user
        tx.Clauses(clause.Locking{Strength: "UPDATE"}).
            First(&user, 1)
        // SQL: SELECT * FROM users WHERE id = 1 FOR UPDATE

        // Safe update — không có concurrent modification
        user.Balance -= 100
        tx.Save(&user)

        return nil // ← release lock
    })

    // ━━━ FOR SHARE: lock cho read (shared lock) ━━━
    db.Transaction(func(tx *gorm.DB) error {
        var user User
        tx.Clauses(clause.Locking{Strength: "SHARE"}).
            First(&user, 1)
        // SQL: SELECT * FROM users WHERE id = 1 FOR SHARE
        // Nhiều tx có thể FOR SHARE, nhưng KHÔNG ai có thể FOR UPDATE

        return nil
    })

    // ━━━ NOWAIT: return error ngay nếu row đang bị lock ━━━
    db.Transaction(func(tx *gorm.DB) error {
        var user User
        err := tx.Clauses(clause.Locking{
            Strength: "UPDATE",
            Options:  "NOWAIT",
        }).First(&user, 1).Error
        // Nếu row đang bị lock → return error ngay (không đợi)
        if err != nil {
            return fmt.Errorf("row is locked: %w", err)
        }
        return nil
    })
}
```

**Kết quả đạt được**:
- `FOR UPDATE`: exclusive lock — tránh concurrent write conflicts.
- `FOR SHARE`: shared lock — nhiều reader, block writers.
- `NOWAIT`: fail fast thay vì đợi lock release.

**Lưu ý**:
- **Luôn dùng locking trong transaction** — lock release khi tx commit/rollback.
- `NOWAIT` tốt cho API handlers — trả error 409 Conflict thay vì timeout.
- Cẩn thận **deadlock** khi lock nhiều rows theo thứ tự khác nhau.

---

### Example 4: DDD Repository Pattern với GORM

**Mục tiêu**: Áp dụng Repository pattern — abstract GORM behind interface cho testability và clean architecture.

```go
package repository

import (
    "context"
    "errors"

    "gorm.io/gorm"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Interface: domain layer — không phụ thuộc GORM
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    FindByID(ctx context.Context, id uint) (*User, error)
    FindByEmail(ctx context.Context, email string) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id uint) error
    List(ctx context.Context, page, pageSize int) ([]User, int64, error)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Implementation: infrastructure layer — GORM specific
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type gormUserRepository struct {
    db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepository {
    return &gormUserRepository{db: db}
}

func (r *gormUserRepository) Create(ctx context.Context, user *User) error {
    return r.db.WithContext(ctx).Create(user).Error
}

func (r *gormUserRepository) FindByID(ctx context.Context, id uint) (*User, error) {
    var user User
    err := r.db.WithContext(ctx).
        Preload("Profile").
        First(&user, id).Error
    if errors.Is(err, gorm.ErrRecordNotFound) {
        return nil, nil // ← not found = nil, nil (convention)
    }
    return &user, err
}

func (r *gormUserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
    var user User
    err := r.db.WithContext(ctx).
        Where("email = ?", email).
        First(&user).Error
    if errors.Is(err, gorm.ErrRecordNotFound) {
        return nil, nil
    }
    return &user, err
}

func (r *gormUserRepository) Update(ctx context.Context, user *User) error {
    return r.db.WithContext(ctx).Save(user).Error
}

func (r *gormUserRepository) Delete(ctx context.Context, id uint) error {
    return r.db.WithContext(ctx).Delete(&User{}, id).Error
}

func (r *gormUserRepository) List(ctx context.Context, page, pageSize int) ([]User, int64, error) {
    var users []User
    var total int64

    // Count total
    r.db.WithContext(ctx).Model(&User{}).Count(&total)

    // Paginate
    offset := (page - 1) * pageSize
    err := r.db.WithContext(ctx).
        Preload("Profile").
        Order("created_at DESC").
        Offset(offset).Limit(pageSize).
        Find(&users).Error

    return users, total, err
}
```

**Kết quả đạt được**:
- Repository interface → domain layer không phụ thuộc GORM.
- Implementation dùng GORM — có thể swap sang other ORM/raw SQL.
- Context support cho timeout/cancellation.
- FindByID trả `nil, nil` khi not found (clean API).

**Lưu ý**:
- **`WithContext(ctx)`** truyền context cho mỗi query — support timeout, cancellation.
- `errors.Is(err, gorm.ErrRecordNotFound)` — check cụ thể, không `err != nil`.
- Repository pattern = **DDD best practice** — tách domain logic khỏi persistence.
- Test bằng mock interface hoặc SQLite in-memory database.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **AutoMigrate trong production** | Dùng golang-migrate, goose, Atlas |
| 2 | **Thiếu connection pool** | Luôn set MaxOpenConns, MaxIdleConns |
| 3 | **Deadlock với locking** | Lock rows theo cùng thứ tự, dùng NOWAIT |
| 4 | **Quên WithContext** | Mọi query nên `WithContext(ctx)` |
| 5 | **db global variable** | Dependency inject *gorm.DB |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| GORM — Performance | https://gorm.io/docs/performance.html |
| GORM — Transactions | https://gorm.io/docs/transactions.html |
| GORM — Indexes | https://gorm.io/docs/indexes.html |
| golang-migrate | https://github.com/golang-migrate/migrate |
| GORM — Clauses | https://gorm.io/docs/sql_builder.html |
