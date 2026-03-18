# 🚀 Exponential Search

> **Phân loại**: Range-finding + Binary Search, Requires sorted data
> **Tóm tắt**: Doubling range (1,2,4,8,...) → tìm block chứa target → binary search trong block.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(log i) — i = vị trí target |
| **Space** | O(1) |
| **Yêu cầu** | Sorted array |
| **Ưu điểm** | Không cần biết array length, O(log i) thay O(log n) |

### Khi nào dùng?

- **Unbounded/infinite arrays** — không biết size trước.
- **Target ở gần đầu** — O(log i) << O(log n).
- Sorted streams, files mà chưa biết length.

---

## ② GRAPH

```text
  Target = 12
  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

  Phase 1: Doubling
  i=1:  arr[1]=2  < 12 → i=2
  i=2:  arr[2]=3  < 12 → i=4
  i=4:  arr[4]=5  < 12 → i=8
  i=8:  arr[8]=9  < 12 → i=16 (> n)

  Phase 2: Binary search in [8..14]
  → Found at index 11 ✓
```

---

## ③ CODE

### Example 1: Standard Exponential Search

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ExponentialSearch: doubling range → binary search
//
// Phase 1: tìm range bằng doubling (1, 2, 4, 8, ...)
// Phase 2: binary search trong [i/2, min(i, n-1)]
//
// Time: O(log i) — i = position of target
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func ExponentialSearch(arr []int, target int) int {
    n := len(arr)
    if n == 0 { return -1 }
    if arr[0] == target { return 0 }

    // Phase 1: Doubling
    i := 1
    for i < n && arr[i] < target {
        i *= 2
    }

    // Phase 2: Binary search in [i/2, min(i, n-1)]
    lo := i / 2
    hi := i
    if hi >= n { hi = n - 1 }

    for lo <= hi {
        mid := lo + (hi-lo)/2
        switch {
        case arr[mid] == target:
            return mid
        case arr[mid] < target:
            lo = mid + 1
        default:
            hi = mid - 1
        }
    }
    return -1
}
```

### Example 2: Unbounded Search — Stream/Iterator pattern

**Mục tiêu**: Search trên data source mà không biết length (stream, file, API).

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DataSource: interface cho unbounded data
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type DataSource interface {
    Get(index int) (int, bool) // value, exists
}

// UnboundedSearch: exponential search khi không biết length
func UnboundedSearch(ds DataSource, target int) int {
    // Phase 1: find upper bound
    i := 1
    for {
        val, exists := ds.Get(i)
        if !exists || val >= target {
            break
        }
        i *= 2
    }

    // Phase 2: binary search in [i/2, i]
    lo := i / 2
    hi := i
    for lo <= hi {
        mid := lo + (hi-lo)/2
        val, exists := ds.Get(mid)
        if !exists {
            hi = mid - 1
            continue
        }
        switch {
        case val == target:
            return mid
        case val < target:
            lo = mid + 1
        default:
            hi = mid - 1
        }
    }
    return -1
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | `i *= 2` overflow | Check `i < n` trước doubling |
| 2 | Dùng cho bounded array khi Binary đủ tốt | Binary Search đơn giản hơn |
| 3 | Quên check `arr[0] == target` | Handle index 0 separately |

---

**Liên kết**: [← Interpolation Search](./04-interpolation-search.md) · [← README](./README.md)
