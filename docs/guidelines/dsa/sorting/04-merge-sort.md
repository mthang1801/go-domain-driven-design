# 🔀 Merge Sort

> **Phân loại**: Comparison-based, Stable, NOT In-place, Divide & Conquer
> **Tóm tắt**: Chia đôi → sort từng nửa → merge hai nửa sorted. Guaranteed O(n log n).

---

## ① DEFINE

### Thông số

| Metric | Value |
|--------|-------|
| **Best case** | O(n log n) |
| **Average case** | O(n log n) |
| **Worst case** | O(n log n) — GUARANTEED |
| **Space** | O(n) — auxiliary array |
| **Stable** | ✅ — merge giữ relative order |
| **In-place** | ❌ — cần O(n) extra space |
| **Adaptive** | ❌ (standard), ✅ (natural merge sort) |
| **Parallelizable** | ✅ — divide & conquer → goroutines |

### Định nghĩa

**Merge Sort** là thuật toán Divide & Conquer:
1. **Divide**: chia array thành 2 nửa.
2. **Conquer**: recursion sort mỗi nửa.
3. **Combine**: merge 2 nửa đã sorted thành 1 array sorted.

### Tại sao Merge Sort quan trọng?

- **Guaranteed O(n log n)** — NEVER O(n²), bất kể input data.
- **Stable** — giữ relative order → quan trọng cho multi-key sorting.
- **External sorting**: nền tảng cho sort files lớn hơn RAM (disk-based merge).
- **Parallelizable**: divide & conquer → natural fit cho goroutines.
- **Timsort** (Python/Java default) = optimized Merge Sort + Insertion Sort.

### Invariants

- Mỗi level recursion: tổng work = O(n).
- Số levels = log₂(n).
- Merge: 2 sorted arrays → 1 sorted array, stable (chọn left khi equal).

---

## ② GRAPH

### Divide & Conquer — Recursion Tree

```text
  Level 0:         [38, 27, 43, 3, 9, 82, 10]          work = n
                  /                           \
  Level 1:   [38, 27, 43, 3]           [9, 82, 10]     work = n
             /            \             /          \
  Level 2: [38, 27]    [43, 3]      [9, 82]      [10]  work = n
           /    \       /    \       /    \          |
  Level 3: [38] [27]  [43]  [3]   [9]  [82]      [10]  work = n

  ← MERGE PHASE (bottom up) →

  Level 3: [38] [27]  [43]  [3]   [9]  [82]      [10]
           \    /       \    /       \    /          |
  Level 2: [27, 38]    [3, 43]    [9, 82]        [10]
             \            /             \          /
  Level 1:   [3, 27, 38, 43]         [9, 10, 82]
                  \                       /
  Level 0:    [3, 9, 10, 27, 38, 43, 82]  ← sorted ✓

  Work per level: O(n)  ×  log₂(n) levels  =  O(n log n)
```

### Merge — 2 Sorted Arrays → 1

```text
  Left:  [3, 27, 38]       Right: [9, 10, 43]
          ↑ i=0                     ↑ j=0
  Result: []

  Step 1: 3 < 9  → take 3   Result: [3]           i=1
  Step 2: 27 > 9 → take 9   Result: [3, 9]        j=1
  Step 3: 27 > 10→ take 10  Result: [3, 9, 10]    j=2
  Step 4: 27 < 43→ take 27  Result: [3, 9, 10, 27] i=2
  Step 5: 38 < 43→ take 38  Result: [3, 9, 10, 27, 38] i=3
  Step 6: append 43          Result: [3, 9, 10, 27, 38, 43] ✓
```

---

## ③ CODE

### Example 1: Standard Merge Sort — Recursive

**Mục tiêu**: Merge Sort chuẩn — recursive divide & conquer.

**Cần gì**: Go standard library.

**Có gì**: Array → split → recurse → merge.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MergeSort: Divide & Conquer — guaranteed O(n log n)
//
// 1. Divide: split tại midpoint
// 2. Conquer: recursion sort mỗi nửa
// 3. Combine: merge 2 sorted halves
//
// Time: O(n log n) — ALWAYS
// Space: O(n) — auxiliary arrays for merge
// Stable: ✅ — merge left[i] <= right[j] → take left
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func MergeSort(arr []int) []int {
    n := len(arr)
    if n <= 1 {
        return arr
    }

    mid := n / 2
    left := MergeSort(arr[:mid])   // sort nửa trái
    right := MergeSort(arr[mid:])  // sort nửa phải
    return merge(left, right)
}

