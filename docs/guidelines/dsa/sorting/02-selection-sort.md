# 🎯 Selection Sort

> **Phân loại**: Comparison-based, Unstable, In-place
> **Tóm tắt**: Tìm phần tử nhỏ nhất trong vùng unsorted, swap vào đầu vùng unsorted. Lặp lại cho đến khi sorted.

---

## ① DEFINE

### Thông số

| Metric | Value |
|--------|-------|
| **Best case** | O(n²) — LUÔN |
| **Average case** | O(n²) |
| **Worst case** | O(n²) |
| **Space** | O(1) — in-place |
| **Stable** | ❌ — swap jump thay đổi relative order |
| **In-place** | ✅ |
| **Adaptive** | ❌ — không tận dụng sorted data |
| **Comparisons** | O(n²) — luôn n(n-1)/2 |
| **Swaps** | O(n) — chính xác n-1 swaps (minimum!) |

### Định nghĩa

**Selection Sort** mỗi bước chọn (select) phần tử nhỏ nhất từ vùng unsorted và swap vào vị trí đúng. Vùng sorted mở rộng từ trái qua phải.

### So sánh với Bubble Sort

| | Selection Sort | Bubble Sort |
|---|---|---|
| **Swaps** | n-1 (minimum) | Lên tới n(n-1)/2 |
| **Comparisons** | n(n-1)/2 (luôn) | n(n-1)/2 (worst) |
| **Adaptive** | ❌ (luôn n²) | ✅ (best O(n)) |
| **Stable** | ❌ | ✅ |
| **Ưu điểm** | Ít write nhất | Đơn giản nhất |

### Invariants

- **Sau iteration thứ i**: `arr[0..i]` chứa `i+1` phần tử **nhỏ nhất**, đã sorted.
- **Vùng unsorted** = `arr[i+1..n-1]`.
- **Số swaps** = chính xác **n-1** — minimum possible.

### Khi nào dùng Selection Sort?

- **Write-expensive storage**: Flash memory, EEPROM — swap cost >> compare cost.
- **n rất nhỏ** (< 30).
- **Memory cực kỳ hạn chế**: chỉ O(1) extra space.
- **Không cần stable sort**.

---

## ② GRAPH

### Visualization — Full Trace

```text
  Input: [64, 25, 12, 22, 11]

  ━━━ Iteration 0: tìm min trong [0..4] ━━━
  min = 11 (index 4)
  Swap arr[0] ↔ arr[4]:  [11, 25, 12, 22, 64]
                          [sorted | unsorted  ]

  ━━━ Iteration 1: tìm min trong [1..4] ━━━
  min = 12 (index 2)
  Swap arr[1] ↔ arr[2]:  [11, 12, 25, 22, 64]
                          [sorted   | unsorted]

  ━━━ Iteration 2: tìm min trong [2..4] ━━━
  min = 22 (index 3)
  Swap arr[2] ↔ arr[3]:  [11, 12, 22, 25, 64]
                          [sorted      | uns. ]

  ━━━ Iteration 3: tìm min trong [3..4] ━━━
  min = 25 (index 3)
  No swap (minIdx == i):  [11, 12, 22, 25, 64]
                          [sorted         | 64]

  Output: [11, 12, 22, 25, 64] ✓
  Total: 4 iterations, 3 swaps (not 4 because last was no-op)
```

### Unstable Demonstration

```text
  Input: [5a, 3, 5b, 1]    (5a, 5b same value, different objects)

  Iteration 0: min=1 → swap arr[0]↔arr[3]
  [1, 3, 5b, 5a]   ← 5a and 5b swapped relative order!

  Bubble Sort: [1, 3, 5a, 5b] ← keeps 5a before 5b (stable ✅)
  Selection:   [1, 3, 5b, 5a] ← 5b before 5a (UNSTABLE ❌)
```

---

## ③ CODE

### Example 1: Basic Selection Sort

**Mục tiêu**: Implement Selection Sort cơ bản.

**Cần gì**: Go standard library.

**Có gì**: Slice integers → tìm min → swap → lặp.

