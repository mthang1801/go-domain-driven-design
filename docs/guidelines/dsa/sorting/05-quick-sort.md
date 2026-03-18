# ⚡ Quick Sort

> **Phân loại**: Comparison-based, Unstable, In-place, Divide & Conquer
> **Tóm tắt**: Chọn pivot → partition thành 2 phần (< pivot, > pivot) → recursion. Fastest average-case.

---

## ① DEFINE

### Thông số

| Metric | Value |
|--------|-------|
| **Best case** | O(n log n) |
| **Average case** | O(n log n) — fastest in practice |
| **Worst case** | O(n²) — bad pivot (sorted input, all equal) |
| **Space** | O(log n) — recursion stack |
| **Stable** | ❌ — partition swaps thay đổi relative order |
| **In-place** | ✅ — O(log n) stack only |
| **Adaptive** | ❌ (standard), ✅ (pdqsort) |
| **Cache-friendly** | ✅ — sequential access pattern |

### Định nghĩa

**Quick Sort** là thuật toán Divide & Conquer:
1. **Pivot**: chọn 1 phần tử làm pivot.
2. **Partition**: chia array thành 2 phần: phần tử < pivot (trái) và > pivot (phải).
3. **Recurse**: sort từng phần.

### Tại sao Quick Sort là default?

- **Fastest average case** — cache-friendly, ít data movement.
- **In-place** — chỉ O(log n) stack, không cần O(n) auxiliary.
- **Go stdlib**: `sort.Slice` dùng **pdqsort** (pattern-defeating quicksort).
- **C++ `std::sort`**: Introsort = Quick Sort + Heap Sort fallback.
- **Java `Arrays.sort`**: Dual-pivot Quicksort cho primitives.

### Invariants

- Sau partition: `arr[lo..p-1] < pivot <= arr[p+1..hi]`.
- Pivot ở đúng vị trí cuối cùng.
- Left partition + right partition = toàn bộ array (trừ pivot).

### Partition Strategies

| Strategy | Swaps | Implementation | Khi nào |
|----------|-------|----------------|---------|
| **Lomuto** | O(n) | Đơn giản, 1 pointer | Giáo dục |
| **Hoare** | O(n/2) | 2 pointers | General, nhanh hơn |
| **3-way (DNF)** | O(n) | 3 pointers | Nhiều duplicates |
| **Dual-pivot** | complex | 2 pivots, 3 parts | Java default |

---

## ② GRAPH

### Lomuto Partition — Single Pointer

```text
  Pivot = arr[hi] = 4
  [7, 2, 1, 6, 8, 5, 3, 4]
   ↑                     ↑
   i,j                   pivot

  j=0: 7≥4 → skip        [7, 2, 1, 6, 8, 5, 3, 4]  i=0
  j=1: 2<4 → swap(i,j)   [2, 7, 1, 6, 8, 5, 3, 4]  i=1
  j=2: 1<4 → swap(i,j)   [2, 1, 7, 6, 8, 5, 3, 4]  i=2
  j=3: 6≥4 → skip
  j=4: 8≥4 → skip
  j=5: 5≥4 → skip
  j=6: 3<4 → swap(i,j)   [2, 1, 3, 6, 8, 5, 7, 4]  i=3

  Swap pivot vào i:        [2, 1, 3, [4], 8, 5, 7, 6]
                           [< pivot]  ↑   [≥ pivot]
```

### Hoare Partition — Two Pointers

```text
  Pivot = arr[mid] = 6
  [7, 2, 1, 6, 8, 5, 3, 4]
   ↑ i                 j ↑

  Step 1: i→ find ≥6: i=0 (7)  |  j← find ≤6: j=7 (4) → swap
  [4, 2, 1, 6, 8, 5, 3, 7]
      ↑ i            j ↑

  Step 2: i→ find ≥6: i=3 (6)  |  j← find ≤6: j=6 (3) → swap
  [4, 2, 1, 3, 8, 5, 6, 7]
            ↑ i    j ↑

  Step 3: i→ find ≥6: i=4 (8)  |  j← find ≤6: j=5 (5) → i>j STOP
  [4, 2, 1, 3] [8, 5, 6, 7]
   ≤ 6 (left)   ≥ 6 (right)

  Hoare: ~2x ít swaps hơn Lomuto ⚡
```