// merge: merge 2 sorted slices → 1 sorted slice
func merge(left, right []int) []int {
    result := make([]int, 0, len(left)+len(right))
    i, j := 0, 0

    for i < len(left) && j < len(right) {
        if left[i] <= right[j] {
            result = append(result, left[i])
            i++
        } else {
            result = append(result, right[j])
            j++
        }
    }

    result = append(result, left[i:]...)
    result = append(result, right[j:]...)
    return result
}
```

---

### Example 2: In-place Merge Sort — O(1) extra space

**Mục tiêu**: Merge Sort không cần O(n) extra space — dùng rotation-based merge.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MergeSortInPlace: pseudo in-place merge sort
//
// Trade-off: O(1) space nhưng O(n² log n) time
// Dùng khi memory CỰC KỲ hạn chế
//
// Production: KHÔNG dùng — chậm hơn standard Merge Sort
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func MergeSortInPlace(arr []int, lo, hi int) {
    if hi-lo <= 0 {
        return
    }
    mid := lo + (hi-lo)/2
    MergeSortInPlace(arr, lo, mid)
    MergeSortInPlace(arr, mid+1, hi)
    mergeInPlace(arr, lo, mid, hi)
}

func mergeInPlace(arr []int, lo, mid, hi int) {
    i, j := lo, mid+1
    for i <= mid && j <= hi {
        if arr[i] <= arr[j] {
            i++
        } else {
            // Shift arr[i..j-1] right, insert arr[j] at i
            val := arr[j]
            copy(arr[i+1:j+1], arr[i:j])
            arr[i] = val
            i++
            mid++
            j++
        }
    }
}
```

**Lưu ý**: O(n² log n) — CHẬM hơn standard. Chỉ dùng khi O(n) memory không khả dụng.

---

### Example 3: Bottom-up Merge Sort — Iterative

**Mục tiêu**: Merge Sort iterative — không recursion, tránh stack overflow cho large arrays.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MergeSortBottomUp: iterative merge sort
//
// Thay vì recursion top-down: bắt đầu từ pairs → merge lên
// Size = 1: merge pairs → sorted pairs
// Size = 2: merge 4 elements → sorted quads
// Size = 4: merge 8 elements → ...
// Cho đến size >= n
//
// ✅ No recursion → no stack overflow
// ✅ Tốt cho external sorting (disk-based merge)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func MergeSortBottomUp(arr []int) []int {
    n := len(arr)
    if n <= 1 {
        return arr
    }

    // Auxiliary buffer
    src := make([]int, n)
    copy(src, arr)
    dst := make([]int, n)

    for size := 1; size < n; size *= 2 {
        for lo := 0; lo < n; lo += 2 * size {
            mid := lo + size
            if mid > n {
                mid = n
            }
            hi := lo + 2*size
            if hi > n {
                hi = n
            }
            mergeRange(src, dst, lo, mid, hi)
        }
        // Swap src and dst
        src, dst = dst, src
    }

    copy(arr, src)
    return arr
}

func mergeRange(src, dst []int, lo, mid, hi int) {
    i, j, k := lo, mid, lo
    for i < mid && j < hi {
        if src[i] <= src[j] {
            dst[k] = src[i]
            i++
        } else {
            dst[k] = src[j]
            j++
        }
        k++
    }
    for i < mid {
        dst[k] = src[i]
        i++
        k++
    }
    for j < hi {
        dst[k] = src[j]
        j++
        k++
    }
}
```

**Kết quả đạt được**:

- **No recursion** → no stack overflow → safe cho n = 100M+.
- **External sorting friendly**: merge pairs from disk files.
- **Same O(n log n)** time, O(n) space.

---

### Example 4: Natural Merge Sort — Adaptive

**Mục tiêu**: Tận dụng existing sorted runs → O(n) cho already sorted input. Đây là nền tảng của Timsort.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NaturalMergeSort: tìm natural runs → merge
//
// Run = maximal sorted subsequence
// Already sorted: 1 run → O(n) ✅
// Reverse sorted: n runs → O(n log n) — same as standard
//
// Timsort = Natural Merge Sort + Insertion Sort cho small runs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func NaturalMergeSort(arr []int) {
    n := len(arr)
    if n <= 1 {
        return
    }

    aux := make([]int, n)

    for {
        // Find and merge pairs of natural runs
        merged := false
        i := 0

        for i < n {
            // Find first run
            runStart1 := i
            for i < n-1 && arr[i] <= arr[i+1] {
                i++
            }
            i++ // end of first run
            runEnd1 := i

            if runEnd1 >= n {
                break // only one run left → sorted
            }

            // Find second run
            runStart2 := i
            for i < n-1 && arr[i] <= arr[i+1] {
                i++
            }
            i++
            runEnd2 := i
            if runEnd2 > n {
                runEnd2 = n
            }

            // Merge two adjacent runs
            mergeRuns(arr, aux, runStart1, runEnd1, runEnd2)
            merged = true
        }

        if !merged {
            break // no merges needed → sorted
        }
    }
}

func mergeRuns(arr, aux []int, lo, mid, hi int) {
    copy(aux[lo:hi], arr[lo:hi])
    i, j, k := lo, mid, lo
    for i < mid && j < hi {
        if aux[i] <= aux[j] {
            arr[k] = aux[i]
            i++
        } else {
            arr[k] = aux[j]
            j++
        }
        k++
    }
    for i < mid {
        arr[k] = aux[i]
        i++
        k++
    }
}
```

