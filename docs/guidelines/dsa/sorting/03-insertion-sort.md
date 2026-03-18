# 🃏 Insertion Sort

> **Phân loại**: Comparison-based, Stable, In-place, Adaptive, Online
> **Tóm tắt**: Chèn phần tử vào đúng vị trí trong vùng sorted — giống xếp bài trên tay.

---

## ① DEFINE

### Thông số

| Metric | Value |
|--------|-------|
| **Best case** | O(n) — đã sorted |
| **Average case** | O(n²) |
| **Worst case** | O(n²) — reverse sorted |
| **Space** | O(1) — in-place |
| **Stable** | ✅ — shift, không swap qua equal |
| **In-place** | ✅ |
| **Adaptive** | ✅ — O(n + d), d = inversions |
| **Online** | ✅ — sort khi nhận data |

### Định nghĩa

**Insertion Sort** duyệt từ trái qua phải, mỗi phần tử được "chèn" vào đúng vị trí trong vùng đã sorted bên trái. Giống cách ta xếp bài trên tay: rút từng quân, chèn vào đúng vị trí.

### Tại sao Insertion Sort quan trọng?

- **Go stdlib `sort.Slice`** dùng Insertion Sort cho partitions < 12 (bên trong pdqsort).
- **Java Arrays.sort** dùng Insertion Sort cho n < 47.
- **Python Timsort** dùng Insertion Sort cho small runs.
- → Nó là **building block** của mọi production sorting algorithm.

### Invariants

- `arr[0..i-1]` luôn sorted tại mỗi bước `i`.
- Phần tử `arr[i]` được chèn vào vị trí đúng bằng shift (không phải swap).
- Số shifts = số inversions của array.

---

## ② GRAPH

### Visualization — Card Dealing Analogy

```text
  Hand (sorted) | Deck (unsorted)

  Step 0: []                 | [5, 3, 8, 1, 2]
  Step 1: [5]                | [3, 8, 1, 2]      ← rút 5
  Step 2: [3, 5]             | [8, 1, 2]          ← chèn 3 trước 5
  Step 3: [3, 5, 8]          | [1, 2]              ← 8 ở cuối
  Step 4: [1, 3, 5, 8]       | [2]                 ← shift 3,5,8 → chèn 1
  Step 5: [1, 2, 3, 5, 8]    | []                  ← shift 3,5,8 → chèn 2

  Done! ✓
```

### Detail — Step 4: Inserting 1

```text
  arr = [3, 5, 8, |1, 2]     key = 1
         sorted   |unsorted

  j=2: 8 > 1 → shift right  [3, 5, _, 8, 2]
  j=1: 5 > 1 → shift right  [3, _, 5, 8, 2]
  j=0: 3 > 1 → shift right  [_, 3, 5, 8, 2]
  j=-1: stop → insert 1     [1, 3, 5, 8, 2]
                              ↑ inserted
```

### Inversions & Performance

```text
  Already sorted: [1, 2, 3, 4, 5]    Inversions: 0     → O(n)
  Nearly sorted:  [1, 2, 4, 3, 5]    Inversions: 1     → O(n)
  Random:         [3, 1, 4, 5, 2]    Inversions: 4     → O(n + 4)
  Reverse sorted: [5, 4, 3, 2, 1]    Inversions: 10    → O(n + 10) = O(n²)

  Time = O(n + inversions) → adaptive!
```

---

## ③ CODE

### Example 1: Basic Insertion Sort

**Mục tiêu**: Insertion Sort cơ bản — shift elements.

**Cần gì**: Go standard library.

**Có gì**: Array → iterate → shift → insert.

```go
package sorting

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// InsertionSort: chèn phần tử vào vùng sorted
//
// Khác Bubble Sort: SHIFT thay vì SWAP
//   Shift: di chuyển 1 chiều, ít writes hơn swap (= 2 writes)
//   → ~2x nhanh hơn Bubble Sort trên random data
//
// Time: O(n + d) — d = number of inversions
// Space: O(1) — in-place
// Stable: ✅ — shift KHÔNG qua equal elements
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func InsertionSort(arr []int) {
    for i := 1; i < len(arr); i++ {
        key := arr[i] // phần tử cần chèn
        j := i - 1

        // Shift phần tử lớn hơn key sang phải
        for j >= 0 && arr[j] > key {
            arr[j+1] = arr[j] // shift right (1 write, not swap = 2 writes)
            j--
        }

        arr[j+1] = key // chèn key vào đúng vị trí
    }
}

func main() {
    arr := []int{12, 11, 13, 5, 6}
    InsertionSort(arr)
    fmt.Println(arr) // [5 6 11 12 13]
}
```