### 3-Way Partition — Dutch National Flag

```text
  Pivot = 4      Array = [4, 9, 4, 4, 1, 9, 4, 3]
  lt=0, i=0, gt=7

  i=0: arr[0]=4 == pivot → i++
  i=1: arr[1]=9 > pivot  → swap(1,7), gt--  → [4, 3, 4, 4, 1, 9, 4, 9]
  i=1: arr[1]=3 < pivot  → swap(0,1), lt++, i++ → [3, 4, 4, 4, 1, 9, 4, 9]
  i=2: arr[2]=4 == pivot → i++
  i=3: arr[3]=4 == pivot → i++
  i=4: arr[4]=1 < pivot  → swap(1,4), lt++, i++ → [3, 1, 4, 4, 4, 9, 4, 9]
  ...

  Result: [1, 3] [4, 4, 4, 4] [9, 9]
          < pivot  = pivot      > pivot
          ↓ recurse             ↓ recurse
          (skip == pivot section → O(n) for all-equal!)
```

---

## ③ CODE

### Example 1: Lomuto Partition — Đơn giản nhất

**Mục tiêu**: Quick Sort với Lomuto partition — đơn giản, 1 pointer, pivot = last element.

**Cần gì**: Go standard library.

**Có gì**: Array → choose pivot → partition → recurse.

```go
package sorting

import (
    "fmt"
    "math/rand"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QuickSortLomuto: pivot = last element
//
// Lomuto partition:
//   i = boundary giữa [< pivot] và [≥ pivot]
//   j duyệt từ lo → hi-1
//   arr[j] < pivot → swap(i, j), i++
//
// Pros: đơn giản, dễ implement
// Cons: ~3x nhiều swaps hơn Hoare trên random data
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func QuickSortLomuto(arr []int, lo, hi int) {
    if lo < hi {
        p := lomutoPartition(arr, lo, hi)
        QuickSortLomuto(arr, lo, p-1)
        QuickSortLomuto(arr, p+1, hi)
    }
}

func lomutoPartition(arr []int, lo, hi int) int {
    // ━━━ Randomized pivot: tránh O(n²) cho sorted input ━━━
    randIdx := lo + rand.Intn(hi-lo+1)
    arr[randIdx], arr[hi] = arr[hi], arr[randIdx]

    pivot := arr[hi]
    i := lo // boundary: arr[lo..i-1] < pivot

    for j := lo; j < hi; j++ {
        if arr[j] < pivot {
            arr[i], arr[j] = arr[j], arr[i]
            i++
        }
    }

    arr[i], arr[hi] = arr[hi], arr[i] // pivot vào đúng vị trí
    return i
}

func main() {
    arr := []int{10, 7, 8, 9, 1, 5}
    QuickSortLomuto(arr, 0, len(arr)-1)
    fmt.Println(arr) // [1 5 7 8 9 10]
}
```

---

### Example 2: Hoare Partition — Nhanh hơn ~2x

**Mục tiêu**: Hoare partition — 2 pointers chạy từ 2 đầu, ít swaps hơn.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QuickSortHoare: 2-pointer partition
//
// i → từ trái, j ← từ phải
// i dừng khi arr[i] >= pivot
// j dừng khi arr[j] <= pivot
// i < j → swap → tiếp tục
//
// ⚡ ~3x ít swaps hơn Lomuto trên random data
// ⚠ Pivot KHÔNG ở đúng vị trí cuối cùng → recursion khác Lomuto
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func QuickSortHoare(arr []int, lo, hi int) {
    if lo < hi {
        p := hoarePartition(arr, lo, hi)
        QuickSortHoare(arr, lo, p)    // ← NOT p-1 (Hoare)
        QuickSortHoare(arr, p+1, hi)
    }
}

