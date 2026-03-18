# 🔢 Sorting Algorithms — Thuật toán Sắp xếp

> **Phạm vi**: 5 thuật toán sắp xếp cốt lõi: Bubble Sort, Selection Sort, Insertion Sort, Merge Sort, Quick Sort.
> **Ngôn ngữ**: Go — với annotated comments chi tiết.

---

## ① DEFINE

### Bảng so sánh tổng quan

| Algorithm      | Best      | Average   | Worst     | Space  | Stable | In-place | Khi nào dùng |
|----------------|-----------|-----------|-----------|--------|--------|----------|--------------|
| Bubble Sort    | O(n)      | O(n²)     | O(n²)     | O(1)   | ✅     | ✅       | Giáo dục, n rất nhỏ |
| Selection Sort | O(n²)     | O(n²)     | O(n²)     | O(1)   | ❌     | ✅       | Memory hạn chế, n nhỏ |
| Insertion Sort | O(n)      | O(n²)     | O(n²)     | O(1)   | ✅     | ✅       | Gần sorted, n nhỏ (< 50) |
| Merge Sort     | O(n log n)| O(n log n)| O(n log n)| O(n)   | ✅     | ❌       | Cần stable + guaranteed O(n log n) |
| Quick Sort     | O(n log n)| O(n log n)| O(n²)     | O(log n)| ❌    | ✅       | General-purpose, fastest average |

### Định nghĩa chính

- **Stable sort**: giữ nguyên thứ tự tương đối của các phần tử bằng nhau. Ví dụ: sort students theo điểm — stable sort giữ thứ tự ban đầu nếu cùng điểm.
- **In-place sort**: không cần bộ nhớ phụ O(n) — chỉ dùng O(1) hoặc O(log n) stack space.
- **Comparison-based**: so sánh cặp phần tử — lower bound O(n log n).
- **Adaptive**: tận dụng data đã sorted → performance tốt hơn average (Insertion Sort best case O(n)).

### Invariants

- **Bubble Sort**: Sau mỗi pass, phần tử lớn nhất "nổi" lên cuối → vùng sorted mở rộng từ phải qua trái.
- **Selection Sort**: Sau mỗi iteration, phần tử nhỏ nhất được chọn và đặt đúng vị trí → vùng sorted mở rộng từ trái qua phải.
- **Insertion Sort**: Tại mỗi bước, phần tử hiện tại được chèn vào đúng vị trí trong vùng đã sorted.
- **Merge Sort**: Chia đôi → sort từng nửa → merge hai nửa đã sorted → kết quả sorted.
- **Quick Sort**: Chọn pivot → partition thành 2 phần (< pivot, > pivot) → recursion.

---

## ② GRAPH

### Bubble Sort — Visualization

```text
  Pass 1:  [5, 3, 8, 1, 2]
            ↕↕
           [3, 5, 8, 1, 2]  → swap(5,3)
               ↕↕
           [3, 5, 8, 1, 2]  → no swap
                  ↕↕
           [3, 5, 1, 8, 2]  → swap(8,1)
                     ↕↕
           [3, 5, 1, 2, 8]  → swap(8,2)   ← 8 bubbled to end ✓

  Pass 2:  [3, 5, 1, 2, |8]
            ↕↕
           [3, 5, 1, 2, |8]  → no swap
               ↕↕
           [3, 1, 5, 2, |8]  → swap(5,1)
                  ↕↕
           [3, 1, 2, 5, |8]  → swap(5,2)  ← 5 bubbled ✓

  Pass 3:  [3, 1, 2, |5, 8]
           [1, 2, 3, |5, 8]  ← sorted ✓
```

### Merge Sort — Divide & Conquer

