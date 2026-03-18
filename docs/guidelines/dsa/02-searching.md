# 🔍 Searching Algorithms — Thuật toán Tìm kiếm

> **Phạm vi**: 5 thuật toán tìm kiếm: Linear, Binary, Jump, Interpolation, Exponential Search.
> **Ngôn ngữ**: Go — với annotated comments chi tiết.

---

## ① DEFINE

### Bảng so sánh tổng quan

| Algorithm            | Time (Avg)    | Time (Worst)  | Space  | Yêu cầu Data     | Khi nào dùng |
|----------------------|---------------|---------------|--------|-------------------|--------------|
| Linear Search        | O(n)          | O(n)          | O(1)   | Không             | Unsorted, small n |
| Binary Search        | O(log n)      | O(log n)      | O(1)   | Sorted            | Sorted array, general |
| Jump Search          | O(√n)         | O(√n)         | O(1)   | Sorted            | Sorted + sequential access |
| Interpolation Search | O(log log n)  | O(n)          | O(1)   | Sorted + uniform  | Uniformly distributed data |
| Exponential Search   | O(log n)      | O(log n)      | O(1)   | Sorted            | Unbounded/infinite arrays |

### Định nghĩa chính

- **Linear Search (Sequential)**: duyệt từng phần tử từ đầu đến cuối → O(n). Đơn giản nhất, không yêu cầu data sorted.
- **Binary Search**: chia đôi search space mỗi bước → O(log n). Yêu cầu data sorted. "Nền tảng" của search algorithms.
- **Jump Search**: nhảy √n bước → tìm block chứa target → linear search trong block. Trade-off giữa linear và binary.
- **Interpolation Search**: ước lượng vị trí target dựa trên giá trị (tương tự tìm từ trong từ điển). O(log log n) cho uniform data.
- **Exponential Search**: tìm range chứa target bằng doubling → binary search trong range. Tốt cho unbounded arrays.

### Invariants

- **Binary Search**: target luôn nằm trong `[lo, hi]` — mỗi bước thu hẹp ≥ 1/2.
- **Interpolation**: position formula `lo + (target - arr[lo]) * (hi - lo) / (arr[hi] - arr[lo])` — chính xác hơn binary search cho uniform data.
- **Jump Search**: `arr[prev] <= target < arr[min(step, n)]` — target nằm trong block `[prev, step)`.

---

## ② GRAPH

### Binary Search — Divide Search Space

```text
  Target = 23

  [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
   lo                                hi
                  mid=16

  Step 1: 23 > 16 → search right half
  [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
                      lo          hi
                          mid=56

  Step 2: 23 < 56 → search left half
  [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
                      lo  hi
                      mid=23

  Step 3: 23 == 23 → FOUND at index 5 ✓

  Total comparisons: 3 (vs Linear: 6)
```

### Jump Search — Block-based

```text
  Target = 55, n = 16, step = √16 = 4

  [0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, ...]
   ↓           ↓           ↓            ↓
  jump 0      jump 4      jump 8       jump 12

  Step 1: arr[0]=0  < 55 → jump
  Step 2: arr[4]=3  < 55 → jump
  Step 3: arr[8]=21 < 55 → jump
  Step 4: arr[12]=89 > 55 → STOP

  Linear search in block [8..12]:
  arr[8]=21, arr[9]=34, arr[10]=55 → FOUND at index 10 ✓
```

### Exponential Search — Doubling Range

```text
  Target = 12

  [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

  Phase 1: Find range (doubling)
  i=1:  arr[1]=2  < 12 → i=2
  i=2:  arr[2]=3  < 12 → i=4
  i=4:  arr[4]=5  < 12 → i=8
  i=8:  arr[8]=9  < 12 → i=16 (> n)

  Phase 2: Binary search in [8..14]
  → Found at index 11 ✓
```

---

## ③ CODE

### Example 1: Linear Search — Cơ bản + Sentinel + Generic

**Mục tiêu**: 3 variants: basic linear search, sentinel optimization, generic version.

**Cần gì**: Go standard library.

