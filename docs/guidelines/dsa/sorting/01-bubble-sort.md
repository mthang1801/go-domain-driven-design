# 🫧 Bubble Sort

> **Phân loại**: Comparison-based, Stable, In-place
> **Tóm tắt**: So sánh cặp phần tử liền kề, swap nếu sai thứ tự. Phần tử lớn nhất "nổi" lên cuối sau mỗi pass.

---

## ① DEFINE

### Thông số

| Metric | Value |
|--------|-------|
| **Best case** | O(n) — đã sorted + early termination |
| **Average case** | O(n²) |
| **Worst case** | O(n²) — reverse sorted |
| **Space** | O(1) — in-place |
| **Stable** | ✅ — không swap phần tử bằng nhau |
| **In-place** | ✅ — chỉ dùng biến swap |
| **Adaptive** | ✅ (với optimized flag) |
| **Comparisons** | O(n²) — n(n-1)/2 worst case |
| **Swaps** | O(n²) — n(n-1)/2 worst case |

### Định nghĩa

**Bubble Sort** là thuật toán sắp xếp đơn giản nhất: duyệt qua array nhiều lần, mỗi lần so sánh 2 phần tử liền kề và swap nếu sai thứ tự. Phần tử lớn nhất sẽ "nổi" (bubble) lên cuối array sau mỗi pass, giống bọt khí nổi lên mặt nước.

### Actors & Components

- **Array**: input cần sort.
- **Pass (lượt duyệt)**: mỗi pass duyệt từ đầu đến cuối vùng unsorted.
- **Swap**: đổi chỗ 2 phần tử liền kề.
- **Boundary**: ranh giới giữa vùng sorted (phải) và unsorted (trái).

### Invariants

- **Sau pass thứ i**: i phần tử lớn nhất nằm ở đúng vị trí cuối array.
- **Vùng sorted** mở rộng từ phải qua trái sau mỗi pass.
- **Phần tử chưa ở đúng vị trí**: chỉ có thể nằm trong vùng unsorted `[0, n-1-i)`.

### Tại sao cần biết Bubble Sort?

- **Giáo dục**: đơn giản nhất để hiểu sorting, swapping, iteration.
- **Interview**: thường dùng làm baseline so sánh với algorithms nhanh hơn.
- **Optimized Bubble Sort**: minh họa kỹ thuật early termination.
- **KHÔNG dùng trong production** — luôn thua Insertion Sort (cùng O(n²) nhưng Insertion ít swaps hơn).

---

## ② GRAPH

### Visualization — Full Trace

```text
  Input: [5, 3, 8, 1, 2]

  ━━━ Pass 1 (i=0): duyệt [0..3] ━━━
  [5, 3, 8, 1, 2]   j=0: 5>3 → swap    → [3, 5, 8, 1, 2]
  [3, 5, 8, 1, 2]   j=1: 5<8 → no swap
  [3, 5, 8, 1, 2]   j=2: 8>1 → swap    → [3, 5, 1, 8, 2]
  [3, 5, 1, 8, 2]   j=3: 8>2 → swap    → [3, 5, 1, 2, [8]]  ← 8 ở đúng vị trí

  ━━━ Pass 2 (i=1): duyệt [0..2] ━━━
  [3, 5, 1, 2, |8]  j=0: 3<5 → no swap
  [3, 5, 1, 2, |8]  j=1: 5>1 → swap    → [3, 1, 5, 2, |8]
  [3, 1, 5, 2, |8]  j=2: 5>2 → swap    → [3, 1, 2, [5], |8]  ← 5 ở đúng vị trí

  ━━━ Pass 3 (i=2): duyệt [0..1] ━━━
  [3, 1, 2, |5, 8]  j=0: 3>1 → swap    → [1, 3, 2, |5, 8]
  [1, 3, 2, |5, 8]  j=1: 3>2 → swap    → [1, 2, [3], |5, 8]  ← 3 ở đúng vị trí

  ━━━ Pass 4 (i=3): duyệt [0..0] ━━━
  [1, 2, |3, 5, 8]  j=0: 1<2 → no swap → swapped=false → STOP!

  Output: [1, 2, 3, 5, 8] ✓
  Total: 4 passes, 6 swaps
```

### Best Case vs Worst Case