```text
               [38, 27, 43, 3, 9, 82, 10]
              ╱                            ╲
       [38, 27, 43, 3]              [9, 82, 10]
       ╱             ╲              ╱           ╲
   [38, 27]      [43, 3]      [9, 82]        [10]
   ╱     ╲       ╱     ╲      ╱     ╲          │
 [38]   [27]  [43]    [3]   [9]   [82]       [10]
   ╲     ╱       ╲     ╱      ╲     ╱          │
   [27, 38]      [3, 43]      [9, 82]        [10]
       ╲             ╱              ╲           ╱
       [3, 27, 38, 43]              [9, 10, 82]
              ╲                            ╱
         [3, 9, 10, 27, 38, 43, 82]  ← sorted ✓
```

### Quick Sort — Partition

```text
  Pivot = 4
  [7, 2, 1, 6, 8, 5, 3, 4]
   i→                  ←j

  Step 1: i=7(>4), j=3(<4) → swap
  [3, 2, 1, 6, 8, 5, 7, 4]

  Step 2: i=6(>4), j=1(<4) → swap
  [3, 2, 1, 6, 8, 5, 7, 4]
              ↕
  i meets j → partition done

  [3, 2, 1] [4] [8, 5, 7, 6]
   < pivot   =    > pivot

  Recurse left + right → sorted ✓
```

---

## ③ CODE

### Example 1: Bubble Sort — Cơ bản + Optimized

**Mục tiêu**: Implement Bubble Sort thuần túy và phiên bản tối ưu (early termination khi không có swap).

**Cần gì**: Go standard library.

**Có gì**: Slice integers → sort ascending.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BubbleSort: so sánh cặp liền kề, swap nếu sai thứ tự
//
// Invariant: sau pass thứ i, i phần tử lớn nhất ở đúng vị trí cuối
// Time: O(n²) average, O(n) best (already sorted)
// Space: O(1) — in-place
// Stable: ✅ — không swap phần tử bằng nhau
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BubbleSort(arr []int) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        swapped := false // ← optimization flag
        for j := 0; j < n-1-i; j++ {
            if arr[j] > arr[j+1] {
                arr[j], arr[j+1] = arr[j+1], arr[j] // swap
                swapped = true
            }
        }
        // ━━━ Early termination: nếu không swap → đã sorted ━━━
        if !swapped {
            break // Best case: O(n) cho already-sorted input
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BubbleSortGeneric: Go 1.18+ generics — sort any Ordered type
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Ordered interface {
    ~int | ~int8 | ~int16 | ~int32 | ~int64 |
        ~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 |
        ~float32 | ~float64 | ~string
}

func BubbleSortGeneric[T Ordered](arr []T) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        swapped := false
        for j := 0; j < n-1-i; j++ {
            if arr[j] > arr[j+1] {
                arr[j], arr[j+1] = arr[j+1], arr[j]
                swapped = true
            }
        }
        if !swapped {
            break
        }
    }
}
```

**Kết quả đạt được**:

- **Bubble Sort thuần túy** + **early termination optimization**.
- **Generic version** cho Go 1.18+ — sort `int`, `float64`, `string` cùng 1 function.

**Lưu ý**:

- **Không dùng trong production** cho dataset lớn — O(n²) quá chậm.
- **Best case O(n)** chỉ khi input đã sorted + có `swapped` flag.
- Dùng cho giáo dục hoặc n < 20.

---

### Example 2: Selection Sort

**Mục tiêu**: Implement Selection Sort — tìm minimum và swap vào đúng vị trí.

**Cần gì**: Go standard library.

**Có gì**: Slice integers → tìm min → swap → lặp lại.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SelectionSort: tìm phần tử nhỏ nhất → đặt vào đầu vùng unsorted
//
// Invariant: sau iteration thứ i, arr[0..i] chứa i+1 phần tử nhỏ nhất
// Time: O(n²) — luôn O(n²), không tối ưu theo data
// Space: O(1) — in-place
// Stable: ❌ — swap có thể thay đổi relative order
//
// Ưu điểm:  ít swap nhất (đúng n-1 swaps) → tốt khi write expensive
// Nhược: luôn O(n²) kể cả sorted input
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func SelectionSort(arr []int) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        minIdx := i
        // Tìm index của phần tử nhỏ nhất trong arr[i+1..n-1]
        for j := i + 1; j < n; j++ {
            if arr[j] < arr[minIdx] {
                minIdx = j
            }
        }
        // Swap phần tử nhỏ nhất vào vị trí i
        if minIdx != i {
            arr[i], arr[minIdx] = arr[minIdx], arr[i]
        }
    }
}
```

