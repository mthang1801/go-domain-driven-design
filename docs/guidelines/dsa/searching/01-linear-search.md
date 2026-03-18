# 📃 Linear Search

> **Phân loại**: Sequential, Works on unsorted data
> **Tóm tắt**: Duyệt tuần tự từng phần tử từ đầu đến cuối. Algorithm đơn giản nhất.

---

## ① DEFINE

### Thông số

| Metric | Value |
|--------|-------|
| **Best case** | O(1) — target ở đầu |
| **Average case** | O(n) |
| **Worst case** | O(n) — target ở cuối hoặc không có |
| **Space** | O(1) |
| **Yêu cầu** | KHÔNG — chạy trên mọi data |

### Định nghĩa

**Linear Search** (Sequential Search) duyệt tuần tự từng phần tử, so sánh với target. Đơn giản nhất, nhưng duy nhất cho unsorted data.

### Khi nào dùng?

- **Data unsorted** — lựa chọn duy nhất.
- **n rất nhỏ** (< 30) — overhead Binary Search > Linear Search.
- **Single search** — sort O(n log n) + search O(log n) > Linear O(n).
- **Linked list** — random access không hiệu quả.

---

## ② GRAPH

```text
  Target = 7

  [4, 2, 7, 1, 9, 3]
   ↓
  i=0: 4≠7 → next
  i=1: 2≠7 → next
  i=2: 7==7 → FOUND at index 2 ✓

  Total comparisons: 3
```

---

## ③ CODE

### Example 1: Basic Linear Search

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LinearSearch: duyệt tuần tự từng phần tử
// Time: O(n) — worst case duyệt toàn bộ
// Space: O(1)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LinearSearch(arr []int, target int) int {
    for i, v := range arr {
        if v == target {
            return i
        }
    }
    return -1
}
```

### Example 2: Sentinel Linear Search — Giảm 1 comparison per iteration

**Mục tiêu**: Đặt target ở cuối (sentinel) → không cần check bounds trong loop → ~2x nhanh hơn.

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LinearSearchSentinel: bỏ bounds check — nhanh hơn ~2x cho large n
//
// Trick: đặt target ở cuối → loop LUÔN tìm thấy → chỉ cần 1 comparison per step
// Normal: "i < n && arr[i] != target" = 2 comparisons
// Sentinel: "arr[i] != target" = 1 comparison
//
// ⚠ MODIFIES input array (temporarily) → NOT thread-safe
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LinearSearchSentinel(arr []int, target int) int {
    n := len(arr)
    if n == 0 {
        return -1
    }

    last := arr[n-1]   // save last element
    arr[n-1] = target  // place sentinel

    i := 0
    for arr[i] != target {
        i++
    }

    arr[n-1] = last // restore

    if i < n-1 || arr[n-1] == target {
        return i
    }
    return -1
}
```

**Lưu ý**: Sentinel modifies input → KHÔNG dùng cho concurrent access.

### Example 3: Find All Occurrences

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LinearSearchAll: tìm TẤT CẢ vị trí chứa target
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LinearSearchAll(arr []int, target int) []int {
    var indices []int
    for i, v := range arr {
        if v == target {
            indices = append(indices, i)
        }
    }
    return indices
}
```

### Example 4: Generic Linear Search — Go 1.18+

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LinearSearchGeneric: search any comparable type
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LinearSearchGeneric[T comparable](arr []T, target T) int {
    for i, v := range arr {
        if v == target {
            return i
        }
    }
    return -1
}

// LinearSearchFunc: search with custom predicate
func LinearSearchFunc[T any](arr []T, predicate func(T) bool) int {
    for i, v := range arr {
        if predicate(v) {
            return i
        }
    }
    return -1
}
```

### Example 5: Combo — Search trong Struct Slice + Filter

**Mục tiêu**: Real-world pattern — search users by criteria, filter results.

```go
package searching

import "fmt"

type User struct {
    ID    int
    Name  string
    Email string
    Age   int
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// FindUser: tìm user theo predicate
// FindAllUsers: tìm tất cả users khớp
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func FindUser(users []User, pred func(User) bool) (User, bool) {
    idx := LinearSearchFunc(users, pred)
    if idx == -1 {
        return User{}, false
    }
    return users[idx], true
}

func FindAllUsers(users []User, pred func(User) bool) []User {
    var results []User
    for _, u := range users {
        if pred(u) {
            results = append(results, u)
        }
    }
    return results
}

func main() {
    users := []User{
        {1, "Alice", "alice@example.com", 30},
        {2, "Bob", "bob@example.com", 25},
        {3, "Charlie", "charlie@example.com", 35},
        {4, "Diana", "diana@example.com", 25},
    }

    // Tìm user by name
    user, found := FindUser(users, func(u User) bool {
        return u.Name == "Bob"
    })
    fmt.Println(found, user) // true {2 Bob bob@example.com 25}

    // Tìm tất cả users age 25
    young := FindAllUsers(users, func(u User) bool {
        return u.Age == 25
    })
    fmt.Println("Age 25:", young) // [Bob, Diana]
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Dùng Linear cho sorted large data | Binary Search O(log n) |
| 2 | Sentinel trên concurrent data | Không dùng sentinel cho shared data |
| 3 | Tìm nhiều lần trên static data | Sort 1 lần + Binary Search |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| `slices.Index` (Go 1.21+) | [pkg.go.dev/slices#Index](https://pkg.go.dev/slices#Index) |

---

**Liên kết**: [← README](./README.md) · [→ Binary Search](./02-binary-search.md)