func hoarePartition(arr []int, lo, hi int) int {
    pivot := arr[lo+(hi-lo)/2] // median element as pivot
    i := lo - 1
    j := hi + 1

    for {
        // i → find first element >= pivot
        for {
            i++
            if arr[i] >= pivot {
                break
            }
        }
        // j ← find first element <= pivot
        for {
            j--
            if arr[j] <= pivot {
                break
            }
        }

        if i >= j {
            return j // partition point
        }
        arr[i], arr[j] = arr[j], arr[i]
    }
}
```

**Kết quả đạt được**:

- **~3x ít swaps** — 2 pointers converge, fewer unnecessary swaps.
- **Pivot = median element** — better than last element.

**Lưu ý**:

- **Recursion: `[lo, p]` và `[p+1, hi]`** — khác Lomuto `[lo, p-1]` và `[p+1, hi]`.
- **Edge case**: tránh infinite recursion — pivot PHẢI nằm trong `[lo, hi-1]`.

---

### Example 3: 3-Way Quick Sort — Dutch National Flag

**Mục tiêu**: 3-way partition cho arrays có nhiều duplicates — O(n) cho all-equal input.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QuickSort3Way: Dutch National Flag — 3 partitions
//
// [< pivot | == pivot | > pivot]
// lt, i, gt: 3 pointers
//
// ⚡ O(n) khi tất cả phần tử bằng nhau
// ⚡ O(n log k) khi k distinct values (k << n)
//
// Dijkstra's Dutch National Flag Problem (1976)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func QuickSort3Way(arr []int, lo, hi int) {
    if lo >= hi {
        return
    }

    pivot := arr[lo]
    lt := lo  // arr[lo..lt-1]   < pivot
    gt := hi  // arr[gt+1..hi]   > pivot
    i := lo   // arr[lt..i-1]    == pivot
              // arr[i..gt]       unexplored

    for i <= gt {
        switch {
        case arr[i] < pivot:
            arr[lt], arr[i] = arr[i], arr[lt]
            lt++
            i++
        case arr[i] > pivot:
            arr[i], arr[gt] = arr[gt], arr[i]
            gt--
            // ⚠ KHÔNG tăng i — phần tử mới swap vào chưa check
        default: // arr[i] == pivot
            i++
        }
    }

    // arr[lt..gt] == pivot → skip!
    QuickSort3Way(arr, lo, lt-1)
    QuickSort3Way(arr, gt+1, hi)
}
```

**Kết quả đạt được**:

- **O(n) cho all-equal** — `[5,5,5,5,5]` → 1 pass, 0 recursions.
- **O(n log k)** — k = số distinct values. k=2 → O(n).
- **Dutch National Flag** — classic algorithm design problem.

**Lưu ý**: Java `Arrays.sort` dùng **dual-pivot** (2 pivots, 3 partitions) — nhanh hơn 3-way trên practice.

---

### Example 4: Median-of-Three Pivot + Tail Call Optimization

**Mục tiêu**: Production-quality pivot selection + tối ưu stack depth.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QuickSortOptimized: production-grade optimizations
//
// 1. Median-of-three pivot: chọn median(lo, mid, hi) → tránh worst case
// 2. Tail call optimization: recurse shorter half → guaranteed O(log n) stack
// 3. Insertion Sort fallback: partition < 16 → Insertion Sort
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func QuickSortOptimized(arr []int) {
    quickSortOpt(arr, 0, len(arr)-1)
}

