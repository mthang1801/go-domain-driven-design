# SOLID — 5 Nguyên tắc Thiết kế Hướng Đối tượng

> **Ngữ cảnh**: Nguyên tắc thiết kế nền tảng cho clean, maintainable code

---

## ① DEFINE

### Định nghĩa

**SOLID** là 5 nguyên tắc thiết kế hướng đối tượng do Robert C. Martin (Uncle Bob) đề xuất, giúp code **dễ bảo trì, mở rộng, và test**.

| Chữ | Nguyên tắc | Ý nghĩa |
|-----|-----------|---------|
| **S** | Single Responsibility Principle | Mỗi class/module chỉ có **1 lý do để thay đổi** |
| **O** | Open/Closed Principle | Mở để **mở rộng**, đóng để **sửa đổi** |
| **L** | Liskov Substitution Principle | Subclass phải **thay thế được** parent class |
| **I** | Interface Segregation Principle | Client không bị **ép phụ thuộc** vào method không dùng |
| **D** | Dependency Inversion Principle | Module cấp cao **không phụ thuộc** module cấp thấp — cả hai phụ thuộc vào abstraction |

### Failure Modes

| Vi phạm | Hậu quả | Cách fix |
|---------|---------|---------|
| Vi phạm S | God class — 1 file 2000 dòng | Tách theo responsibility |
| Vi phạm O | Sửa 1 chỗ → vỡ nhiều chỗ | Dùng interface + composition |
| Vi phạm D | Không thể unit test | Inject dependencies qua interface |

---

## ② GRAPH

### S — Single Responsibility

```
❌ SAI:                          ✅ ĐÚNG:
┌──────────────────┐            ┌──────────────┐  ┌──────────────┐
│     UserService  │            │ AuthService  │  │ EmailService │
│ • Login          │     →      │ • Login      │  │ • SendEmail  │
│ • Register       │            │ • Register   │  │ • Template   │
│ • SendEmail      │            └──────────────┘  └──────────────┘
│ • GenerateReport │            ┌──────────────┐
│ • ExportCSV      │            │ReportService │
└──────────────────┘            │ • Generate   │
                                │ • ExportCSV  │
 1 class, 5 lý do thay đổi     └──────────────┘
                                Mỗi class 1 responsibility
```

### D — Dependency Inversion

```
❌ SAI (phụ thuộc concrete):     ✅ ĐÚNG (phụ thuộc abstraction):

┌────────────┐                   ┌────────────┐
│ UserService│                   │ UserService│
└──────┬─────┘                   └──────┬─────┘
       │ depends on                     │ depends on
       ▼                                ▼
┌────────────┐                   ┌─────────────────┐ ← interface
│ PostgresDB │                   │ UserRepository   │
└────────────┘                   └────────┬────────┘
                                          │ implements
                                 ┌────────▼────────┐
                                 │ PostgresUserRepo│
                                 └─────────────────┘
                                 (có thể swap sang MongoUserRepo)
```

---

## ③ CODE

### Go Examples cho từng nguyên tắc

```go
// ═══════════════════════════════
// D — Dependency Inversion (quan trọng nhất trong Go)
// ═══════════════════════════════

// Abstraction (interface) — ở package cấp cao
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// Module cấp cao — phụ thuộc vào interface, KHÔNG phụ thuộc concrete
type UserService struct {
    repo UserRepository // ← interface, không phải *PostgresRepo
}

// Module cấp thấp — implement interface
type PostgresUserRepo struct {
    db *sql.DB
}
func (r *PostgresUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    // SQL query...
}

// Test — dễ dàng mock
type MockUserRepo struct{}
func (m *MockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    return &User{ID: id, Name: "Test"}, nil
}
```

```go
// ═══════════════════════════════
// I — Interface Segregation
// ═══════════════════════════════

// ❌ SAI: Interface quá lớn
type Database interface {
    Query(sql string) (*Rows, error)
    Exec(sql string) error
    BeginTx() (*Tx, error)
    Migrate() error
    Backup() error
}

// ✅ ĐÚNG: Tách thành interfaces nhỏ
type Reader interface {
    Query(sql string) (*Rows, error)
}
type Writer interface {
    Exec(sql string) error
}
type ReadWriter interface {
    Reader
    Writer
}
// Client chỉ depend vào interface cần dùng
func GetUser(db Reader, id string) (*User, error) { ... }
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Over-abstract | Chỉ extract interface khi có ≥ 2 implementations |
| 2 | God interface | Interface ≤ 3-5 methods (Go convention) |
| 3 | Concrete dependency | Luôn depend on interface, inject concrete |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Clean Architecture (Uncle Bob) | https://blog.cleancoder.com/ |
| Go Proverbs | https://go-proverbs.github.io/ |
| SOLID in Go | https://dave.cheney.net/2016/08/20/solid-go-design |
