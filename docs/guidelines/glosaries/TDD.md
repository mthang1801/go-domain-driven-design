# TDD — Test-Driven Development

> **Viết tắt**: TDD  
> **Ngữ cảnh**: Phương pháp phát triển — viết test TRƯỚC code

---

## ① DEFINE

### Định nghĩa

**TDD (Test-Driven Development)** là phương pháp phát triển theo chu kỳ **Red → Green → Refactor**: viết test thất bại trước, viết code vừa đủ để pass, rồi refactor.

### Chu kỳ Red-Green-Refactor

| Bước | Tên | Mô tả |
|------|-----|-------|
| 1 | 🔴 **Red** | Viết test → chạy → FAIL (chưa có code) |
| 2 | 🟢 **Green** | Viết code TỐI THIỂU để test PASS |
| 3 | 🔵 **Refactor** | Cải thiện code mà KHÔNG thay đổi behavior |

### Phân biệt TDD vs BDD

| | TDD | BDD |
|--|-----|-----|
| **Focus** | Code correctness | Business behavior |
| **Ngôn ngữ** | Code (Go/Python/JS) | Natural language (Gherkin) |
| **Ai viết** | Developer | BA/QA + Developer |
| **Ví dụ** | `assert.Equal(4, Add(2,2))` | `Given 2 and 2, When Add, Then 4` |

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| Test quá chi tiết | Brittle — refactor code → test vỡ | Test behavior, không test implementation |
| Skip refactor step | Code messy dần | Luôn refactor sau Green |
| Test chạy quá lâu | Dev bỏ chạy test | Unit test < 1s, tách integration test |

---

## ② GRAPH

### TDD Cycle

```
     ┌──── 🔴 RED ◄────────────────────┐
     │    Viết test                      │
     │    Chạy → FAIL                    │
     ▼                                   │
  🟢 GREEN                               │
  Viết code tối thiểu                    │
  Chạy → PASS                     🔵 REFACTOR
     │                              Cải thiện code
     │                              Chạy → vẫn PASS
     └─────────────────────────────────▶┘
                   
  Lặp lại cho mỗi unit of behavior
```

---

## ③ CODE

### Go TDD Example

```go
// Step 1: 🔴 RED — Viết test trước
// file: calculator_test.go
func TestAdd(t *testing.T) {
    result := Add(2, 3)
    assert.Equal(t, 5, result) // FAIL — Add() chưa tồn tại
}

// Step 2: 🟢 GREEN — Viết code tối thiểu
// file: calculator.go
func Add(a, b int) int {
    return a + b // PASS
}

// Step 3: 🔵 REFACTOR — Cải thiện (nếu cần)
// Trong trường hợp này code đã clean, không cần refactor
// Tiếp tục với test case mới...

func TestAddNegative(t *testing.T) {
    result := Add(-1, -2)
    assert.Equal(t, -3, result)
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Test implementation, không test behavior | Test public interface, mock dependencies |
| 2 | Bỏ qua Refactor | Luôn refactor sau mỗi Green |
| 3 | Unit test quá chậm | Tách unit (< 1s) vs integration test |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| TDD By Example (Kent Beck) | ISBN: 978-0321146533 |
| Go Testing | https://go.dev/doc/tutorial/add-a-test |
| BDD — Cucumber | https://cucumber.io/docs/bdd/ |