func quickSortOpt(arr []int, lo, hi int) {
    for lo < hi {
        // ━━━ Optimization 1: Insertion Sort cho small partitions ━━━
        if hi-lo+1 <= 16 {
            insertionSortRange(arr, lo, hi)
            return
        }

        // ━━━ Optimization 2: Median-of-three pivot ━━━
        mid := lo + (hi-lo)/2
        // Sort lo, mid, hi → median ở mid
        if arr[mid] < arr[lo] {
            arr[lo], arr[mid] = arr[mid], arr[lo]
        }
        if arr[hi] < arr[lo] {
            arr[lo], arr[hi] = arr[hi], arr[lo]
        }
        if arr[mid] < arr[hi] {
            arr[mid], arr[hi] = arr[hi], arr[mid]
        }
        // Pivot = arr[hi] = median of three
        pivot := arr[hi]

        // ━━━ Partition ━━━
        i := lo
        for j := lo; j < hi; j++ {
            if arr[j] < pivot {
                arr[i], arr[j] = arr[j], arr[i]
                i++
            }
        }
        arr[i], arr[hi] = arr[hi], arr[i]

        // ━━━ Optimization 3: Tail call — recurse shorter half ━━━
        // Guaranteed stack depth = O(log n)
        if i-lo < hi-i {
            quickSortOpt(arr, lo, i-1) // recurse shorter (left)
            lo = i + 1                  // iterate longer (right) → tail call
        } else {
            quickSortOpt(arr, i+1, hi) // recurse shorter (right)
            hi = i - 1                  // iterate longer (left)
        }
    }
}

func insertionSortRange(arr []int, lo, hi int) {
    for i := lo + 1; i <= hi; i++ {
        key := arr[i]
        j := i - 1
        for j >= lo && arr[j] > key {
            arr[j+1] = arr[j]
            j--
        }
        arr[j+1] = key
    }
}
```

**Kết quả đạt được**:

- **Median-of-three**: tránh worst case cho sorted/reverse input.
- **Tail call**: stack depth guaranteed O(log n) — no stack overflow.
- **Insertion Sort fallback**: partition < 16 → low overhead.
- **Đây chính là strategy của production-grade sort implementations**.

---

### Example 5: Introsort — Quick Sort + Heap Sort fallback

**Mục tiêu**: Introsort = Quick Sort + Heap Sort fallback khi recursion quá sâu → **guaranteed O(n log n)**.

```go
package sorting

import "math"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Introsort: Quick Sort + Heap Sort fallback
//
// C++ std::sort dùng Introsort
// Strategy:
//   depth < 2*log(n) → Quick Sort (fast average)
//   depth >= 2*log(n) → Heap Sort (guaranteed O(n log n))
//   n < 16 → Insertion Sort (low overhead)
//
// Time: O(n log n) — GUARANTEED (worst case = Heap Sort)
// Space: O(log n) — stack depth
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func Introsort(arr []int) {
    maxDepth := int(2 * math.Log2(float64(len(arr))))
    introsortHelper(arr, 0, len(arr)-1, maxDepth)
}

func introsortHelper(arr []int, lo, hi, depth int) {
    n := hi - lo + 1

    // ━━━ Base: Insertion Sort cho small partitions ━━━
    if n <= 16 {
        insertionSortRange(arr, lo, hi)
        return
    }

    // ━━━ Depth exceeded: fallback Heap Sort ━━━
    if depth == 0 {
        heapSortRange(arr, lo, hi)
        return
    }

    // ━━━ Quick Sort partition ━━━
    p := lomutoPartitionOpt(arr, lo, hi)
    introsortHelper(arr, lo, p-1, depth-1)
    introsortHelper(arr, p+1, hi, depth-1)
}

func lomutoPartitionOpt(arr []int, lo, hi int) int {
    // Median-of-three
    mid := lo + (hi-lo)/2
    if arr[mid] < arr[lo] { arr[lo], arr[mid] = arr[mid], arr[lo] }
    if arr[hi] < arr[lo] { arr[lo], arr[hi] = arr[hi], arr[lo] }
    if arr[mid] < arr[hi] { arr[mid], arr[hi] = arr[hi], arr[mid] }

    pivot := arr[hi]
    i := lo
    for j := lo; j < hi; j++ {
        if arr[j] < pivot {
            arr[i], arr[j] = arr[j], arr[i]
            i++
        }
    }
    arr[i], arr[hi] = arr[hi], arr[i]
    return i
}

