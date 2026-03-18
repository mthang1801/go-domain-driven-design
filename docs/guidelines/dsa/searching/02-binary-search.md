# 🎯 Binary Search

> **Phân loại**: Divide & Conquer, Requires sorted data
> **Tóm tắt**: Chia đôi search space mỗi bước → O(log n). "Nền tảng" của search algorithms.

---

## ① DEFINE

### Thông số

| Metric | Value |
|--------|-------|
| **Best case** | O(1) — target ở giữa |
| **Average case** | O(log n) |
| **Worst case** | O(log n) |
| **Space** | O(1) iterative, O(log n) recursive |
| **Yêu cầu** | Array PHẢI sorted |

### Định nghĩa

**Binary Search** chia đôi search space mỗi bước. So sánh target với phần tử giữa → loại bỏ 1 nửa. Lặp lại cho đến khi tìm thấy hoặc space = 0.

### Variants quan trọng

| Variant | Mô tả | Use case |
|---------|--------|----------|
| **Standard** | Tìm index of target | Exact match |
| **LowerBound** | Index đầu tiên ≥ target | Insertion point, count < target |
| **UpperBound** | Index đầu tiên > target | Count ≤ target |
| **Leftmost** | Phần tử đầu tiên == target | First occurrence |
| **Rightmost** | Phần tử cuối == target | Last occurrence |

---

## ② GRAPH

```text
  Target = 23
  [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
   lo                                hi

  Step 1: mid=4, arr[4]=16 < 23 → lo=5
  [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
                       lo            hi
  Step 2: mid=7, arr[7]=56 > 23 → hi=6
  [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
                       lo  hi
  Step 3: mid=5, arr[5]=23 == 23 → FOUND ✓

  Comparisons: 3 (vs Linear: 6)
  log₂(10) ≈ 3.32 ✓
```

### LowerBound vs UpperBound

```text
  arr = [1, 3, 3, 3, 5, 7]     target = 3

  LowerBound(3) = 1   ← first index ≥ 3
  UpperBound(3) = 4   ← first index > 3
  Count of 3 = UpperBound - LowerBound = 4 - 1 = 3 ✓

  arr:     [1, 3, 3, 3, 5, 7]
  index:    0  1  2  3  4  5
               ↑LB       ↑UB
```

---

## ③ CODE