**Kết quả đạt được**:

- **Adaptive** — O(n) cho already sorted, O(n log n) worst case.
- **Natural runs** — tận dụng existing order trong data.
- **Timsort foundation** — Python/Java default sort = optimized Natural Merge Sort.

---

### Example 5: Concurrent Merge Sort — Goroutines

**Mục tiêu**: Parallel merge sort dùng goroutines — tận dụng multi-core CPU.

```go
package sorting

import "sync"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MergeSortConcurrent: parallel sort cho large arrays
//
// Strategy:
// - n >= threshold: spawn 2 goroutines cho left/right
// - n < threshold: sequential Merge Sort (avoid goroutine overhead)
//
// Threshold = 2048: goroutine overhead ~1µs, sort 2048 ints ~50µs
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const concurrentThreshold = 2048

func MergeSortConcurrent(arr []int) []int {
    if len(arr) <= 1 {
        return arr
    }

    if len(arr) < concurrentThreshold {
        return MergeSort(arr) // sequential fallback
    }

    mid := len(arr) / 2
    var left, right []int
    var wg sync.WaitGroup

    wg.Add(2)
    go func() {
        defer wg.Done()
        left = MergeSortConcurrent(arr[:mid])
    }()
    go func() {
        defer wg.Done()
        right = MergeSortConcurrent(arr[mid:])
    }()
    wg.Wait()

    return merge(left, right)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MergeSortSemaphore: controlled concurrency — tránh goroutine explosion
//
// Limit goroutines bằng semaphore channel
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func MergeSortSemaphore(arr []int, sem chan struct{}) []int {
    if len(arr) <= 1 {
        return arr
    }

    mid := len(arr) / 2

    select {
    case sem <- struct{}{}: // acquire semaphore
        var left []int
        var wg sync.WaitGroup
        wg.Add(1)
        go func() {
            defer wg.Done()
            defer func() { <-sem }() // release
            left = MergeSortSemaphore(arr[:mid], sem)
        }()
        right := MergeSortSemaphore(arr[mid:], sem)
        wg.Wait()
        return merge(left, right)
    default:
        // No slot available → sequential
        return MergeSort(arr)
    }
}
```

**Kết quả đạt được**:

- **Concurrent** — 2x-4x speedup trên multi-core cho n > 100K.
- **Threshold** — avoid goroutine overhead cho small arrays.
- **Semaphore version** — controlled concurrency, prevent goroutine explosion.

**Lưu ý**: Kết hợp goroutines chi tiết → xem [goroutines/](../../goroutines/).

---

### Example 6: External Merge Sort — Sorting files lớn hơn RAM

**Mục tiêu**: Sort file 10GB với chỉ 1GB RAM — chia file thành chunks, sort trong memory, merge files.