**Có gì**: Slice → duyệt tuần tự → tìm target.

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LinearSearch: duyệt tuần tự từng phần tử
//
// Time: O(n) — worst case duyệt toàn bộ
// Space: O(1)
// Yêu cầu: KHÔNG — chạy trên mọi loại data
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LinearSearch(arr []int, target int) int {
    for i, v := range arr {
        if v == target {
            return i // tìm thấy → return index
        }
    }
    return -1 // không tìm thấy
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LinearSearchSentinel: giảm 1 comparison per iteration
//
// Trick: đặt target ở cuối array → không cần check bounds
// ~2x nhanh hơn basic version cho large arrays
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LinearSearchSentinel(arr []int, target int) int {
    n := len(arr)
    if n == 0 {
        return -1
    }

    // Lưu phần tử cuối, đặt sentinel
    last := arr[n-1]
    arr[n-1] = target

    i := 0
    for arr[i] != target { // không cần check i < n
        i++
    }

    // Restore phần tử cuối
    arr[n-1] = last

    if i < n-1 || arr[n-1] == target {
        return i
    }
    return -1
}

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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Generic version — Go 1.18+
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LinearSearchGeneric[T comparable](arr []T, target T) int {
    for i, v := range arr {
        if v == target {
            return i
        }
    }
    return -1
}
```

**Kết quả đạt được**:

- **3 variants**: basic, sentinel (faster), find-all.
- **Sentinel trick**: loại bỏ bound check → ~2× nhanh hơn cho large arrays.
- **Generic**: search bất kỳ `comparable` type.

**Lưu ý**:

- **Sentinel modifies input**: `arr[n-1]` bị thay đổi tạm → KHÔNG thread-safe.
- Linear Search là **lựa chọn duy nhất** cho unsorted data.
- Production: `slices.Index` (Go 1.21+) thay thế custom linear search.

---

### Example 2: Binary Search — Iterative + Recursive + Variants

**Mục tiêu**: Binary Search iterative + recursive, lower/upper bound (giống C++ `lower_bound`), và `sort.Search` wrapper.

**Cần gì**: Go standard library, `sort`.

**Có gì**: Sorted array → chia đôi search space → O(log n).

```go
package searching

import "sort"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BinarySearch (Iterative): chia đôi search space
//
// Time: O(log n) — chia đôi mỗi bước
// Space: O(1)
// Yêu cầu: array PHẢI sorted (ascending)
//
// ⚠ Common bug: mid = (lo + hi) / 2 → integer overflow!
//    Fix: mid = lo + (hi - lo) / 2
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BinarySearch(arr []int, target int) int {
    lo, hi := 0, len(arr)-1

    for lo <= hi {
        mid := lo + (hi-lo)/2 // ← tránh overflow

        switch {
        case arr[mid] == target:
            return mid // FOUND
        case arr[mid] < target:
            lo = mid + 1 // target ở nửa phải
        default:
            hi = mid - 1 // target ở nửa trái
        }
    }
    return -1 // NOT FOUND
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BinarySearchRecursive: recursive version
// Space: O(log n) — stack depth
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LowerBound: tìm index đầu tiên ≥ target (giống C++ lower_bound)
//
// Use case: "có bao nhiêu phần tử < target?" → LowerBound(arr, target)
// Use case: "chèn target vào sorted array mà vẫn sorted" → LowerBound
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LowerBound(arr []int, target int) int {
    lo, hi := 0, len(arr)
    for lo < hi {
        mid := lo + (hi-lo)/2
        if arr[mid] < target {
            lo = mid + 1
        } else {
            hi = mid // arr[mid] >= target → có thể là answer
        }
    }
    return lo // index đầu tiên ≥ target (hoặc len(arr) nếu không có)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UpperBound: tìm index đầu tiên > target (giống C++ upper_bound)
//
// Use case: "có bao nhiêu phần tử ≤ target?" → UpperBound(arr, target)
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CountOccurrences: đếm số lần target xuất hiện (sorted array)
// = UpperBound - LowerBound
// Time: O(log n) — 2 binary searches
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CountOccurrences(arr []int, target int) int {
    return UpperBound(arr, target) - LowerBound(arr, target)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Go stdlib wrapper: sort.Search — binary search chuẩn
// sort.Search tìm index nhỏ nhất i sao cho f(i) == true
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BinarySearchStdlib(arr []int, target int) int {
    idx := sort.SearchInts(arr, target) // = LowerBound
    if idx < len(arr) && arr[idx] == target {
        return idx
    }
    return -1
}
```

**Kết quả đạt được**:

- **Binary Search** iterative (O(1) space) + recursive (O(log n) space).
- **LowerBound/UpperBound**: C++ STL equivalent — cực kỳ hữu ích.
- **CountOccurrences**: O(log n) — 2 binary searches thay vì O(n) linear scan.
- **`sort.Search` wrapper**: stdlib integration.

**Lưu ý**:

- **⚠ Overflow bug**: `mid = (lo + hi) / 2` → overflow khi `lo + hi > MaxInt`. Fix: `mid = lo + (hi-lo)/2`.
- **Off-by-one**: `lo <= hi` vs `lo < hi` — iterative dùng `<=`, LowerBound dùng `<`.
- **Go 1.21+**: `slices.BinarySearch` thay thế `sort.SearchInts`.
- **Array PHẢI sorted** — binary search trên unsorted data → kết quả sai, KHÔNG có error.

---

### Example 3: Jump Search

**Mục tiêu**: Jump Search — nhảy √n bước → tìm block → linear search trong block.

**Cần gì**: Go standard library, `math`.

**Có gì**: Sorted array → jump blocks → linear scan.

```go
package searching

import "math"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// JumpSearch: nhảy √n bước, sau đó linear search trong block
//
// Tại sao √n? Optimal block size minimizes:
//   jumps (n/step) + linear scan (step) → n/step + step
//   Đạo hàm = 0 → step = √n
//
// Time: O(√n) — worst case: n/√n jumps + √n linear
// Space: O(1)
// Yêu cầu: sorted array
//
// So sánh Binary Search:
// - Binary: O(log n) nhưng cần random access (jump anywhere)
// - Jump: O(√n) nhưng chủ yếu dùng sequential access
// - Jump tốt hơn khi: sequential access nhanh hơn random (linked list, disk)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func JumpSearch(arr []int, target int) int {
    n := len(arr)
    if n == 0 {
        return -1
    }

    step := int(math.Sqrt(float64(n))) // optimal block size = √n
    prev := 0

    // ━━━ Phase 1: Jump forward tìm block chứa target ━━━
    // Tìm block sao cho arr[prev] <= target < arr[min(step, n)]
    for step < n && arr[step] < target {
        prev = step
        step += int(math.Sqrt(float64(n)))
    }

    // ━━━ Phase 2: Linear search trong block [prev, min(step, n)) ━━━
    for prev < n && prev <= step {
        if arr[prev] == target {
            return prev
        }
        if arr[prev] > target {
            break // overshoot → not found
        }
        prev++
    }

    return -1
}
```

**Kết quả đạt được**:

- **O(√n)** — trung gian giữa O(n) linear và O(log n) binary.
- **Sequential access pattern** — cache-friendly hơn binary search.

**Lưu ý**:

- **Chủ yếu dùng cho giáo dục** — production luôn dùng Binary Search.
- **Block size = √n** là toán học tối ưu, có thể tuning cho specific use case.
- Tốt cho **systems cần sequential access** (magnetic tape, linked list).

---

### Example 4: Interpolation Search

**Mục tiêu**: Interpolation Search — ước lượng vị trí target dựa trên giá trị (tương tự tra từ điển).

**Cần gì**: Go standard library.

**Có gì**: Sorted + uniformly distributed array → ước lượng vị trí → O(log log n) average.

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// InterpolationSearch: ước lượng vị trí dựa trên giá trị
//
// Tương tự tra từ điển:
// - Tìm "apple" → mở đầu sách (chữ A ở đầu)
// - Tìm "zebra" → mở cuối sách (chữ Z ở cuối)
// - Binary search: luôn mở giữa → chậm hơn cho trường hợp này
//
// Formula: pos = lo + (target - arr[lo]) × (hi - lo) / (arr[hi] - arr[lo])
//
// Time: O(log log n) avg (uniform data), O(n) worst (exponential data)
// Space: O(1)
// Yêu cầu: sorted + uniformly distributed
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func InterpolationSearch(arr []int, target int) int {
    lo, hi := 0, len(arr)-1

    for lo <= hi && target >= arr[lo] && target <= arr[hi] {
        // Guard: tránh division by zero
        if arr[hi] == arr[lo] {
            if arr[lo] == target {
                return lo
            }
            return -1
        }

        // ━━━ Interpolation formula: ước lượng vị trí target ━━━
        // Nếu data uniform: pos ≈ đúng vị trí → O(1) per step
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

**Kết quả đạt được**:

- **O(log log n)** cho uniformly distributed data — nhanh hơn Binary Search.
- **Interpolation formula** — ước lượng thông minh thay vì chia đôi.

**Lưu ý**:

- **Worst case O(n)**: data phân bố exponential (1, 2, 4, 8, 16, ...) → formula ước lượng sai.
- **Division by zero**: `arr[hi] == arr[lo]` → phải guard.
- **Integer overflow**: `(target - arr[lo]) * (hi - lo)` có thể overflow → dùng `int64` nếu cần.
- **Thực tế**: Binary Search luôn đủ tốt — Interpolation chỉ nhanh hơn cho uniform data.

---

### Example 5: Exponential Search

**Mục tiêu**: Exponential Search — tìm range bằng doubling → Binary Search trong range. Tốt cho unbounded/infinite arrays.

**Cần gì**: Go standard library.

**Có gì**: Sorted array (có thể unbounded) → find range → binary search.

```go
package searching

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ExponentialSearch: doubling range → binary search
//
// Use case: array SIZE KHÔNG BIẾT TRƯỚC (unbounded/infinite)
//   Step 1: tìm range bằng doubling (1, 2, 4, 8, 16, ...)
//   Step 2: binary search trong range [i/2, i]
//
// Time: O(log n) — O(log i) doubling + O(log i) binary search
// Space: O(1)
// Yêu cầu: sorted array
//
// Ưu điểm so với Binary Search:
// - Không cần biết length (unbounded arrays, streams)
// - O(log i) thay vì O(log n) — target ở đầu → nhanh hơn
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func ExponentialSearch(arr []int, target int) int {
    n := len(arr)
    if n == 0 {
        return -1
    }

    // Special case: target ở index 0
    if arr[0] == target {
        return 0
    }

    // ━━━ Phase 1: Doubling — tìm range chứa target ━━━
    // i doubles: 1, 2, 4, 8, 16, ... cho đến arr[i] >= target
    i := 1
    for i < n && arr[i] < target {
        i *= 2
    }

    // ━━━ Phase 2: Binary Search trong range [i/2, min(i, n-1)] ━━━
    lo := i / 2
    hi := i
    if hi >= n {
        hi = n - 1
    }
    return binarySearchRange(arr, target, lo, hi)
}

func binarySearchRange(arr []int, target, lo, hi int) int {
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

**Kết quả đạt được**:

- **O(log i)** — i = vị trí target → nếu target ở đầu array, nhanh hơn Binary Search O(log n).
- **Unbounded arrays**: không cần biết length trước.
- **Doubling** → tìm range → Binary Search trong range nhỏ.

**Lưu ý**:

- **Comparison vs Binary**: cùng sorted array, Binary Search đơn giản hơn và đủ tốt.
- **Real use case**: tìm kiếm trong sorted file/stream mà không biết size.
- **i doubles** → number of doubling steps = O(log i) — logarithmic range finding.

---

### Example 6: Combo — Search Engine với Binary Search + Trie-like Index

**Mục tiêu**: Production pattern — sorted log entries + binary search cho time-range queries + concurrent search.

**Cần gì**: Go standard library, `sort`, `sync`, `time`.

**Có gì**: 1M log entries sorted by timestamp → binary search cho time range → parallel search.

```go
package searching

import (
    "fmt"
    "sort"
    "sync"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LogEntry: sorted by Timestamp
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type LogEntry struct {
    Timestamp time.Time
    Level     string // "INFO", "WARN", "ERROR"
    Message   string
    Service   string
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LogIndex: sorted slice + binary search for time-range queries
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type LogIndex struct {
    entries []LogEntry // MUST be sorted by Timestamp
    mu      sync.RWMutex
}

func NewLogIndex() *LogIndex {
    return &LogIndex{}
}

// Insert: thêm log entry, giữ sorted order
func (idx *LogIndex) Insert(entry LogEntry) {
    idx.mu.Lock()
    defer idx.mu.Unlock()

    // Binary search tìm insertion point → O(log n)
    pos := sort.Search(len(idx.entries), func(i int) bool {
        return idx.entries[i].Timestamp.After(entry.Timestamp)
    })

    // Insert at position
    idx.entries = append(idx.entries, LogEntry{})
    copy(idx.entries[pos+1:], idx.entries[pos:])
    idx.entries[pos] = entry
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QueryTimeRange: tìm tất cả logs trong [from, to]
// Dùng 2 binary searches: LowerBound(from) + UpperBound(to)
// Time: O(log n + k) — k = số results
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (idx *LogIndex) QueryTimeRange(from, to time.Time) []LogEntry {
    idx.mu.RLock()
    defer idx.mu.RUnlock()

    // LowerBound: index đầu tiên >= from
    start := sort.Search(len(idx.entries), func(i int) bool {
        return !idx.entries[i].Timestamp.Before(from) // >= from
    })

    // UpperBound: index đầu tiên > to
    end := sort.Search(len(idx.entries), func(i int) bool {
        return idx.entries[i].Timestamp.After(to) // > to
    })

    if start >= end {
        return nil
    }

    // Copy results (immutable)
    results := make([]LogEntry, end-start)
    copy(results, idx.entries[start:end])
    return results
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QueryByLevel: filter by level trong time range
// Binary search (time) + linear filter (level)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (idx *LogIndex) QueryByLevel(from, to time.Time, level string) []LogEntry {
    rangeResults := idx.QueryTimeRange(from, to)

    var filtered []LogEntry
    for _, entry := range rangeResults {
        if entry.Level == level {
            filtered = append(filtered, entry)
        }
    }
    return filtered
}

func main() {
    idx := NewLogIndex()

    // Insert logs
    baseTime := time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC)
    for i := 0; i < 1000; i++ {
        idx.Insert(LogEntry{
            Timestamp: baseTime.Add(time.Duration(i) * time.Minute),
            Level:     []string{"INFO", "WARN", "ERROR"}[i%3],
            Message:   fmt.Sprintf("Log entry #%d", i),
            Service:   "api-gateway",
        })
    }

    // Query: logs from 10:00 to 12:00
    from := baseTime.Add(10 * time.Hour)
    to := baseTime.Add(12 * time.Hour)

    results := idx.QueryTimeRange(from, to)
    fmt.Printf("Logs 10:00-12:00: %d entries\n", len(results))

    errors := idx.QueryByLevel(from, to, "ERROR")
    fmt.Printf("Errors 10:00-12:00: %d entries\n", len(errors))
}
```

**Kết quả đạt được**:

- **O(log n + k)** time-range query trên 1M log entries — instant.
- **Binary search** cho time range boundaries (LowerBound + UpperBound).
- **Thread-safe** với `sync.RWMutex` — concurrent reads.
- **Real-world pattern**: log aggregation, time-series databases, event stores.

**Lưu ý**:

- **`sort.Search`** là Go stdlib binary search — luôn return insertion point.
- **Sorted insert**: O(log n) search + O(n) shift → chậm cho high-volume. Production: dùng B-tree hoặc LSM-tree.
- **Time-range query**: pattern phổ biến trong monitoring (Prometheus, Grafana), log search (ELK).
- Kết hợp với goroutines parallel search cho multi-index — xem [goroutines/05-errgroup](../goroutines/05-errgroup.md).

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Binary search trên unsorted array | LUÔN sort trước hoặc verify sorted |
| 2 | `mid = (lo + hi) / 2` → integer overflow | `mid = lo + (hi - lo) / 2` |
| 3 | Off-by-one: `lo <= hi` vs `lo < hi` | Iterative: `<=`, LowerBound: `<` |
| 4 | Interpolation search trên non-uniform data | Fallback Binary Search cho non-uniform |
| 5 | `sort.Search` return insertion point, not -1 | Luôn check `arr[idx] == target` |
| 6 | Sentinel search modify input array | Không dùng cho concurrent access |
| 7 | Jump Search block size sai | Luôn dùng `√n` — mathematically optimal |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| Go `sort.Search` | [pkg.go.dev/sort#Search](https://pkg.go.dev/sort#Search) |
| Go `slices.BinarySearch` (1.21+) | [pkg.go.dev/slices#BinarySearch](https://pkg.go.dev/slices#BinarySearch) |
| Binary Search — topcoder | [topcoder.com/binary-search](https://www.topcoder.com/thrive/articles/Binary%20Search) |
| Interpolation Search | [en.wikipedia.org](https://en.wikipedia.org/wiki/Interpolation_search) |

---

## ⑥ RECOMMEND

| Tool / Library | Mô tả | Khi nào dùng |
|----------------|--------|---------------|
| **`sort.Search`** | Go stdlib binary search — generic predicate | Production, any sorted data |
| **`slices.BinarySearch`** | Go 1.21+ generic binary search | New projects, type-safe |
| **`sort.SearchInts/Strings`** | Type-specific binary search | Quick prototyping |
| **`container/heap`** | Priority queue — efficient min/max finding | Top-K, median finding |

---

**Liên kết**: [← Sorting](./01-sorting.md) · [→ Graph](./03-graph.md) · [← README](./README.md)