```text
  Best case: [1, 2, 3, 4, 5]     Already sorted
  Pass 1: 0 swaps → swapped=false → STOP
  Comparisons: n-1 = 4           → O(n) ✅

  Worst case: [5, 4, 3, 2, 1]    Reverse sorted
  Pass 1: 4 swaps → [4, 3, 2, 1, 5]
  Pass 2: 3 swaps → [3, 2, 1, 4, 5]
  Pass 3: 2 swaps → [2, 1, 3, 4, 5]
  Pass 4: 1 swap  → [1, 2, 3, 4, 5]
  Total: 4+3+2+1 = 10 swaps = n(n-1)/2  → O(n²) ❌
```

---

## ③ CODE

### Example 1: Basic Bubble Sort — Đơn giản nhất

**Mục tiêu**: Implement Bubble Sort thuần túy — cơ bản nhất, không optimization.

**Cần gì**: Go standard library.

**Có gì**: Slice integers → 2 nested loops → sort ascending.

```go
package sorting

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BubbleSortBasic: phiên bản cơ bản nhất
//
// 2 nested loops:
//   Outer: n-1 passes
//   Inner: so sánh arr[j] với arr[j+1]
//
// Time: LUÔN O(n²) — không có early termination
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BubbleSortBasic(arr []int) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        for j := 0; j < n-1-i; j++ { // n-1-i: bỏ qua vùng sorted
            if arr[j] > arr[j+1] {
                arr[j], arr[j+1] = arr[j+1], arr[j] // swap
            }
        }
    }
}

func main() {
    arr := []int{64, 34, 25, 12, 22, 11, 90}
    fmt.Println("Before:", arr)

    BubbleSortBasic(arr)
    fmt.Println("After: ", arr)
    // Output: After:  [11 12 22 25 34 64 90]
}
```

**Kết quả đạt được**:

- **Đúng kết quả** — sort ascending.
- **Đơn giản** — chỉ 2 nested loops + 1 swap.

**Lưu ý**:

- **Luôn O(n²)** — kể cả input đã sorted vẫn chạy đủ passes.
- **`n-1-i`**: inner loop giảm range mỗi pass — phần tử cuối đã sorted.

---

### Example 2: Optimized Bubble Sort — Early Termination

**Mục tiêu**: Thêm `swapped` flag — nếu không có swap trong 1 pass → array đã sorted → stop.

**Cần gì**: Go standard library.