---

### Example 2: Binary Insertion Sort — O(n log n) comparisons

**Mục tiêu**: Dùng Binary Search tìm vị trí chèn → giảm comparisons.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BinaryInsertionSort: binary search cho insertion point
//
// Comparisons: O(n log n) — binary search per element
// Shifts: O(n²) — vẫn cần shift elements
// Total: O(n²) — shifts dominate
//
// Khi nào tốt hơn?
// - Compare operation đắt (ví dụ: so sánh strings dài)
// - Array gần sorted (ít shifts)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BinaryInsertionSort(arr []int) {
    for i := 1; i < len(arr); i++ {
        key := arr[i]

        // Binary search cho vị trí chèn
        lo, hi := 0, i
        for lo < hi {
            mid := lo + (hi-lo)/2
            if arr[mid] > key {
                hi = mid
            } else {
                lo = mid + 1 // ← lo = mid + 1 → stable (chèn SAU equal)
            }
        }

        // Shift arr[lo..i-1] sang phải
        copy(arr[lo+1:i+1], arr[lo:i])
        arr[lo] = key
    }
}
```

**Kết quả đạt được**:

- **O(n log n) comparisons** — mỗi element dùng O(log n) binary search.
- **Vẫn stable**: `lo = mid + 1` khi equal → chèn SAU phần tử bằng.

**Lưu ý**: Total vẫn O(n²) vì shifts — chỉ tốt hơn khi compare đắt hơn shift.

---

### Example 3: Insertion Sort cho Linked List — O(1) insert

**Mục tiêu**: Trên linked list, insert = O(1) → tổng O(n²) comparisons + O(1) inserts. Không cần shift!

```go
package sorting

import "fmt"

