# DRY, KISS, YAGNI — Nguyên tắc Thiết kế Phần mềm

> **Ngữ cảnh**: 3 nguyên tắc đơn giản nhưng cực kỳ hiệu quả để giữ code clean

---

## ① DEFINE

### DRY — Don't Repeat Yourself

**Mỗi mảnh kiến thức phải có 1 và chỉ 1 nơi đại diện** trong hệ thống. Nếu cùng logic xuất hiện ở 2+ chỗ → extract thành function/module chung.

| | DRY | WET (Write Everything Twice) |
|--|-----|-----|
| **Logic trùng lặp** | 1 nơi duy nhất | Copy-paste nhiều nơi |
| **Sửa bug** | Sửa 1 chỗ | Sửa N chỗ (dễ quên) |
| **Ví dụ** | `validate(email)` dùng chung | Copy validation logic vào mỗi handler |

### KISS — Keep It Simple, Stupid

**Giải pháp đơn giản nhất thường là giải pháp tốt nhất.** Đừng over-engineer, đừng thêm abstraction không cần thiết.

| | KISS | Over-engineered |
|--|------|----------------|
| **Ví dụ** | 1 file `main.go` cho CLI tool | 5 packages + interface + DI container cho CLI tool |
| **Khi nào** | Luôn luôn mặc định | Chỉ khi complexity thực sự cần |

### YAGNI — You Aren't Gonna Need It

**Đừng code tính năng chưa cần.** Implement khi có requirement thực sự, không phải "phòng khi cần".

| | YAGNI | Premature |
|--|-------|-----------|
| **Ví dụ** | Chỉ hỗ trợ PostgreSQL (vì chỉ dùng PG) | Viết database abstraction layer hỗ trợ 5 DB |
| **Cost** | Thêm tính năng khi cần ≈ O(1) | Maintain code không dùng ≈ O(n) |

---

## ② GRAPH

### DRY vs WET

```
❌ WET:                              ✅ DRY:
handler1.go:                         utils/validate.go:
  if !isValidEmail(email) {...}        func ValidateEmail(e string) error
handler2.go:                         
  if !isValidEmail(email) {...}      handler1.go:
handler3.go:                           validate.ValidateEmail(email)
  if !isValidEmail(email) {...}      handler2.go:
                                       validate.ValidateEmail(email)
Bug fix → sửa 3 chỗ                 Bug fix → sửa 1 chỗ
```

### KISS Decision Flow

```
Cần giải quyết vấn đề X?
    │
    ├── Giải pháp đơn giản nhất là gì?
    │       │
    │       ▼
    │   Đủ tốt? ──── Yes ──▶ DÙNG NÓ ✅
    │       │
    │      No
    │       │
    │       ▼
    │   Thêm 1 mức phức tạp
    │       │
    │       ▼
    │   Đủ tốt? ──── Yes ──▶ DÙNG NÓ ✅
    │       │
    │      No → lặp lại (nhưng DỪNG sau 2-3 vòng)
```

---

## ③ CODE

```go
// ═══════ DRY ═══════
// ❌ WET — copy-paste validation
func CreateUser(email string) { /* validate email here */ }
func UpdateUser(email string) { /* validate email here AGAIN */ }

// ✅ DRY — extract thành function
func validateEmail(email string) error {
    if !strings.Contains(email, "@") {
        return errors.New("invalid email")
    }
    return nil
}
func CreateUser(email string) { validateEmail(email) }
func UpdateUser(email string) { validateEmail(email) }

// ═══════ KISS ═══════
// ❌ Over-engineered cho simple task
type Strategy interface{ Execute() }
type ConcreteStrategyA struct{}
type Context struct{ strategy Strategy }
// ... 50 lines for a simple if/else

// ✅ KISS
if orderTotal > 100000 {
    discount = 0.1
}

// ═══════ YAGNI ═══════
// ❌ "Phòng khi cần support MongoDB"
type DatabaseAdapter interface {
    Connect() error
    Query() error
}
type PostgresAdapter struct{}
type MongoAdapter struct{}   // ← CHƯA BAO GIỜ DÙNG

// ✅ YAGNI — chỉ code cái đang dùng
type UserRepo struct {
    db *sql.DB // PostgreSQL — thêm adapter khi THỰC SỰ cần
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | DRY quá mức → wrong abstraction | Chỉ DRY khi logic THỰC SỰ giống nhau |
| 2 | KISS = code cẩu thả | KISS = đơn giản, KHÔNG phải đơn sơ |
| 3 | YAGNI = không thiết kế | YAGNI = không code thừa, vẫn phải design |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| The Pragmatic Programmer | https://pragprog.com/titles/tpp20/ |
| AHA Programming (Kent C. Dodds) | https://kentcdodds.com/blog/aha-programming |
| YAGNI (Martin Fowler) | https://martinfowler.com/bliki/Yagni.html |