### Example 1: Iterative Binary Search

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BinarySearch: iterative — O(log n) time, O(1) space
//
// ⚠ Common bug: mid = (lo + hi) / 2 → integer overflow!
//    Fix: mid = lo + (hi - lo) / 2
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BinarySearch(arr []int, target int) int {
    lo, hi := 0, len(arr)-1
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

### Example 2: Recursive Binary Search

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BinarySearchRecursive: O(log n) time, O(log n) stack space
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BinarySearchRecursive(arr []int, target, lo, hi int) int {
    if lo > hi {
        return -1
    }
    mid := lo + (hi-lo)/2
    switch {
    case arr[mid] == target:
        return mid
    case arr[mid] < target:
        return BinarySearchRecursive(arr, target, mid+1, hi)
    default:
        return BinarySearchRecursive(arr, target, lo, mid-1)
    }
}
```

### Example 3: LowerBound & UpperBound (C++ STL equivalent)

**Mục tiêu**: Tìm insertion point, đếm occurrences, range queries.

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LowerBound: index đầu tiên ≥ target
// == C++ std::lower_bound
// Use: insertion point, count elements < target
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LowerBound(arr []int, target int) int {
    lo, hi := 0, len(arr)
    for lo < hi {
        mid := lo + (hi-lo)/2
        if arr[mid] < target {
            lo = mid + 1
        } else {
            hi = mid // arr[mid] >= target → candidate
        }
    }
    return lo
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UpperBound: index đầu tiên > target
// == C++ std::upper_bound
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func UpperBound(arr []int, target int) int {
    lo, hi := 0, len(arr)
    for lo < hi {
        mid := lo + (hi-lo)/2
        if arr[mid] <= target {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    return lo
}

// CountOccurrences = UpperBound - LowerBound → O(log n)
func CountOccurrences(arr []int, target int) int {
    return UpperBound(arr, target) - LowerBound(arr, target)
}

// EqualRange: [first, last) index range of target
func EqualRange(arr []int, target int) (int, int) {
    return LowerBound(arr, target), UpperBound(arr, target)
}
```

### Example 4: Binary Search on Answer — Search space trừu tượng

**Mục tiêu**: Binary search không chỉ trên array — search trên "answer space". Pattern phổ biến trong competitive programming.

```go
package searching

import (
    "fmt"
    "math"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Binary Search on Answer: tìm sqrt(n) bằng binary search
//
// Không tìm trong array — tìm trong [0, n]:
//   "giá trị nhỏ nhất x sao cho x*x >= n"
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func IntSqrt(n int) int {
    lo, hi := 0, n
    for lo < hi {
        mid := lo + (hi-lo)/2
        if mid*mid < n {
            lo = mid + 1
        } else {
            hi = mid
        }
    }
    if lo*lo == n {
        return lo
    }
    return lo - 1
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MinDays: tối thiểu bao nhiêu ngày để sản xuất M products
// capacity[i] = số ngày cần cho máy i sản xuất 1 product
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func MinDays(capacity []int, target int) int {
    lo, hi := 1, target*sliceMax(capacity)

    for lo < hi {
        mid := lo + (hi-lo)/2
        produced := 0
        for _, cap := range capacity {
            produced += mid / cap
        }
        if produced >= target {
            hi = mid
        } else {
            lo = mid + 1
        }
    }
    return lo
}

func sliceMax(arr []int) int {
    m := arr[0]
    for _, v := range arr[1:] {
        if v > m { m = v }
    }
    return m
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Float Binary Search: tìm cube root
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CubeRoot(n float64) float64 {
    lo, hi := 0.0, math.Max(1, n)
    for hi-lo > 1e-9 {
        mid := (lo + hi) / 2
        if mid*mid*mid < n {
            lo = mid
        } else {
            hi = mid
        }
    }
    return (lo + hi) / 2
}

func main() {
    fmt.Println("sqrt(25):", IntSqrt(25))   // 5
    fmt.Println("sqrt(26):", IntSqrt(26))   // 5
    fmt.Println("cbrt(27):", CubeRoot(27))  // 3.0
    fmt.Println("MinDays:", MinDays([]int{2, 3, 5}, 10)) // ?
}
```

### Example 5: Go stdlib — sort.Search + slices.BinarySearch

```go
package searching

import (
    "fmt"
    "sort"
    "slices" // Go 1.21+
)

func main() {
    arr := []int{1, 3, 5, 7, 9, 11, 13}

    // ━━━ sort.Search: generic predicate ━━━
    // Returns smallest index i where f(i)==true
    idx := sort.SearchInts(arr, 7)
    if idx < len(arr) && arr[idx] == 7 {
        fmt.Println("Found 7 at:", idx) // 3
    }

    // ━━━ sort.Search custom ━━━
    target := 10
    idx = sort.Search(len(arr), func(i int) bool {
        return arr[i] >= target
    })
    fmt.Printf("Insert %d at index %d\n", target, idx) // index 5

    // ━━━ slices.BinarySearch (Go 1.21+) ━━━
    idx2, found := slices.BinarySearch(arr, 7)
    fmt.Printf("slices.BinarySearch(7): idx=%d, found=%v\n", idx2, found)
}
```

### Example 6: Combo — Sorted Log Index with Time-Range Query

**Mục tiêu**: Production pattern — binary search cho time-range queries trên sorted log entries.

```go
package searching

import (
    "fmt"
    "sort"
    "sync"
    "time"
)

type LogEntry struct {
    Timestamp time.Time
    Level     string
    Message   string
}

type LogIndex struct {
    entries []LogEntry
    mu      sync.RWMutex
}

func NewLogIndex() *LogIndex { return &LogIndex{} }

func (idx *LogIndex) Insert(entry LogEntry) {
    idx.mu.Lock()
    defer idx.mu.Unlock()

    pos := sort.Search(len(idx.entries), func(i int) bool {
        return idx.entries[i].Timestamp.After(entry.Timestamp)
    })
    idx.entries = append(idx.entries, LogEntry{})
    copy(idx.entries[pos+1:], idx.entries[pos:])
    idx.entries[pos] = entry
}

// QueryTimeRange: O(log n + k) — k = số results
func (idx *LogIndex) QueryTimeRange(from, to time.Time) []LogEntry {
    idx.mu.RLock()
    defer idx.mu.RUnlock()

    start := sort.Search(len(idx.entries), func(i int) bool {
        return !idx.entries[i].Timestamp.Before(from)
    })
    end := sort.Search(len(idx.entries), func(i int) bool {
        return idx.entries[i].Timestamp.After(to)
    })

    if start >= end { return nil }
    result := make([]LogEntry, end-start)
    copy(result, idx.entries[start:end])
    return result
}

func main() {
    idx := NewLogIndex()
    base := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
    for i := 0; i < 1000; i++ {
        idx.Insert(LogEntry{
            Timestamp: base.Add(time.Duration(i) * time.Minute),
            Level:     []string{"INFO", "WARN", "ERROR"}[i%3],
            Message:   fmt.Sprintf("Log #%d", i),
        })
    }

    from := base.Add(10 * time.Hour)
    to := base.Add(12 * time.Hour)
    results := idx.QueryTimeRange(from, to)
    fmt.Printf("Logs 10:00-12:00: %d entries\n", len(results))
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | `mid = (lo + hi) / 2` overflow | `mid = lo + (hi-lo)/2` |
| 2 | Off-by-one: `lo <= hi` vs `lo < hi` | Standard: `<=`, LowerBound: `<` |
| 3 | Binary search trên unsorted data | LUÔN verify sorted |
| 4 | `sort.Search` returns insertion point, not -1 | Check `arr[idx] == target` |
| 5 | Forget `hi = len(arr)` cho LowerBound | Open range `[lo, hi)` |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| Go `sort.Search` | [pkg.go.dev/sort#Search](https://pkg.go.dev/sort#Search) |
| Go `slices.BinarySearch` | [pkg.go.dev/slices#BinarySearch](https://pkg.go.dev/slices#BinarySearch) |
| Binary Search on Answer | [codeforces.com/blog](https://codeforces.com/blog/entry/43722) |

---

## ⑥ RECOMMEND

| Extension | Khi nào |
|-----------|---------|
| **Binary Search on Answer** | Optimization problems — min/max feasible |
| **Fractional Cascading** | Multi-level binary search |
| **Exponential + Binary** | Unbounded search |

---

**Liên kết**: [← Linear Search](./01-linear-search.md) · [→ Jump Search](./03-jump-search.md) · [← README](./README.md)
