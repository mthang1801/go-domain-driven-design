# 🦘 Jump Search

> **Phân loại**: Block-based, Requires sorted data
> **Tóm tắt**: Nhảy √n bước → tìm block chứa target → linear search trong block.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(√n) |
| **Space** | O(1) |
| **Yêu cầu** | Sorted array |
| **Optimal block** | √n (toán học chứng minh) |

### Tại sao √n?

Minimize: `jumps + linear scan = n/step + step`. Đạo hàm = 0 → `step = √n`.

### Khi nào dùng?

- Sequential access nhanh hơn random (linked list, magnetic tape).
- **Chủ yếu giáo dục** — production luôn dùng Binary Search.

---

## ② GRAPH

```text
  Target = 55, n = 16, step = √16 = 4

  [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, ...]
   ↓           ↓           ↓            ↓
  jump 0      jump 4      jump 8       jump 12

  Jump 1: arr[0]=0   < 55 → jump
  Jump 2: arr[4]=3   < 55 → jump
  Jump 3: arr[8]=21  < 55 → jump
  Jump 4: arr[12]=89 > 55 → STOP

  Linear search [8..12]: arr[10]=55 → FOUND ✓
```

---

## ③ CODE

### Example 1: Standard Jump Search

```go
package searching

import "math"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JumpSearch: nhảy √n bước → linear search trong block
// Time: O(√n), Space: O(1)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func JumpSearch(arr []int, target int) int {
    n := len(arr)
    if n == 0 { return -1 }

    step := int(math.Sqrt(float64(n)))
    prev := 0

    // Phase 1: Jump forward
    for step < n && arr[step] < target {
        prev = step
        step += int(math.Sqrt(float64(n)))
    }

    // Phase 2: Linear search in block [prev, min(step, n))
    for prev < n && prev <= step {
        if arr[prev] == target { return prev }
        if arr[prev] > target { break }
        prev++
    }
    return -1
}
```

### Example 2: Generic Jump Search

```go
package searching

import (
    "math"
    "golang.org/x/exp/constraints"
)

func JumpSearchGeneric[T constraints.Ordered](arr []T, target T) int {
    n := len(arr)
    if n == 0 { return -1 }

    step := int(math.Sqrt(float64(n)))
    prev := 0
    for step < n && arr[step] < target {
        prev = step
        step += int(math.Sqrt(float64(n)))
    }
    for prev < n && prev <= step {
        if arr[prev] == target { return prev }
        if arr[prev] > target { break }
        prev++
    }
    return -1
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Block size != √n | Luôn dùng √n — mathematically optimal |
| 2 | Out of bounds khi step > n | Check `step < n` |
| 3 | Dùng cho random access data | Binary Search tốt hơn |

---

**Liên kết**: [← Binary Search](./02-binary-search.md) · [→ Interpolation Search](./04-interpolation-search.md)