**Kết quả đạt được**:

- **Đúng n-1 swaps** — tối thiểu số lần ghi vào memory.
- Phù hợp khi write operation (ví dụ: Flash memory) đắt hơn compare.

**Lưu ý**:

- **Không stable**: swap jump → thay đổi relative order. Ví dụ: `[5a, 3, 5b, 1]` → `[1, 3, 5b, 5a]`.
- **Luôn O(n²)**: không có early termination — không phân biệt sorted vs unsorted.

---

### Example 3: Insertion Sort

**Mục tiêu**: Implement Insertion Sort — chèn phần tử vào đúng vị trí trong vùng sorted (giống xếp bài).

**Cần gì**: Go standard library.

**Có gì**: Slice integers → mỗi phần tử được chèn vào vùng sorted bên trái.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// InsertionSort: chèn phần tử vào vùng sorted — tương tự xếp bài
//
// Invariant: arr[0..i-1] luôn sorted tại mỗi bước
// Time: O(n²) worst/avg, O(n) best (already sorted)
// Space: O(1) — in-place
// Stable: ✅ — shift, không swap qua phần tử bằng nhau
//
// ✅ BEST khi: n nhỏ (< 50), nearly sorted, online (streaming data)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func InsertionSort(arr []int) {
    for i := 1; i < len(arr); i++ {
        key := arr[i] // phần tử cần chèn
        j := i - 1

        // Shift các phần tử lớn hơn key sang phải
        for j >= 0 && arr[j] > key {
            arr[j+1] = arr[j] // shift right (không phải swap)
            j--
        }
        arr[j+1] = key // chèn key vào đúng vị trí
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BinaryInsertionSort: dùng Binary Search tìm vị trí chèn
// Giảm số lần compare từ O(n) → O(log n) per element
// Tổng: O(n log n) compares + O(n²) shifts = O(n²) overall
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BinaryInsertionSort(arr []int) {
    for i := 1; i < len(arr); i++ {
        key := arr[i]

        // Binary search cho vị trí chèn trong arr[0..i-1]
        lo, hi := 0, i
        for lo < hi {
            mid := lo + (hi-lo)/2
            if arr[mid] > key {
                hi = mid
            } else {
                lo = mid + 1 // stable: chèn SAU phần tử bằng
            }
        }

        // Shift arr[lo..i-1] sang phải 1 vị trí
        copy(arr[lo+1:i+1], arr[lo:i])
        arr[lo] = key
    }
}
```

**Kết quả đạt được**:

- **Insertion Sort thuần túy** — O(n) best case cho nearly sorted data.
- **Binary Insertion Sort** — giảm compares, vẫn O(n²) shifts nhưng cache-friendly hơn.

**Lưu ý**:

- **Go stdlib** dùng Insertion Sort cho n < 12 (bên trong `sort.Slice`) → overhead thấp.
- **Online algorithm**: có thể sort elements khi nhận từng cái một (streaming).
- **Adaptive**: performance phụ thuộc "inversions" — càng ít inversions, càng nhanh.

---

### Example 4: Merge Sort — Divide & Conquer + Concurrent

**Mục tiêu**: Implement Merge Sort chuẩn + phiên bản concurrent dùng goroutines cho large arrays.

**Cần gì**: Go standard library, `sync`.

**Có gì**: Merge Sort recursion → split → sort → merge. Version 2 dùng goroutines cho parallel sorting.

```go
package sorting

import "sync"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MergeSort: Divide & Conquer — guaranteed O(n log n)
//
// 1. Divide: chia đôi array
// 2. Conquer: recursion sort mỗi nửa
// 3. Combine: merge 2 nửa đã sorted
//
// Time: O(n log n) — luôn, không phụ thuộc data
// Space: O(n) — cần auxiliary array cho merge
// Stable: ✅ — merge giữ relative order
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func MergeSort(arr []int) []int {
    if len(arr) <= 1 {
        return arr
    }

    mid := len(arr) / 2
    left := MergeSort(arr[:mid])   // sort nửa trái
    right := MergeSort(arr[mid:])  // sort nửa phải
    return merge(left, right)      // merge 2 nửa sorted
}

// merge: merge 2 sorted slices thành 1 sorted slice
func merge(left, right []int) []int {
    result := make([]int, 0, len(left)+len(right))
    i, j := 0, 0

    // So sánh phần tử nhỏ hơn → append
    for i < len(left) && j < len(right) {
        if left[i] <= right[j] { // ← "=" → stable sort
            result = append(result, left[i])
            i++
        } else {
            result = append(result, right[j])
            j++
        }
    }

    // Append phần còn lại
    result = append(result, left[i:]...)
    result = append(result, right[j:]...)
    return result
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MergeSortConcurrent: parallel merge sort dùng goroutines
//
// Khi n lớn (> 10000): tận dụng multi-core CPU
// Khi n nhỏ (< 2048): fallback sang sequential (overhead goroutine)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const concurrencyThreshold = 2048

func MergeSortConcurrent(arr []int) []int {
    if len(arr) <= 1 {
        return arr
    }

    // Fallback: sequential cho small arrays
    if len(arr) < concurrencyThreshold {
        return MergeSort(arr)
    }

    mid := len(arr) / 2
    var left, right []int
    var wg sync.WaitGroup

    // ━━━ Sort left half in goroutine ━━━
    wg.Add(1)
    go func() {
        defer wg.Done()
        left = MergeSortConcurrent(arr[:mid])
    }()

    // ━━━ Sort right half in goroutine ━━━
    wg.Add(1)
    go func() {
        defer wg.Done()
        right = MergeSortConcurrent(arr[mid:])
    }()

    wg.Wait()
    return merge(left, right)
}
```

**Kết quả đạt được**:

- **Merge Sort chuẩn** — guaranteed O(n log n), stable.
- **Concurrent version** — tận dụng multi-core CPU cho large arrays.
- **Threshold `2048`** — tránh overhead goroutine cho small arrays.

**Lưu ý**:

- **Space O(n)**: cần `n` extra space cho merge → không phải in-place.
- **Concurrent Merge Sort**: goroutine per recursion → explosion risk nếu không có threshold.
- **Go stdlib `sort.Slice`**: dùng pattern-defeating quicksort (pdqsort), không phải merge sort.
- **External sorting**: Merge Sort là nền tảng cho disk-based sorting (tách file → sort → merge).

---

### Example 5: Quick Sort — Lomuto + Hoare Partition + 3-way

**Mục tiêu**: 3 variants của Quick Sort: Lomuto (đơn giản), Hoare (nhanh hơn), 3-way (xử lý duplicates).

**Cần gì**: Go standard library, `math/rand`.

**Có gì**: Quick Sort với 3 chiến lược partition khác nhau.

```go
package sorting

import (
    "math/rand"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QuickSort (Lomuto Partition): đơn giản, dễ hiểu
//
// Pivot = phần tử cuối
// Partition: gom phần tử < pivot sang trái
// Time: O(n log n) avg, O(n²) worst (sorted input)
// Space: O(log n) — stack depth
// Stable: ❌
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func QuickSort(arr []int, lo, hi int) {
    if lo < hi {
        p := lomutoPartition(arr, lo, hi)
        QuickSort(arr, lo, p-1)  // left of pivot
        QuickSort(arr, p+1, hi)  // right of pivot
    }
}

func lomutoPartition(arr []int, lo, hi int) int {
    // Randomized pivot: tránh worst case cho sorted input
    randIdx := lo + rand.Intn(hi-lo+1)
    arr[randIdx], arr[hi] = arr[hi], arr[randIdx]

    pivot := arr[hi] // pivot = phần tử cuối (sau swap)
    i := lo          // boundary: arr[lo..i-1] < pivot

    for j := lo; j < hi; j++ {
        if arr[j] < pivot {
            arr[i], arr[j] = arr[j], arr[i]
            i++
        }
    }
    arr[i], arr[hi] = arr[hi], arr[i] // đặt pivot vào đúng vị trí
    return i
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QuickSortHoare: Hoare partition — ít swaps hơn Lomuto
//
// 2 pointers: i từ trái, j từ phải → gặp nhau ở giữa
// ⚡ ~3x ít swaps hơn Lomuto trên random data
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func QuickSortHoare(arr []int, lo, hi int) {
    if lo < hi {
        p := hoarePartition(arr, lo, hi)
        QuickSortHoare(arr, lo, p)
        QuickSortHoare(arr, p+1, hi)
    }
}

func hoarePartition(arr []int, lo, hi int) int {
    pivot := arr[lo+(hi-lo)/2] // pivot = phần tử giữa
    i := lo - 1
    j := hi + 1

    for {
        // Tìm phần tử >= pivot từ trái
        for {
            i++
            if arr[i] >= pivot {
                break
            }
        }
        // Tìm phần tử <= pivot từ phải
        for {
            j--
            if arr[j] <= pivot {
                break
            }
        }
        if i >= j {
            return j
        }
        arr[i], arr[j] = arr[j], arr[i]
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// QuickSort3Way: Dutch National Flag — tối ưu cho nhiều duplicates
//
// Chia thành 3 vùng: [< pivot | == pivot | > pivot]
// Time: O(n) khi tất cả phần tử bằng nhau!
// Dùng khi: data có nhiều giá trị trùng lặp
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func QuickSort3Way(arr []int, lo, hi int) {
    if lo >= hi {
        return
    }

    // Dutch National Flag partition
    pivot := arr[lo]
    lt := lo  // arr[lo..lt-1]  < pivot
    gt := hi  // arr[gt+1..hi]  > pivot
    i := lo   // arr[lt..i-1]   == pivot

    for i <= gt {
        switch {
        case arr[i] < pivot:
            arr[lt], arr[i] = arr[i], arr[lt]
            lt++
            i++
        case arr[i] > pivot:
            arr[i], arr[gt] = arr[gt], arr[i]
            gt-- // không tăng i — cần check phần tử mới swap vào
        default: // arr[i] == pivot
            i++
        }
    }

    // arr[lt..gt] đều == pivot → không cần sort lại
    QuickSort3Way(arr, lo, lt-1)
    QuickSort3Way(arr, gt+1, hi)
}
```

**Kết quả đạt được**:

- **Lomuto**: đơn giản nhất, dễ implement, dễ debug.
- **Hoare**: ~3× ít swaps → nhanh hơn trên practice.
- **3-way**: O(n) khi nhiều duplicates (Dutch National Flag problem).
- **Randomized pivot**: tránh worst case O(n²) cho sorted input.

**Lưu ý**:

- **Go stdlib `sort.Slice`** dùng pdqsort (pattern-defeating quicksort) — hybrid algorithm.
- **Worst case O(n²)**: khi pivot luôn là min/max → randomized pivot giải quyết.
- **Tail recursion**: có thể optimize bằng cách recurse nửa nhỏ hơn trước → stack depth O(log n).
- **Introsort**: Quick Sort + fallback Heap Sort khi recursion depth quá sâu → guaranteed O(n log n).

---

### Example 6: Combo — Hybrid Sort + Benchmark + sort.Interface

**Mục tiêu**: Production-ready hybrid sort (Quick Sort + Insertion Sort cho small partitions) + implement `sort.Interface` + benchmark comparison.

**Cần gì**: Go standard library, `sort`, `testing`.

**Có gì**: Hybrid Sort kết hợp ưu điểm Quick Sort (fast trên large) + Insertion Sort (fast trên small).

```go
package sorting

import (
    "fmt"
    "math/rand"
    "sort"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HybridSort: Quick Sort + Insertion Sort
//
// Tại sao hybrid?
// - Quick Sort: overhead cho small partitions (function calls, pivot selection)
// - Insertion Sort: O(n²) nhưng constant factor nhỏ, cache-friendly
// - Threshold ~16: partition < 16 → Insertion Sort
//
// Đây chính là strategy mà Go stdlib, Java, C++ stdlib đều dùng
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const insertionThreshold = 16

func HybridSort(arr []int) {
    hybridQuickSort(arr, 0, len(arr)-1)
}

func hybridQuickSort(arr []int, lo, hi int) {
    for lo < hi {
        // ━━━ Small partition → Insertion Sort ━━━
        if hi-lo+1 <= insertionThreshold {
            insertionSortRange(arr, lo, hi)
            return
        }

        // ━━━ Median-of-three pivot ━━━
        mid := lo + (hi-lo)/2
        if arr[mid] < arr[lo] {
            arr[lo], arr[mid] = arr[mid], arr[lo]
        }
        if arr[hi] < arr[lo] {
            arr[lo], arr[hi] = arr[hi], arr[lo]
        }
        if arr[mid] < arr[hi] {
            arr[mid], arr[hi] = arr[hi], arr[mid]
        }
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

        // ━━━ Tail call optimization: recurse shorter half ━━━
        if i-lo < hi-i {
            hybridQuickSort(arr, lo, i-1)
            lo = i + 1 // tail call → loop
        } else {
            hybridQuickSort(arr, i+1, hi)
            hi = i - 1 // tail call → loop
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Implement sort.Interface — sort any struct
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Employee struct {
    Name   string
    Salary float64
    Age    int
}

// BySalary implements sort.Interface — sort employees by salary DESC
type BySalary []Employee

func (s BySalary) Len() int           { return len(s) }
func (s BySalary) Less(i, j int) bool { return s[i].Salary > s[j].Salary } // DESC
func (s BySalary) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

// MultiSort: sort theo nhiều criteria (salary DESC, nếu = thì age ASC)
type MultiSort []Employee

func (s MultiSort) Len() int { return len(s) }
func (s MultiSort) Less(i, j int) bool {
    if s[i].Salary != s[j].Salary {
        return s[i].Salary > s[j].Salary // salary DESC
    }
    return s[i].Age < s[j].Age // age ASC (tiebreaker)
}
func (s MultiSort) Swap(i, j int) { s[i], s[j] = s[j], s[i] }

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Benchmark: so sánh performance các algorithms
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func RunBenchmark() {
    sizes := []int{100, 1_000, 10_000, 100_000}

    for _, n := range sizes {
        // Generate random data
        data := make([]int, n)
        for i := range data {
            data[i] = rand.Intn(n * 10)
        }

        algorithms := map[string]func([]int){
            "BubbleSort":    BubbleSort,
            "InsertionSort": InsertionSort,
            "MergeSort": func(arr []int) {
                copy(arr, MergeSort(arr))
            },
            "QuickSort": func(arr []int) {
                QuickSort(arr, 0, len(arr)-1)
            },
            "HybridSort": HybridSort,
            "StdlibSort": func(arr []int) {
                sort.Ints(arr)
            },
        }

        fmt.Printf("\n━━━ n = %d ━━━\n", n)
        for name, sortFn := range algorithms {
            if n > 10_000 && (name == "BubbleSort") {
                fmt.Printf("  %-15s: SKIPPED (too slow)\n", name)
                continue
            }

            // Copy data để fair comparison
            arr := make([]int, n)
            copy(arr, data)

            start := time.Now()
            sortFn(arr)
            elapsed := time.Since(start)

            // Verify sorted
            sorted := sort.IntsAreSorted(arr)
            fmt.Printf("  %-15s: %12v  sorted=%v\n", name, elapsed, sorted)
        }
    }
}

func main() {
    // ━━━ sort.Interface demo ━━━
    employees := []Employee{
        {"Alice", 85000, 30},
        {"Bob", 92000, 25},
        {"Charlie", 85000, 28},
        {"Diana", 92000, 32},
    }

    sort.Sort(MultiSort(employees))
    for _, e := range employees {
        fmt.Printf("  %s: $%.0f, age %d\n", e.Name, e.Salary, e.Age)
    }
    // Output:
    // Bob: $92000, age 25      ← salary DESC
    // Diana: $92000, age 32    ← salary =, age ASC
    // Charlie: $85000, age 28
    // Alice: $85000, age 30

    // ━━━ Benchmark ━━━
    RunBenchmark()
}
```

**Kết quả đạt được**:

- **Hybrid Sort**: production-level — Quick Sort cho large + Insertion Sort cho small partitions.
- **Median-of-three**: chọn pivot tốt hơn → tránh worst case.
- **Tail call optimization**: recurse shorter half → stack depth guaranteed O(log n).
- **sort.Interface**: custom sort cho struct — multi-criteria sorting.
- **Benchmark**: fair comparison giữa tất cả algorithms.

**Lưu ý**:

- **Go `sort.Slice`** (Go 1.8+): simple API, không cần implement interface.
- **Go 1.19+**: `sort.Slice` dùng pdqsort — pattern-defeating quicksort.
- **`slices.Sort`** (Go 1.21+): generic sort, nhanh hơn `sort.Slice` ~10%.
- Production: **LUÔN dùng `sort.Slice`/`slices.Sort`** — chỉ implement custom khi cần special behavior.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Quick Sort O(n²) cho sorted input | Dùng randomized pivot hoặc median-of-three |
| 2 | Merge Sort dùng quá nhiều memory | Dùng in-place merge hoặc chuyển sang Quick Sort |
| 3 | `sort.Slice` không stable | Dùng `sort.SliceStable` nếu cần giữ relative order |
| 4 | Goroutine explosion trong concurrent sort | Thêm threshold — fallback sequential cho small arrays |
| 5 | Selection Sort dùng cho large dataset | Chỉ dùng khi n < 100 hoặc write-expensive |
| 6 | Bubble Sort trong production code | KHÔNG BAO GIỜ — dùng stdlib sort |
| 7 | Quick Sort stack overflow | Tail call optimization + introsort fallback |
| 8 | So sánh float NaN trong sort | `math.IsNaN` check trước khi sort |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| Go `sort` package | [pkg.go.dev/sort](https://pkg.go.dev/sort) |
| Go `slices` package (1.21+) | [pkg.go.dev/slices](https://pkg.go.dev/slices) |
| Visualgo — Sorting Animations | [visualgo.net/sorting](https://visualgo.net/en/sorting) |
| Pattern-defeating Quicksort | [arxiv.org/abs/2106.05123](https://arxiv.org/abs/2106.05123) |
| Big-O Cheat Sheet | [bigocheatsheet.com](https://www.bigocheatsheet.com/) |

---

## ⑥ RECOMMEND

| Tool / Library | Mô tả | Khi nào dùng |
|----------------|--------|---------------|
| **`sort.Slice`** | Go stdlib — pdqsort hybrid | Production general-purpose |
| **`sort.SliceStable`** | Stable version of sort.Slice | Khi cần giữ relative order |
| **`slices.Sort`** | Go 1.21+ generic sort — nhanh hơn sort.Slice | New projects, Go 1.21+ |
| **`slices.SortFunc`** | Custom comparator generic sort | Sort structs với custom logic |
| **`sort.Search`** | Binary search trong sorted slice | Tìm insertion point |
| **`container/heap`** | Priority queue — heap sort nền tảng | Top-K problems, Dijkstra |

---

**Liên kết**: [← README](./README.md) · [→ Searching](./02-searching.md)