// ━━━ Heap Sort for fallback ━━━
func heapSortRange(arr []int, lo, hi int) {
    n := hi - lo + 1
    // Build max heap
    for i := n/2 - 1; i >= 0; i-- {
        siftDown(arr, lo, i, n)
    }
    // Extract elements
    for i := n - 1; i > 0; i-- {
        arr[lo], arr[lo+i] = arr[lo+i], arr[lo]
        siftDown(arr, lo, 0, i)
    }
}

func siftDown(arr []int, offset, i, n int) {
    for {
        largest := i
        left := 2*i + 1
        right := 2*i + 2
        if left < n && arr[offset+left] > arr[offset+largest] {
            largest = left
        }
        if right < n && arr[offset+right] > arr[offset+largest] {
            largest = right
        }
        if largest == i {
            break
        }
        arr[offset+i], arr[offset+largest] = arr[offset+largest], arr[offset+i]
        i = largest
    }
}
```

**Kết quả đạt được**:

- **Guaranteed O(n log n)** — Heap Sort fallback khi Quick Sort degenerates.
- **3 algorithms trong 1**: Quick Sort (fast) + Heap Sort (guaranteed) + Insertion Sort (small).
- **C++ `std::sort`** = Introsort — đây là production standard.

---

### Example 6: Combo — Comprehensive Benchmark + Sort Stability Demo

**Mục tiêu**: Benchmark tất cả Quick Sort variants + demo stability issue.

```go
package sorting

import (
    "fmt"
    "math/rand"
    "sort"
    "time"
)