```go
package sorting

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SelectionSort: tìm min → swap vào đúng vị trí
//
// Invariant: arr[0..i] sorted, chứa i+1 phần tử nhỏ nhất
// Time: O(n²) — LUÔN, bất kể input
// Space: O(1) — in-place
// Swaps: chính xác n-1 — minimum possible
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func SelectionSort(arr []int) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        minIdx := i

        // Tìm index phần tử nhỏ nhất trong arr[i+1..n-1]
        for j := i + 1; j < n; j++ {
            if arr[j] < arr[minIdx] {
                minIdx = j
            }
        }

        // Swap min vào vị trí i (skip nếu đã đúng)
        if minIdx != i {
            arr[i], arr[minIdx] = arr[minIdx], arr[i]
        }
    }
}

func main() {
    arr := []int{64, 25, 12, 22, 11}
    fmt.Println("Before:", arr)
    SelectionSort(arr)
    fmt.Println("After: ", arr)
    // After: [11 12 22 25 64]
}
```

---

### Example 2: Double Selection Sort — Tìm cả min và max

**Mục tiêu**: Tối ưu — tìm cả min và max trong mỗi iteration → giảm 50% passes.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DoubleSelectionSort: tìm cả min và max mỗi pass
//
// Mỗi iteration: đặt min vào đầu + max vào cuối
// Số passes: n/2 thay vì n-1
// Time: vẫn O(n²) — nhưng ~25% ít comparisons hơn
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func DoubleSelectionSort(arr []int) {
    n := len(arr)
    for left, right := 0, n-1; left < right; left, right = left+1, right-1 {
        minIdx, maxIdx := left, left

        // Tìm min và max trong [left..right]
        for j := left; j <= right; j++ {
            if arr[j] < arr[minIdx] {
                minIdx = j
            }
            if arr[j] > arr[maxIdx] {
                maxIdx = j
            }
        }

        // Swap min vào left
        arr[left], arr[minIdx] = arr[minIdx], arr[left]

        // ⚠ Nếu max ở left (đã bị swap), adjust index
        if maxIdx == left {
            maxIdx = minIdx
        }

        // Swap max vào right
        arr[right], arr[maxIdx] = arr[maxIdx], arr[right]
    }
}
```

**Kết quả đạt được**:

- **~50% ít passes** — tìm cả min và max mỗi iteration.
- **Edge case handled**: khi max nằm ở vị trí left (đã bị swap bởi min).

**Lưu ý**:

- **Vẫn O(n²)** — chỉ giảm constant factor.
- **Index adjustment**: khi `maxIdx == left`, max đã bị di chuyển → phải update `maxIdx = minIdx`.

---

### Example 3: Stable Selection Sort

**Mục tiêu**: Biến Selection Sort thành stable bằng cách dùng shift thay vì swap.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// StableSelectionSort: stable version — dùng shift thay swap
//
// Thay vì swap arr[i] ↔ arr[minIdx]:
//   Save arr[minIdx] → shift arr[i..minIdx-1] sang phải → insert
//
// Trade-off: O(n²) writes thay vì O(n) swaps
// Khi nào: cần stable + selection sort specific
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func StableSelectionSort(arr []int) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        minIdx := i
        for j := i + 1; j < n; j++ {
            if arr[j] < arr[minIdx] {
                minIdx = j
            }
        }

        if minIdx != i {
            // Shift thay vì swap → giữ relative order
            minVal := arr[minIdx]
            // Shift arr[i..minIdx-1] sang phải 1 vị trí
            copy(arr[i+1:minIdx+1], arr[i:minIdx])
            arr[i] = minVal
        }
    }
}
```

**Kết quả đạt được**:

- **Stable** — shift giữ relative order của equal elements.
- **Trade-off**: O(n²) writes (shift) thay vì O(n) swaps — mất ưu điểm ít write.

**Lưu ý**: Nếu cần stable sort, Insertion Sort hoặc Merge Sort tốt hơn. Variant này chỉ mang tính giáo dục.

---

### Example 4: Generic + Struct Sort — Real-world Use Case

**Mục tiêu**: Selection Sort cho structs — sort products by price (ứng dụng tìm top-K cheapest).

