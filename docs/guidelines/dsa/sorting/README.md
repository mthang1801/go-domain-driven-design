# 🔢 Sorting Algorithms — Tổng quan & Hướng dẫn

> **Mục đích**: Tổng hợp 5 thuật toán sắp xếp cốt lõi, implement bằng Go, từ cơ bản đến nâng cao.
> **Cấu trúc**: Mỗi thuật toán có file detail riêng theo format ① DEFINE → ② GRAPH → ③ CODE → ④ PITFALLS → ⑤ REF → ⑥ RECOMMEND.

---

## 📑 Mục lục

| # | Algorithm | Best | Average | Worst | Space | Stable | In-place | Detail |
|---|-----------|------|---------|-------|-------|--------|----------|--------|
| 1 | **Bubble Sort** | O(n) | O(n²) | O(n²) | O(1) | ✅ | ✅ | [→ 01-bubble-sort.md](./01-bubble-sort.md) |
| 2 | **Selection Sort** | O(n²) | O(n²) | O(n²) | O(1) | ❌ | ✅ | [→ 02-selection-sort.md](./02-selection-sort.md) |
| 3 | **Insertion Sort** | O(n) | O(n²) | O(n²) | O(1) | ✅ | ✅ | [→ 03-insertion-sort.md](./03-insertion-sort.md) |
| 4 | **Merge Sort** | O(n log n) | O(n log n) | O(n log n) | O(n) | ✅ | ❌ | [→ 04-merge-sort.md](./04-merge-sort.md) |
| 5 | **Quick Sort** | O(n log n) | O(n log n) | O(n²) | O(log n) | ❌ | ✅ | [→ 05-quick-sort.md](./05-quick-sort.md) |

---

## 🗺️ Algorithm Selection Flowchart

```text
  Cần sort?
    │
    ├── n rất nhỏ (< 20)?
    │     └── Insertion Sort (cache-friendly, low overhead)
    │
    ├── Gần sorted / streaming data?
    │     └── Insertion Sort (best case O(n), online)
    │
    ├── Cần stable sort?
    │     ├── Memory OK?    → Merge Sort (guaranteed O(n log n))
    │     └── Memory hạn chế? → Insertion Sort (in-place, stable)
    │
    ├── Memory hạn chế + n lớn?
    │     └── Quick Sort (in-place, O(log n) stack)
    │
    ├── Cần guaranteed O(n log n)?
    │     └── Merge Sort (never O(n²))
    │
    ├── General purpose (fastest average)?
    │     └── Quick Sort (pdqsort hybrid)
    │
    └── Production Go code?
          └── sort.Slice / slices.Sort (LUÔN dùng stdlib)
```

---

## 📊 Performance Comparison

```text
  Time │
  (ms) │
       │                                    ╱ Bubble O(n²)
       │                                  ╱
       │                                ╱   ╱ Selection O(n²)
       │                              ╱   ╱
       │                            ╱   ╱
       │                          ╱   ╱     ╱ Insertion O(n²)
       │                        ╱   ╱     ╱
       │                      ╱   ╱     ╱
       │          ╱──────────────────── Quick O(n log n) avg
       │        ╱           ╱
       │      ╱──────────── Merge O(n log n) guaranteed
       │    ╱
       │──╱─────────────────────────────────────→ n
       0       1K     10K    100K    1M

  n=10K:   Bubble ~250ms  |  Quick ~2ms  |  Merge ~3ms
  n=100K:  Bubble ~25s    |  Quick ~25ms |  Merge ~35ms
```

---

## 🔑 Khái niệm chung

### Định nghĩa

- **Stable sort**: giữ nguyên thứ tự tương đối của các phần tử bằng nhau. Ví dụ: sort students theo điểm — stable sort giữ thứ tự ban đầu nếu cùng điểm.
- **In-place sort**: không cần bộ nhớ phụ O(n) — chỉ dùng O(1) hoặc O(log n) stack space.
- **Comparison-based**: so sánh cặp phần tử — lower bound lý thuyết O(n log n).
- **Adaptive**: tận dụng data đã sorted → performance tốt hơn average case.
- **Inversions**: số cặp (i, j) mà i < j nhưng arr[i] > arr[j]. Array sorted = 0 inversions. Reverse sorted = n(n-1)/2 inversions.

### Khi nào dùng từng algorithm?

| Tình huống | Algorithm | Lý do |
|------------|-----------|-------|
| Giáo dục, demo | Bubble Sort | Đơn giản nhất |
| n < 50, nearly sorted | Insertion Sort | O(n) best case, low overhead |
| Write expensive (Flash) | Selection Sort | Chỉ n-1 swaps |
| Cần stable + O(n log n) | Merge Sort | Guaranteed, stable |
| General purpose, n lớn | Quick Sort | Fastest average |
| Production code | `sort.Slice` / `slices.Sort` | Stdlib optimized (pdqsort) |

---

## 🏗️ Go Standard Library Sorting

```go
import (
    "sort"
    "slices" // Go 1.21+
)

// ━━━ sort.Slice (Go 1.8+) — most common ━━━
sort.Slice(arr, func(i, j int) bool {
    return arr[i] < arr[j]
})

// ━━━ sort.SliceStable — stable version ━━━
sort.SliceStable(arr, func(i, j int) bool {
    return arr[i] < arr[j]
})

// ━━━ slices.Sort (Go 1.21+) — generic, fastest ━━━
slices.Sort(arr) // uses pdqsort

// ━━━ slices.SortFunc — custom comparator ━━━
slices.SortFunc(people, func(a, b Person) int {
    return cmp.Compare(a.Age, b.Age)
})
```

---

## ⑥ RECOMMEND

| Tool / Library | Mô tả | Khi nào dùng |
|----------------|--------|---------------|
| **`sort.Slice`** | Go stdlib — pdqsort hybrid | Production general-purpose |
| **`sort.SliceStable`** | Stable version of sort.Slice | Khi cần giữ relative order |
| **`slices.Sort`** | Go 1.21+ generic sort — nhanh hơn sort.Slice ~10% | New projects, Go 1.21+ |
| **`slices.SortFunc`** | Custom comparator generic sort | Sort structs với custom logic |
| **`sort.Search`** | Binary search trong sorted slice | Tìm insertion point |
| **`container/heap`** | Priority queue — heap sort nền tảng | Top-K problems, Dijkstra |

---

**Liên kết**: [← DSA Overview](../README.md) · [→ Searching](../searching/README.md)