type Record struct {
    Name  string
    Score int
    Order int // insertion order
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Demo: Quick Sort is NOT stable
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func DemoStability() {
    records := []Record{
        {"Alice", 80, 1},
        {"Bob", 90, 2},
        {"Charlie", 80, 3},
        {"Diana", 80, 4},
    }

    // Quick Sort: unstable — equal-score records may reorder
    QuickSortFunc(records, func(a, b Record) bool {
        return a.Score < b.Score
    })

    fmt.Println("Quick Sort (unstable):")
    for _, r := range records {
        fmt.Printf("  %s: score=%d, order=%d\n", r.Name, r.Score, r.Order)
    }
    // May output:
    //   Charlie: score=80, order=3  ← order changed!
    //   Diana: score=80, order=4
    //   Alice: score=80, order=1    ← Alice moved after Charlie
    //   Bob: score=90, order=2

    // sort.SliceStable: stable — preserves order
    sort.SliceStable(records, func(i, j int) bool {
        return records[i].Score < records[j].Score
    })

    fmt.Println("\nsort.SliceStable (stable):")
    for _, r := range records {
        fmt.Printf("  %s: score=%d, order=%d\n", r.Name, r.Score, r.Order)
    }
    // Always:
    //   Alice: score=80, order=1    ← order preserved ✓
    //   Charlie: score=80, order=3
    //   Diana: score=80, order=4
    //   Bob: score=90, order=2
}

func QuickSortFunc[T any](arr []T, less func(a, b T) bool) {
    quickSortFuncHelper(arr, 0, len(arr)-1, less)
}

func quickSortFuncHelper[T any](arr []T, lo, hi int, less func(a, b T) bool) {
    if lo >= hi {
        return
    }
    pivot := arr[hi]
    i := lo
    for j := lo; j < hi; j++ {
        if less(arr[j], pivot) {
            arr[i], arr[j] = arr[j], arr[i]
            i++
        }
    }
    arr[i], arr[hi] = arr[hi], arr[i]
    quickSortFuncHelper(arr, lo, i-1, less)
    quickSortFuncHelper(arr, i+1, hi, less)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Benchmark tất cả variants
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BenchmarkQuickSort() {
    n := 100_000

    // Generate test data
    random := make([]int, n)
    for i := range random {
        random[i] = rand.Intn(n)
    }

    type algo struct {
        name string
        fn   func([]int)
    }

    algorithms := []algo{
        {"Lomuto", func(arr []int) { QuickSortLomuto(arr, 0, len(arr)-1) }},
        {"Hoare", func(arr []int) { QuickSortHoare(arr, 0, len(arr)-1) }},
        {"3-Way", func(arr []int) { QuickSort3Way(arr, 0, len(arr)-1) }},
        {"Optimized", QuickSortOptimized},
        {"Introsort", Introsort},
        {"stdlib", func(arr []int) { sort.Ints(arr) }},
    }

    fmt.Printf("\n━━━ Benchmark: n=%d random ━━━\n", n)
    for _, a := range algorithms {
        arr := make([]int, n)
        copy(arr, random)

        start := time.Now()
        a.fn(arr)
        elapsed := time.Since(start)

        sorted := sort.IntsAreSorted(arr)
        fmt.Printf("  %-12s: %10v  sorted=%v\n", a.name, elapsed, sorted)
    }

    // Test worst case: sorted input
    sorted := make([]int, n)
    for i := range sorted {
        sorted[i] = i
    }

    fmt.Printf("\n━━━ Benchmark: n=%d sorted (worst case) ━━━\n", n)
    for _, a := range algorithms {
        arr := make([]int, n)
        copy(arr, sorted)

        start := time.Now()
        a.fn(arr)
        elapsed := time.Since(start)
        fmt.Printf("  %-12s: %10v\n", a.name, elapsed)
    }

    // Test many duplicates
    dups := make([]int, n)
    for i := range dups {
        dups[i] = rand.Intn(10) // only 10 distinct values
    }

    fmt.Printf("\n━━━ Benchmark: n=%d with 10 distinct values ━━━\n", n)
    for _, a := range algorithms {
        arr := make([]int, n)
        copy(arr, dups)

        start := time.Now()
        a.fn(arr)
        elapsed := time.Since(start)
        fmt.Printf("  %-12s: %10v\n", a.name, elapsed)
    }
}
```

**Kết quả đạt được**:

- **Stability demo** — rõ ràng Quick Sort vs `sort.SliceStable`.
- **3 benchmark scenarios**: random, sorted (worst case), duplicates.
- **Variant comparison**: Lomuto vs Hoare vs 3-Way vs Optimized vs Introsort vs stdlib.

---

## ④ PITFALLS

| # | Lỗi | Nguyên nhân | Fix |
|---|------|-------------|-----|
| 1 | O(n²) cho sorted input | Pivot = min/max → unbalanced | Randomized / Median-of-three |
| 2 | Stack overflow cho large n | Recursion depth = n (worst) | Tail call + Introsort |
| 3 | All-equal elements → O(n²) | Lomuto/Hoare degenerate | 3-Way partition |
| 4 | Assume Quick Sort is stable | Partition swaps break order | Dùng `sort.SliceStable` |
| 5 | Hoare partition recursion wrong | `lo, p` not `lo, p-1` | Hoare: `[lo, p]` + `[p+1, hi]` |
| 6 | Not randomizing pivot | Adversarial input → O(n²) | `rand.Intn` cho pivot index |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| pdqsort (Go stdlib) | [arxiv.org/abs/2106.05123](https://arxiv.org/abs/2106.05123) |
| Visualgo — Quick Sort | [visualgo.net/sorting](https://visualgo.net/en/sorting) |
| Dual-pivot Quicksort (Java) | [arxiv.org](https://arxiv.org/abs/1511.01138) |
| Introsort | [en.wikipedia.org](https://en.wikipedia.org/wiki/Introsort) |
| Dutch National Flag | [en.wikipedia.org](https://en.wikipedia.org/wiki/Dutch_national_flag_problem) |

---

## ⑥ RECOMMEND

| Extension | Khi nào | Lý do |
|-----------|---------|-------|
| **Introsort** | Guaranteed O(n log n) | Quick + Heap fallback |
| **pdqsort** | Go stdlib default | Pattern-defeating, fastest |
| **3-Way** | Many duplicates | O(n) for all-equal |
| **Dual-pivot** | Java style | ~5% faster than single-pivot |
| **`sort.Slice`** | Production Go | ALWAYS use stdlib |

---

**Liên kết**: [← Merge Sort](./04-merge-sort.md) · [← README](./README.md)