```go
package sorting

import "fmt"

type Product struct {
    Name  string
    Price float64
    Stock int
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SelectionSortFunc: generic selection sort with custom comparator
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func SelectionSortFunc[T any](arr []T, less func(a, b T) bool) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        minIdx := i
        for j := i + 1; j < n; j++ {
            if less(arr[j], arr[minIdx]) {
                minIdx = j
            }
        }
        if minIdx != i {
            arr[i], arr[minIdx] = arr[minIdx], arr[i]
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Partial Selection Sort: chỉ tìm K phần tử nhỏ nhất
//
// Use case: "Top 3 cheapest products" — chỉ sort K iterations
// Time: O(n × K) thay vì O(n²) — tốt khi K << n
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func PartialSelectionSort[T any](arr []T, k int, less func(a, b T) bool) {
    n := len(arr)
    if k > n {
        k = n
    }
    for i := 0; i < k; i++ {
        minIdx := i
        for j := i + 1; j < n; j++ {
            if less(arr[j], arr[minIdx]) {
                minIdx = j
            }
        }
        if minIdx != i {
            arr[i], arr[minIdx] = arr[minIdx], arr[i]
        }
    }
    // arr[0..k-1] chứa K phần tử nhỏ nhất, sorted
}

func main() {
    products := []Product{
        {"Laptop", 999.99, 50},
        {"Mouse", 29.99, 200},
        {"Keyboard", 79.99, 150},
        {"Monitor", 449.99, 30},
        {"Headset", 59.99, 100},
        {"Webcam", 49.99, 80},
    }

    // Top 3 cheapest products
    PartialSelectionSort(products, 3, func(a, b Product) bool {
        return a.Price < b.Price
    })

    fmt.Println("Top 3 cheapest:")
    for _, p := range products[:3] {
        fmt.Printf("  %s: $%.2f\n", p.Name, p.Price)
    }
    // Mouse: $29.99, Webcam: $49.99, Headset: $59.99
}
```

**Kết quả đạt được**:

- **Partial sort**: chỉ tìm K phần tử nhỏ nhất — O(nK) thay vì O(n²).
- **Real use case**: top-K problems khi K rất nhỏ.
- **Generic**: sort bất kỳ struct.

**Lưu ý**:

- **K << n**: Partial Selection tốt hơn full sort (ví dụ: top-3 từ 1M items).
- **K lớn**: dùng `container/heap` — O(n log K) tốt hơn O(nK).
- Production: `container/heap` cho top-K — KHÔNG dùng partial selection sort.

---

## ④ PITFALLS

| # | Lỗi | Nguyên nhân | Fix |
|---|------|-------------|-----|
| 1 | Dùng cho large dataset | Luôn O(n²), không adaptive | Dùng stdlib sort |
| 2 | Assume stable | Swap jump → unstable | Dùng Insertion/Merge nếu cần stable |
| 3 | Double Selection index bug | Max ở vị trí left đã bị swap | Adjust `maxIdx` sau swap min |
| 4 | Dùng cho top-K khi K lớn | O(nK) → O(n²) | Dùng `container/heap` — O(n log K) |
| 5 | Expect O(n) best case | Selection luôn O(n²) | Dùng Insertion Sort nếu cần adaptive |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| Visualgo — Selection Sort | [visualgo.net/sorting](https://visualgo.net/en/sorting) |
| Wikipedia — Selection sort | [en.wikipedia.org](https://en.wikipedia.org/wiki/Selection_sort) |
| Go `container/heap` | [pkg.go.dev/container/heap](https://pkg.go.dev/container/heap) |

---

## ⑥ RECOMMEND

| Thay thế | Khi nào | Lý do |
|----------|---------|-------|
| **Insertion Sort** | Nearly sorted, cần stable | O(n) best, stable, ít overhead |
| **Heap Sort** | Cần O(n log n) in-place | O(n log n) guaranteed, O(1) space |
| **`container/heap`** | Top-K problems | O(n log K) — production-grade |
| **`sort.Slice`** | Production code | Always use stdlib |

---

**Liên kết**: [← Bubble Sort](./01-bubble-sort.md) · [→ Insertion Sort](./03-insertion-sort.md) · [← README](./README.md)
