# 📊 Interpolation Search

> **Phân loại**: Probe-based, Requires sorted + uniformly distributed data
> **Tóm tắt**: Ước lượng vị trí target dựa trên giá trị — tương tự tìm từ trong từ điển.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Best case** | O(1) |
| **Average case** | O(log log n) — uniform data |
| **Worst case** | O(n) — exponential data |
| **Space** | O(1) |
| **Yêu cầu** | Sorted + uniformly distributed |

### Formula

```text
pos = lo + (target - arr[lo]) × (hi - lo) / (arr[hi] - arr[lo])
```

Nếu data uniform: `pos ≈ đúng vị trí` → chỉ 1-2 steps.

---

## ② GRAPH

```text
  Tìm "apple" trong từ điển:
  - Binary Search: luôn mở giữa sách → chậm
  - Interpolation: mở đầu sách (chữ A ở đầu) → nhanh hơn!

  arr = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
  target = 70

  pos = 0 + (70-10) × (9-0) / (100-10) = 0 + 60×9/90 = 6
  arr[6] = 70 → FOUND in 1 step! (Binary cần 3-4 steps)
```

---

## ③ CODE

### Example 1: Standard Interpolation Search

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// InterpolationSearch: ước lượng vị trí dựa trên giá trị
//
// O(log log n) average cho uniform data
// O(n) worst cho exponential data → fallback Binary Search
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func InterpolationSearch(arr []int, target int) int {
    lo, hi := 0, len(arr)-1

    for lo <= hi && target >= arr[lo] && target <= arr[hi] {
        if arr[hi] == arr[lo] {
            if arr[lo] == target { return lo }
            return -1
        }

        // Interpolation formula
        pos := lo + (target-arr[lo])*(hi-lo)/(arr[hi]-arr[lo])

        switch {
        case arr[pos] == target:
            return pos
        case arr[pos] < target:
            lo = pos + 1
        default:
            hi = pos - 1
        }
    }
    return -1
}
```

### Example 2: Interpolation with Binary Search Fallback

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// InterpolationSearchSafe: fallback Binary Search sau K bad probes
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func InterpolationSearchSafe(arr []int, target int) int {
    lo, hi := 0, len(arr)-1
    badProbes := 0
    maxBadProbes := 3 // fallback threshold

    for lo <= hi && target >= arr[lo] && target <= arr[hi] {
        if arr[hi] == arr[lo] {
            if arr[lo] == target { return lo }
            return -1
        }

        var pos int
        if badProbes >= maxBadProbes {
            pos = lo + (hi-lo)/2 // fallback: binary search
        } else {
            pos = lo + (target-arr[lo])*(hi-lo)/(arr[hi]-arr[lo])
        }

        switch {
        case arr[pos] == target:
            return pos
        case arr[pos] < target:
            lo = pos + 1
            badProbes++
        default:
            hi = pos - 1
            badProbes++
        }
    }
    return -1
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Non-uniform data → O(n) | Fallback Binary Search |
| 2 | Division by zero: `arr[hi]==arr[lo]` | Guard check |
| 3 | Integer overflow: `(target-arr[lo])*(hi-lo)` | Dùng int64 |
| 4 | Assume luôn O(log log n) | Chỉ cho uniform — worst case O(n) |

---

**Liên kết**: [← Jump Search](./03-jump-search.md) · [→ Exponential Search](./05-exponential-search.md)