type ListNode struct {
    Val  int
    Next *ListNode
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// InsertionSortList: Insertion Sort cho Linked List
//
// Ưu điểm vs array version:
// - Insert = O(1) — chỉ pointer manipulation, KHÔNG cần shift
// - Total: O(n²) comparisons + O(n) pointer ops
//
// Đây là lý do Insertion Sort "sinh ra" cho linked list
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func InsertionSortList(head *ListNode) *ListNode {
    if head == nil || head.Next == nil {
        return head
    }

    dummy := &ListNode{Val: -1 << 31} // sentinel node
    current := head

    for current != nil {
        next := current.Next // save next before modifying

        // Tìm vị trí chèn trong sorted list
        prev := dummy
        for prev.Next != nil && prev.Next.Val < current.Val {
            prev = prev.Next
        }

        // Insert current sau prev
        current.Next = prev.Next
        prev.Next = current

        current = next
    }

    return dummy.Next
}

func printList(head *ListNode) {
    for head != nil {
        fmt.Printf("%d → ", head.Val)
        head = head.Next
    }
    fmt.Println("nil")
}

func main() {
    // 4 → 2 → 1 → 3
    head := &ListNode{4, &ListNode{2, &ListNode{1, &ListNode{3, nil}}}}
    printList(head) // 4 → 2 → 1 → 3 → nil

    sorted := InsertionSortList(head)
    printList(sorted) // 1 → 2 → 3 → 4 → nil
}
```

**Kết quả đạt được**:

- **O(1) insert** — pointer manipulation, no shifts.
- **Linked list**: Insertion Sort = natural fit.

**Lưu ý**: Array shift = O(n) per insert. Linked list insert = O(1). Nhưng linked list poor cache locality.

---

### Example 4: Online Insertion Sort — Streaming Data

**Mục tiêu**: Minh họa "online" property — sort data khi nhận từng phần tử (streaming). Không cần biết toàn bộ array trước.

```go
package sorting

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SortedBuffer: online insertion sort — maintain sorted order
//
// Online algorithm: xử lý data từng phần tử
// Mỗi Insert: O(n) shift → tổng O(n²) cho n inserts
//
// Use case: maintain sorted leaderboard, rolling median
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type SortedBuffer struct {
    data []int
}

func NewSortedBuffer() *SortedBuffer {
    return &SortedBuffer{}
}

// Insert: chèn vào đúng vị trí sorted
func (sb *SortedBuffer) Insert(val int) {
    // Binary search cho insertion point
    lo, hi := 0, len(sb.data)
    for lo < hi {
        mid := lo + (hi-lo)/2
        if sb.data[mid] < val {
            lo = mid + 1
        } else {
            hi = mid
        }
    }

    // Insert at position lo
    sb.data = append(sb.data, 0)           // grow
    copy(sb.data[lo+1:], sb.data[lo:])     // shift right
    sb.data[lo] = val                       // insert
}

func (sb *SortedBuffer) GetSorted() []int {
    return sb.data
}

func (sb *SortedBuffer) Median() float64 {
    n := len(sb.data)
    if n == 0 {
        return 0
    }
    if n%2 == 0 {
        return float64(sb.data[n/2-1]+sb.data[n/2]) / 2.0
    }
    return float64(sb.data[n/2])
}

func main() {
    buf := NewSortedBuffer()

    // Streaming scores
    scores := []int{85, 92, 78, 95, 88, 72, 91}
    for _, score := range scores {
        buf.Insert(score)
        fmt.Printf("Insert %d → sorted: %v, median: %.1f\n",
            score, buf.GetSorted(), buf.Median())
    }
    // Insert 85 → sorted: [85], median: 85.0
    // Insert 92 → sorted: [85 92], median: 88.5
    // Insert 78 → sorted: [78 85 92], median: 85.0
    // ...
}
```

**Kết quả đạt được**:

- **Online** — luôn maintain sorted state khi nhận data mới.
- **Running median** — instant O(1) access.
- **Streaming applications**: leaderboard, real-time analytics.

**Lưu ý**: n lớn → dùng `container/heap` hoặc balanced BST cho O(log n) insert.

---

### Example 5: Shell Sort — Insertion Sort với Gap Sequence

**Mục tiêu**: Shell Sort — generalized Insertion Sort, sort elements cách nhau gap positions. Giảm inversions trước → Insertion Sort final pass nhanh hơn.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ShellSort: Insertion Sort với diminishing gap sequence
//
// Key insight: Insertion Sort rất nhanh trên nearly sorted data
// → pre-sort bằng larger gaps → final Insertion Sort = fast
//
// Gap sequences:
//   Shell original: n/2, n/4, ..., 1  → O(n²) worst
//   Knuth:          1, 4, 13, 40, ... (3h+1) → O(n^1.5)
//   Hibbard:        1, 3, 7, 15, 31, ... (2^k - 1) → O(n^1.5)
//   Sedgewick:      complex formula → O(n^(4/3))
//
// Time: O(n^1.25) ~ O(n^1.5) — depends on gap sequence
// Space: O(1) — in-place
// Stable: ❌ — gap-based swaps thay đổi relative order
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func ShellSort(arr []int) {
    n := len(arr)

    // Gap sequence: Knuth's (1, 4, 13, 40, 121, ...)
    gap := 1
    for gap < n/3 {
        gap = gap*3 + 1 // 1, 4, 13, 40, 121, ...
    }

    for gap > 0 {
        // Insertion Sort với step = gap
        for i := gap; i < n; i++ {
            key := arr[i]
            j := i

            // Shift elements gap positions apart
            for j >= gap && arr[j-gap] > key {
                arr[j] = arr[j-gap]
                j -= gap
            }
            arr[j] = key
        }

        gap /= 3 // shrink gap
    }
}
```

**Kết quả đạt được**:

- **O(n^1.5)** với Knuth gap — much better than O(n²).
- **In-place** — O(1) space.
- **Pre-sorting** — larger gaps reduce inversions → final pass fast.

**Lưu ý**:

- **Shell Sort vs stdlib**: Shell Sort vẫn chậm hơn Quick Sort — chỉ dùng cho embedded systems.
- **Gap sequence matters**: tốt = O(n^1.25), tệ = O(n²).
- **Not stable**: gap-based operations thay đổi relative order.
- Go stdlib **KHÔNG** dùng Shell Sort (dùng pdqsort).

---

### Example 6: Combo — Hybrid Insertion Sort trong stdlib-like algorithm

**Mục tiêu**: Minh họa cách Insertion Sort được dùng bên trong hybrid algorithms (giống Go stdlib).

```go
package sorting

import (
    "fmt"
    "math/rand"
    "sort"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HybridInsertionSort: kết hợp Quick Sort + Insertion Sort
//
// Giống cách Go stdlib sort.Slice hoạt động:
// 1. Quick Sort cho partitions lớn
// 2. Khi partition < threshold → Insertion Sort
//
// Tại sao Insertion Sort cho small partitions?
// - Quick Sort overhead: pivot selection, partition, recursion
// - Insertion Sort: ít overhead, cache-friendly, O(n) cho small n
// - Threshold ~12-16: sweet spot performance
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const threshold = 16

func HybridSort(arr []int) {
    hybridSortHelper(arr, 0, len(arr)-1)
}

func hybridSortHelper(arr []int, lo, hi int) {
    if hi-lo+1 <= threshold {
        // ━━━ Small partition → Insertion Sort ━━━
        insertionSortRange(arr, lo, hi)
        return
    }

    // ━━━ Quick Sort partition ━━━
    pivot := arr[lo+(hi-lo)/2]
    i, j := lo, hi
    for i <= j {
        for arr[i] < pivot { i++ }
        for arr[j] > pivot { j-- }
        if i <= j {
            arr[i], arr[j] = arr[j], arr[i]
            i++
            j--
        }
    }

    if lo < j { hybridSortHelper(arr, lo, j) }
    if i < hi { hybridSortHelper(arr, i, hi) }
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

func main() {
    n := 100_000
    data := make([]int, n)
    for i := range data {
        data[i] = rand.Intn(n)
    }

    // Hybrid sort
    arr1 := make([]int, n)
    copy(arr1, data)
    start := time.Now()
    HybridSort(arr1)
    hybrid := time.Since(start)

    // Pure Insertion Sort
    arr2 := make([]int, n)
    copy(arr2, data)
    start = time.Now()
    InsertionSort(arr2)
    pure := time.Since(start)

    // stdlib
    arr3 := make([]int, n)
    copy(arr3, data)
    start = time.Now()
    sort.Ints(arr3)
    stdlib := time.Since(start)

    fmt.Printf("n=%d:\n", n)
    fmt.Printf("  Pure Insertion: %v\n", pure)
    fmt.Printf("  Hybrid:         %v\n", hybrid)
    fmt.Printf("  stdlib:         %v\n", stdlib)
    fmt.Printf("  Hybrid/stdlib:  %.1fx\n", float64(hybrid)/float64(stdlib))
    // Pure Insertion: ~5s
    // Hybrid:         ~15ms
    // stdlib:         ~12ms
    // → Hybrid gần bằng stdlib, 300x nhanh hơn pure Insertion
}
```

**Kết quả đạt được**:

- **Hybrid = Quick Sort + Insertion Sort** — gần bằng stdlib performance.
- **Insertion Sort chỉ cho small partitions** → low overhead, cache-friendly.
- **300x nhanh hơn** pure Insertion Sort cho n=100K.

**Lưu ý**: Go stdlib `sort.Slice` dùng pdqsort = Quick Sort + Insertion Sort + Heap Sort fallback.

---

## ④ PITFALLS

| # | Lỗi | Nguyên nhân | Fix |
|---|------|-------------|-----|
| 1 | Dùng cho large unsorted array | O(n²) quá chậm | Dùng stdlib sort |
| 2 | Dùng swap thay shift | 2× writes, chậm hơn | Shift 1 chiều |
| 3 | Quên `j >= 0` check | Index out of bounds | Guard condition |
| 4 | Binary Insertion Sort assume O(n log n) | Shifts vẫn O(n²) | Only reduces comparisons |
| 5 | Shell Sort assume stable | Gap-based = unstable | Dùng Merge Sort nếu cần stable |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| Visualgo — Insertion Sort | [visualgo.net/sorting](https://visualgo.net/en/sorting) |
| Wikipedia — Insertion sort | [en.wikipedia.org](https://en.wikipedia.org/wiki/Insertion_sort) |
| Shell Sort — gap sequences | [en.wikipedia.org](https://en.wikipedia.org/wiki/Shellsort#Gap_sequences) |
| Timsort (uses Insertion Sort) | [en.wikipedia.org](https://en.wikipedia.org/wiki/Timsort) |

---

## ⑥ RECOMMEND

| Thay thế / Extension | Khi nào | Lý do |
|----------------------|---------|-------|
| **Shell Sort** | Embedded, no recursion | O(n^1.5), in-place |
| **Timsort** | Python/Java default | Merge Sort + Insertion Sort hybrid |
| **`sort.Slice`** | Production Go | pdqsort = Quick + Insertion + Heap |
| **`container/heap`** | Streaming data, large n | O(log n) insert |

---

**Liên kết**: [← Selection Sort](./02-selection-sort.md) · [→ Merge Sort](./04-merge-sort.md) · [← README](./README.md)