**Có gì**: BubbleSortBasic + `swapped` flag → best case O(n).

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BubbleSortOptimized: early termination khi không có swap
//
// Optimization: nếu 1 pass không có swap → array đã sorted
// Best case: O(n) — already sorted → 1 pass, 0 swaps
// Average/Worst: O(n²) — chỉ giảm constant factor
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BubbleSortOptimized(arr []int) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        swapped := false // ← optimization flag

        for j := 0; j < n-1-i; j++ {
            if arr[j] > arr[j+1] {
                arr[j], arr[j+1] = arr[j+1], arr[j]
                swapped = true
            }
        }

        // ━━━ Nếu không swap → đã sorted → stop sớm ━━━
        if !swapped {
            break
        }
    }
}
```

**Kết quả đạt được**:

- **Best case O(n)**: already-sorted input → 1 pass, n-1 comparisons, 0 swaps → immediate break.
- **Adaptive**: performance phụ thuộc "disorder" của input.

**Lưu ý**:

-**Average case vẫn O(n²)** — chỉ nearly-sorted mới hưởng lợi.
- Đây là phiên bản **nên dùng** nếu phải implement Bubble Sort (thay vì basic).

---

### Example 3: Cocktail Shaker Sort — Bidirectional Bubble Sort

**Mục tiêu**: Bubble Sort cải tiến — duyệt cả 2 chiều (trái→phải, rồi phải→trái). Giải quyết "turtle problem".

**Cần gì**: Go standard library.

**Có gì**: Bidirectional passes → phần tử nhỏ cũng "nổi" nhanh.

```go
package sorting

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CocktailShakerSort: Bidirectional Bubble Sort
//
// Vấn đề Bubble Sort: "turtle" — phần tử nhỏ ở cuối di chuyển rất chậm
//   Ví dụ: [2, 3, 4, 5, 1] → 1 phải "bò" qua 4 passes mới về đầu
//
// Solution: duyệt 2 chiều:
//   Left→Right: bubble lớn lên cuối
//   Right→Left: bubble nhỏ về đầu
//
// Time: O(n²) — cùng worst case, nhưng faster cho "turtle" cases
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CocktailShakerSort(arr []int) {
    n := len(arr)
    start, end := 0, n-1

    for start < end {
        swapped := false

        // ━━━ Pass forward: trái → phải (bubble max lên cuối) ━━━
        for j := start; j < end; j++ {
            if arr[j] > arr[j+1] {
                arr[j], arr[j+1] = arr[j+1], arr[j]
                swapped = true
            }
        }
        end-- // phần tử cuối đã sorted

        // ━━━ Pass backward: phải → trái (bubble min về đầu) ━━━
        for j := end; j > start; j-- {
            if arr[j] < arr[j-1] {
                arr[j], arr[j-1] = arr[j-1], arr[j]
                swapped = true
            }
        }
        start++ // phần tử đầu đã sorted

        if !swapped {
            break
        }
    }
}
```

**Kết quả đạt được**:

- **Giải turtle problem**: `[2, 3, 4, 5, 1]` → Cocktail chỉ cần 1 forward + 1 backward pass.
- **Bidirectional**: sorted boundary thu hẹp từ cả 2 đầu.

**Lưu ý**:

- **Vẫn O(n²)** — chỉ cải thiện constant factor, KHÔNG thay đổi complexity class.
- Trong thực tế, **Insertion Sort** vẫn nhanh hơn cả Cocktail Shaker cho same O(n²).

---

### Example 4: Generic Bubble Sort — Go 1.18+ Generics

**Mục tiêu**: Bubble Sort generic — sort bất kỳ `Ordered` type (int, float64, string) cùng 1 function.

**Cần gì**: Go 1.18+.

**Có gì**: Generic constraint `Ordered` → type-safe tại compile time.

```go
package sorting

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Ordered: constraint cho comparable types
// Go 1.21+ có sẵn cmp.Ordered, nhưng ta tự define cho compatibility
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Ordered interface {
    ~int | ~int8 | ~int16 | ~int32 | ~int64 |
        ~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 |
        ~float32 | ~float64 | ~string
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BubbleSortGeneric: sort any Ordered type
//
// Ưu điểm vs interface{}:
// - Compile-time type safety — không cần type assertion
// - Zero runtime overhead — Go compiler generates specialized code
// - Cleaner API — no casts
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BubbleSortFunc: custom comparator — sort any type
//
// less(a, b) returns true if a should come before b
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BubbleSortFunc[T any](arr []T, less func(a, b T) bool) {
    n := len(arr)
    for i := 0; i < n-1; i++ {
        swapped := false
        for j := 0; j < n-1-i; j++ {
            if less(arr[j+1], arr[j]) { // if j+1 should be before j
                arr[j], arr[j+1] = arr[j+1], arr[j]
                swapped = true
            }
        }
        if !swapped {
            break
        }
    }
}

func main() {
    // Sort integers
    nums := []int{5, 3, 8, 1, 2}
    BubbleSortGeneric(nums)
    fmt.Println("Ints:", nums) // [1 2 3 5 8]

    // Sort strings
    words := []string{"banana", "apple", "cherry"}
    BubbleSortGeneric(words)
    fmt.Println("Strings:", words) // [apple banana cherry]

    // Sort floats
    prices := []float64{9.99, 1.50, 4.75, 2.30}
    BubbleSortGeneric(prices)
    fmt.Println("Floats:", prices) // [1.5 2.3 4.75 9.99]

    // Sort structs with custom comparator
    type Product struct {
        Name  string
        Price float64
    }
    products := []Product{
        {"Laptop", 999},
        {"Phone", 699},
        {"Tablet", 499},
    }
    BubbleSortFunc(products, func(a, b Product) bool {
        return a.Price < b.Price // sort by price ASC
    })
    fmt.Println("Products:", products)
}
```

**Kết quả đạt được**:

- **Generic**: 1 function cho `int`, `float64`, `string` — no code duplication.
- **BubbleSortFunc**: custom comparator → sort bất kỳ struct.
- **Type-safe**: compile-time check, zero runtime overhead.

**Lưu ý**:

- **Go 1.21+**: `cmp.Ordered` constraint có sẵn trong stdlib — dùng thay custom `Ordered`.
- **Monomorphization**: Go compiler tạo specialized code cho mỗi type → performance = hand-written.

---

### Example 5: Bubble Sort Descending + Stable Sort Demo

**Mục tiêu**: Minh họa stable sort property — sort students theo điểm, giữ thứ tự ban đầu khi cùng điểm.

**Cần gì**: Go standard library.

**Có gì**: Struct Student → sort by score DESC → verify stable order.

```go
package sorting

import "fmt"

type Student struct {
    Name  string
    Score int
    ID    int // enrollment order
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BubbleSortStudents: sort by score DESC — stable
//
// Stable = students cùng score giữ enrollment order
// Bubble Sort: chỉ swap khi score STRICTLY less → stable ✅
//
// Ví dụ: Alice(80, ID=1), Bob(90, ID=2), Charlie(80, ID=3)
//   After sort (DESC): Bob(90), Alice(80, ID=1), Charlie(80, ID=3)
//   Alice trước Charlie vì ID=1 < ID=3 → stable ✓
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BubbleSortStudents(students []Student) {
    n := len(students)
    for i := 0; i < n-1; i++ {
        swapped := false
        for j := 0; j < n-1-i; j++ {
            // ⚠ STRICTLY less than → giữ relative order khi bằng nhau
            if students[j].Score < students[j+1].Score {
                students[j], students[j+1] = students[j+1], students[j]
                swapped = true
            }
        }
        if !swapped {
            break
        }
    }
}

func main() {
    students := []Student{
        {"Alice", 80, 1},
        {"Bob", 90, 2},
        {"Charlie", 80, 3},
        {"Diana", 95, 4},
        {"Eve", 80, 5},
    }

    fmt.Println("Before:")
    for _, s := range students {
        fmt.Printf("  %s: score=%d, ID=%d\n", s.Name, s.Score, s.ID)
    }

    BubbleSortStudents(students)

    fmt.Println("\nAfter (score DESC, stable):")
    for _, s := range students {
        fmt.Printf("  %s: score=%d, ID=%d\n", s.Name, s.Score, s.ID)
    }
    // Output:
    //   Diana: score=95, ID=4    ← highest
    //   Bob: score=90, ID=2
    //   Alice: score=80, ID=1    ← same score, ID order preserved ✓
    //   Charlie: score=80, ID=3  ← stable: Alice before Charlie
    //   Eve: score=80, ID=5      ← stable: keeps original order
}
```

**Kết quả đạt được**:

- **Stable sort** minh họa: students cùng score giữ enrollment order.
- **DESC sort**: `<` thay `>` trong comparison.
- Hiểu rõ tại sao `>` (strict) → stable, `>=` → unstable.

**Lưu ý**:

- **Bubble Sort stable**: chỉ khi dùng `>` (strict). Nếu `>=` → swap equal elements → unstable!
- **Production stable sort**: dùng `sort.SliceStable` — KHÔNG dùng Bubble Sort.

---

### Example 6: Combo — Benchmark + So sánh với stdlib

**Mục tiêu**: Benchmark Bubble Sort vs stdlib để thấy rõ performance gap. Minh họa tại sao KHÔNG dùng Bubble Sort trong production.

**Cần gì**: Go standard library, `sort`, `time`.

**Có gì**: Generate random data → compare Bubble Sort vs `sort.Ints` → table output.

```go
package sorting

import (
    "fmt"
    "math/rand"
    "sort"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BenchmarkBubbleSort: so sánh performance Bubble Sort vs stdlib
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BenchmarkBubbleSort() {
    sizes := []int{100, 1_000, 5_000, 10_000}

    fmt.Println("┌──────────┬───────────────┬───────────────┬──────────┐")
    fmt.Println("│    n     │  Bubble Sort  │  sort.Ints    │  Ratio   │")
    fmt.Println("├──────────┼───────────────┼───────────────┼──────────┤")

    for _, n := range sizes {
        data := make([]int, n)
        for i := range data {
            data[i] = rand.Intn(n * 10)
        }

        // Bubble Sort
        arr1 := make([]int, n)
        copy(arr1, data)
        start := time.Now()
        BubbleSortOptimized(arr1)
        bubbleTime := time.Since(start)

        // stdlib sort
        arr2 := make([]int, n)
        copy(arr2, data)
        start = time.Now()
        sort.Ints(arr2)
        stdlibTime := time.Since(start)

        // Ratio
        ratio := float64(bubbleTime) / float64(stdlibTime)
        fmt.Printf("│ %8d │ %13v │ %13v │ %7.1fx │\n",
            n, bubbleTime, stdlibTime, ratio)
    }
    fmt.Println("└──────────┴───────────────┴───────────────┴──────────┘")
    fmt.Println()
    fmt.Println("⚠ Bubble Sort chậm hơn stdlib 100-1000x cho n lớn!")
    fmt.Println("  → LUÔN dùng sort.Slice / slices.Sort trong production")
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BenchmarkBestWorstCase: so sánh sorted vs reverse input
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func BenchmarkBestWorstCase() {
    n := 5000

    // Best case: already sorted
    sorted := make([]int, n)
    for i := range sorted {
        sorted[i] = i
    }
    start := time.Now()
    BubbleSortOptimized(sorted)
    bestTime := time.Since(start)

    // Worst case: reverse sorted
    reverse := make([]int, n)
    for i := range reverse {
        reverse[i] = n - i
    }
    start = time.Now()
    BubbleSortOptimized(reverse)
    worstTime := time.Since(start)

    fmt.Printf("n=%d:\n", n)
    fmt.Printf("  Best case (sorted):   %v\n", bestTime)
    fmt.Printf("  Worst case (reverse): %v\n", worstTime)
    fmt.Printf("  Ratio: %.0fx slower\n", float64(worstTime)/float64(bestTime))
}
```

**Kết quả đạt được**:

- **Visual benchmark** — rõ ràng performance gap giữa Bubble Sort và stdlib.
- **Best vs Worst case** — x100-x1000 difference.
- **Kết luận**: **KHÔNG BAO GIỜ** dùng Bubble Sort trong production.

**Lưu ý**:

- `sort.Ints` dùng pdqsort — pattern-defeating quicksort → O(n log n) avg.
- Bubble Sort n=10K: ~200ms. stdlib n=10K: ~0.2ms. Gap: **1000x**!

---

## ④ PITFALLS

| # | Lỗi | Nguyên nhân | Fix |
|---|------|-------------|-----|
| 1 | Dùng Bubble Sort cho n > 100 | O(n²) quá chậm | Dùng stdlib `sort.Slice` |
| 2 | Quên `swapped` flag | Luôn O(n²) kể cả sorted input | Thêm early termination |
| 3 | So sánh `>=` thay `>` → unstable | Swap equal elements → mất relative order | Dùng strict `>` |
| 4 | Inner loop chạy đến `n-1` thay vì `n-1-i` | So sánh thừa vùng đã sorted | Dùng `n-1-i` |
| 5 | Concurrent Bubble Sort | O(n²) + goroutine overhead = tệ hơn | Chỉ sort concurrent cho O(n log n) algorithms |
| 6 | Dùng cho sorting strings dài | So sánh string dài = expensive | Dùng `slices.Sort` |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| Visualgo — Bubble Sort Animation | [visualgo.net/sorting](https://visualgo.net/en/sorting) |
| Wikipedia — Bubble sort | [en.wikipedia.org](https://en.wikipedia.org/wiki/Bubble_sort) |
| Go `sort` package | [pkg.go.dev/sort](https://pkg.go.dev/sort) |
| Big-O Cheat Sheet | [bigocheatsheet.com](https://www.bigocheatsheet.com/) |

---

## ⑥ RECOMMEND

| Thay thế | Khi nào | Lý do |
|----------|---------|-------|
| **Insertion Sort** | n < 50, nearly sorted | Cùng O(n²) nhưng ít swaps, cache-friendly hơn |
| **`sort.Slice`** | Production code | pdqsort hybrid — O(n log n) always |
| **`slices.Sort`** | Go 1.21+ | Generic, nhanh hơn sort.Slice ~10% |
| **Cocktail Shaker** | Khi cần bubble sort nhưng có "turtles" | Bidirectional giải quyết turtle problem |

---

**Liên kết**: [← README](./README.md) · [→ Selection Sort](./02-selection-sort.md)