```go
package sorting

import (
    "bufio"
    "container/heap"
    "fmt"
    "os"
    "sort"
    "strconv"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ExternalMergeSort — Sort data lớn hơn RAM
//
// Phase 1: Split
//   Đọc chunks data vừa RAM → sort in-memory → write sorted chunk
//
// Phase 2: Merge
//   K-way merge: dùng min-heap merge K sorted chunks → output
//
// Used by: databases, Hadoop MapReduce, Unix `sort` command
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

type ChunkReader struct {
    scanner *bufio.Scanner
    current int
    done    bool
    index   int // chunk identifier
}

func (cr *ChunkReader) Next() bool {
    if cr.scanner.Scan() {
        val, _ := strconv.Atoi(cr.scanner.Text())
        cr.current = val
        return true
    }
    cr.done = true
    return false
}

// Min-heap cho K-way merge
type MergeHeap []*ChunkReader

func (h MergeHeap) Len() int            { return len(h) }
func (h MergeHeap) Less(i, j int) bool  { return h[i].current < h[j].current }
func (h MergeHeap) Swap(i, j int)       { h[i], h[j] = h[j], h[i] }
func (h *MergeHeap) Push(x interface{}) { *h = append(*h, x.(*ChunkReader)) }
func (h *MergeHeap) Pop() interface{} {
    old := *h
    n := len(old)
    item := old[n-1]
    *h = old[:n-1]
    return item
}

// Phase 1: Split large file into sorted chunks
func splitAndSort(inputFile string, chunkSize int) ([]string, error) {
    file, err := os.Open(inputFile)
    if err != nil {
        return nil, err
    }
    defer file.Close()

    scanner := bufio.NewScanner(file)
    var chunkFiles []string
    chunkIdx := 0

    for {
        // Read chunk into memory
        chunk := make([]int, 0, chunkSize)
        for i := 0; i < chunkSize && scanner.Scan(); i++ {
            val, _ := strconv.Atoi(scanner.Text())
            chunk = append(chunk, val)
        }

        if len(chunk) == 0 {
            break
        }

        // Sort in-memory
        sort.Ints(chunk)

        // Write sorted chunk to temp file
        chunkFile := fmt.Sprintf("/tmp/chunk_%d.txt", chunkIdx)
        f, _ := os.Create(chunkFile)
        w := bufio.NewWriter(f)
        for _, v := range chunk {
            fmt.Fprintln(w, v)
        }
        w.Flush()
        f.Close()

        chunkFiles = append(chunkFiles, chunkFile)
        chunkIdx++
    }

    return chunkFiles, nil
}

// Phase 2: K-way merge sorted chunks
func kWayMerge(chunkFiles []string, outputFile string) error {
    h := &MergeHeap{}
    heap.Init(h)

    // Open all chunk files
    for i, cf := range chunkFiles {
        f, _ := os.Open(cf)
        reader := &ChunkReader{
            scanner: bufio.NewScanner(f),
            index:   i,
        }
        if reader.Next() {
            heap.Push(h, reader)
        }
    }

    // Merge
    outFile, _ := os.Create(outputFile)
    w := bufio.NewWriter(outFile)
    defer func() {
        w.Flush()
        outFile.Close()
    }()

    for h.Len() > 0 {
        smallest := heap.Pop(h).(*ChunkReader)
        fmt.Fprintln(w, smallest.current)

        if smallest.Next() {
            heap.Push(h, smallest)
        }
    }

    // Cleanup temp files
    for _, cf := range chunkFiles {
        os.Remove(cf)
    }

    return nil
}
```

**Kết quả đạt được**:

- **External sorting** — sort 10GB file với 1GB RAM.
- **K-way merge** — min-heap cho efficient merging.
- **Production pattern**: databases, Hadoop, Unix `sort`.

---

## ④ PITFALLS

| # | Lỗi | Nguyên nhân | Fix |
|---|------|-------------|-----|
| 1 | Memory OOM cho large arrays | O(n) extra space | Bottom-up + streaming merge |
| 2 | Goroutine explosion | Unlimited concurrency | Threshold + semaphore |
| 3 | Unstable merge | `left[i] < right[j]` thay `<=` | Dùng `<=` cho stable |
| 4 | Stack overflow recursive | n > 100M | Bottom-up iterative |
| 5 | External sort temp files not cleaned | Crash mid-process | defer cleanup |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| Visualgo — Merge Sort | [visualgo.net/sorting](https://visualgo.net/en/sorting) |
| Timsort | [en.wikipedia.org](https://en.wikipedia.org/wiki/Timsort) |
| External Sorting | [en.wikipedia.org](https://en.wikipedia.org/wiki/External_sorting) |
| Go `container/heap` | [pkg.go.dev/container/heap](https://pkg.go.dev/container/heap) |

---

## ⑥ RECOMMEND

| Extension | Khi nào | Lý do |
|-----------|---------|-------|
| **Natural Merge Sort** | Data có existing order | Adaptive, O(n) best |
| **Timsort** | Python/Java style | Natural Merge + Insertion, production-grade |
| **External Merge Sort** | Data > RAM | K-way merge, disk-based |
| **Concurrent Merge Sort** | Multi-core CPU, n > 100K | 2-4x speedup |
| **`sort.SliceStable`** | Production Go, need stable | Merge Sort variant |

---

**Liên kết**: [← Insertion Sort](./03-insertion-sort.md) · [→ Quick Sort](./05-quick-sort.md) · [← README](./README.md)
