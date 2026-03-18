# 🔍 Searching Algorithms — Tổng quan & Hướng dẫn

> **Mục đích**: 5 thuật toán tìm kiếm: Linear, Binary, Jump, Interpolation, Exponential Search.
> **Cấu trúc**: Mỗi algorithm có file detail riêng.

---

## 📑 Mục lục

| # | Algorithm | Time (Avg) | Time (Worst) | Space | Yêu cầu Data | Detail |
|---|-----------|------------|--------------|-------|---------------|--------|
| 1 | **Linear Search** | O(n) | O(n) | O(1) | Không | [→ 01-linear-search.md](./01-linear-search.md) |
| 2 | **Binary Search** | O(log n) | O(log n) | O(1) | Sorted | [→ 02-binary-search.md](./02-binary-search.md) |
| 3 | **Jump Search** | O(√n) | O(√n) | O(1) | Sorted | [→ 03-jump-search.md](./03-jump-search.md) |
| 4 | **Interpolation Search** | O(log log n) | O(n) | O(1) | Sorted + Uniform | [→ 04-interpolation-search.md](./04-interpolation-search.md) |
| 5 | **Exponential Search** | O(log n) | O(log n) | O(1) | Sorted | [→ 05-exponential-search.md](./05-exponential-search.md) |

---

## 🗺️ Algorithm Selection Flowchart

```text
  Cần tìm kiếm?
    │
    ├── Data unsorted?
    │     └── Linear Search (lựa chọn duy nhất)
    │
    ├── Data sorted?
    │     ├── General purpose         → Binary Search ⭐
    │     ├── Uniformly distributed?  → Interpolation Search
    │     ├── Sequential access only? → Jump Search
    │     └── Unknown array size?     → Exponential Search
    │
    └── Production Go code?
          ├── sort.Search       (Go < 1.21)
          └── slices.BinarySearch (Go 1.21+)
```

---

## 🔑 Khái niệm chung

### Sorted vs Unsorted

- **Unsorted data**: chỉ có Linear Search O(n) — không thể nhanh hơn.
- **Sorted data**: Binary Search O(log n) — chia đôi search space mỗi bước.
- **Sort trước + search**: O(n log n) + O(log n) — chỉ đáng nếu search nhiều lần.

### Go Standard Library

```go
import (
    "sort"
    "slices" // Go 1.21+
)

// sort.Search — generic binary search (Go 1.0+)
idx := sort.SearchInts(arr, target)

// slices.BinarySearch — generic + type-safe (Go 1.21+)
idx, found := slices.BinarySearch(arr, target)
```

---

## ⑥ RECOMMEND

| Tool / Library | Mô tả | Khi nào dùng |
|----------------|--------|---------------|
| **`sort.Search`** | Go stdlib binary search — predicate-based | Mọi Go version |
| **`slices.BinarySearch`** | Go 1.21+ generic binary search | New projects |
| **`sort.SearchInts/Strings`** | Type-specific search | Quick prototyping |
| **`container/heap`** | Priority queue — min/max finding | Top-K, median |

---

**Liên kết**: [← Sorting](../sorting/README.md) · [→ Graph](../graph/README.md) · [← DSA Overview](../README.md)
