# 🧮 Data Structures & Algorithms — Tổng quan & Hướng dẫn

> **Mục đích**: Tổng hợp 25 thuật toán quan trọng nhất, implement bằng Go, từ cơ bản đến nâng cao.
> **Cấu trúc**: Mỗi nhóm thuật toán có **thư mục riêng** — `README.md` summary + file detail cho mỗi algorithm.
> **Format**: ① DEFINE → ② GRAPH → ③ CODE → ④ PITFALLS → ⑤ REF → ⑥ RECOMMEND.

---

## 📂 Cấu trúc thư mục

```text
dsa/
├── README.md                          ← Bạn đang ở đây
├── sorting/                           ← 5 sorting algorithms
│   ├── README.md                      (summary + comparison table)
│   ├── 01-bubble-sort.md
│   ├── 02-selection-sort.md
│   ├── 03-insertion-sort.md
│   ├── 04-merge-sort.md
│   └── 05-quick-sort.md
├── searching/                         ← 5 searching algorithms
│   ├── README.md                      (summary)
│   ├── 01-linear-search.md
│   ├── 02-binary-search.md
│   ├── 03-jump-search.md
│   ├── 04-interpolation-search.md
│   └── 05-exponential-search.md
├── graph/                             ← 5 graph algorithms
│   ├── README.md                      (summary)
│   ├── 01-bfs.md
│   ├── 02-dfs.md
│   ├── 03-dijkstra.md
│   ├── 04-kruskal.md
│   └── 05-prim.md
├── dynamic-programming/               ← 5 DP problems
│   ├── README.md                      (summary)
│   ├── 01-fibonacci.md
│   ├── 02-lcs.md
│   ├── 03-knapsack.md
│   ├── 04-matrix-chain.md
│   └── 05-coin-change.md
├── important-algorithms/              ← 5 important algorithms
│   ├── README.md                      (summary)
│   ├── 01-union-find.md
│   ├── 02-kmp.md
│   ├── 03-rabin-karp.md
│   ├── 04-a-star.md
│   └── 05-backtracking.md
└── pictures/                          ← diagrams & images
```

---

## 📑 Mục lục tổng hợp

### 1. Sorting (Sắp xếp) — [→ sorting/](./sorting/README.md)

| # | Algorithm | Best | Average | Worst | Space | Stable |
|---|-----------|------|---------|-------|-------|--------|
| 1 | [**Bubble Sort**](./sorting/01-bubble-sort.md) | O(n) | O(n²) | O(n²) | O(1) | ✅ |
| 2 | [**Selection Sort**](./sorting/02-selection-sort.md) | O(n²) | O(n²) | O(n²) | O(1) | ❌ |
| 3 | [**Insertion Sort**](./sorting/03-insertion-sort.md) | O(n) | O(n²) | O(n²) | O(1) | ✅ |
| 4 | [**Merge Sort**](./sorting/04-merge-sort.md) | O(n log n) | O(n log n) | O(n log n) | O(n) | ✅ |
| 5 | [**Quick Sort**](./sorting/05-quick-sort.md) | O(n log n) | O(n log n) | O(n²) | O(log n) | ❌ |

### 2. Searching (Tìm kiếm) — [→ searching/](./searching/README.md)

| # | Algorithm | Time (Avg) | Yêu cầu Data |
|---|-----------|------------|---------------|
| 6 | [**Linear Search**](./searching/01-linear-search.md) | O(n) | Không |
| 7 | [**Binary Search**](./searching/02-binary-search.md) | O(log n) | Sorted |
| 8 | [**Jump Search**](./searching/03-jump-search.md) | O(√n) | Sorted |
| 9 | [**Interpolation Search**](./searching/04-interpolation-search.md) | O(log log n) | Sorted + Uniform |
| 10 | [**Exponential Search**](./searching/05-exponential-search.md) | O(log n) | Sorted |

### 3. Graph (Đồ thị) — [→ graph/](./graph/README.md)

| # | Algorithm | Time Complexity | Mục đích |
|---|-----------|-----------------|----------|
| 11 | [**BFS**](./graph/01-bfs.md) | O(V + E) | Duyệt chiều rộng, shortest path (unweighted) |
| 12 | [**DFS**](./graph/02-dfs.md) | O(V + E) | Duyệt chiều sâu, cycle detection, topo sort |
| 13 | [**Dijkstra**](./graph/03-dijkstra.md) | O((V+E) log V) | Shortest path (non-negative weights) |
| 14 | [**Kruskal**](./graph/04-kruskal.md) | O(E log E) | Minimum Spanning Tree (sparse) |
| 15 | [**Prim**](./graph/05-prim.md) | O((V+E) log V) | Minimum Spanning Tree (dense) |

### 4. Dynamic Programming (Quy hoạch động) — [→ dynamic-programming/](./dynamic-programming/README.md)

| # | Algorithm | Time | Space |
|---|-----------|------|-------|
| 16 | [**Fibonacci (DP)**](./dynamic-programming/01-fibonacci.md) | O(n) | O(1) |
| 17 | [**LCS**](./dynamic-programming/02-lcs.md) | O(m × n) | O(m × n) |
| 18 | [**0/1 Knapsack**](./dynamic-programming/03-knapsack.md) | O(n × W) | O(n × W) |
| 19 | [**Matrix Chain**](./dynamic-programming/04-matrix-chain.md) | O(n³) | O(n²) |
| 20 | [**Coin Change**](./dynamic-programming/05-coin-change.md) | O(n × amount) | O(amount) |

### 5. Important Algorithms — [→ important-algorithms/](./important-algorithms/README.md)

| # | Algorithm | Time Complexity | Mục đích |
|---|-----------|-----------------|----------|
| 21 | [**Union-Find**](./important-algorithms/01-union-find.md) | O(α(n)) ≈ O(1) | Disjoint sets, connectivity |
| 22 | [**KMP**](./important-algorithms/02-kmp.md) | O(n + m) | Pattern matching |
| 23 | [**Rabin-Karp**](./important-algorithms/03-rabin-karp.md) | O(n + m) avg | Pattern matching (hash) |
| 24 | [**A\* Search**](./important-algorithms/04-a-star.md) | O(b^d) | Pathfinding with heuristic |
| 25 | [**Backtracking**](./important-algorithms/05-backtracking.md) | O(exponential) | N-Queens, Sudoku Solver |

---

## 🗺️ Algorithm Selection Flowchart

```text
  Bài toán
    │
    ├── Cần sắp xếp?
    │     ├── n nhỏ (< 50)        → Insertion Sort
    │     ├── Cần stable?         → Merge Sort
    │     ├── Memory hạn chế?     → Quick Sort (in-place)
    │     └── Production code?    → sort.Slice / slices.Sort
    │
    ├── Cần tìm kiếm?
    │     ├── Unsorted data?      → Linear Search
    │     ├── Sorted array?       → Binary Search
    │     ├── Uniform distributed?→ Interpolation Search
    │     └── Unbounded size?     → Exponential Search
    │
    ├── Bài toán đồ thị?
    │     ├── Shortest path?
    │     │     ├── Non-negative?  → Dijkstra
    │     │     └── Negative?      → Bellman-Ford
    │     ├── MST?
    │     │     ├── Dense graph?   → Prim
    │     │     └── Sparse graph?  → Kruskal
    │     └── Duyệt?              → BFS (level) / DFS (depth)
    │
    ├── Tối ưu hóa?
    │     ├── Overlapping subproblems? → Dynamic Programming
    │     └── Enumerate + prune?       → Backtracking
    │
    └── String matching?
          ├── Single pattern?   → KMP
          └── Multiple patterns?→ Rabin-Karp / Aho-Corasick
```

---

## 📊 Big-O Complexity Chart

```text
  Time │
       │  O(n!)
       │  ╱  O(2ⁿ)
       │ ╱  ╱
       │╱  ╱   O(n²)       ← Bubble, Selection, Insertion
       │  ╱   ╱
       │ ╱   ╱    O(n log n) ← Merge, Quick, Heap
       │╱   ╱    ╱
       │   ╱    ╱  O(n)     ← Linear Search, KMP
       │  ╱    ╱  ╱
       │ ╱    ╱  ╱  O(√n)   ← Jump Search
       │╱    ╱  ╱  ╱
       │    ╱  ╱  ╱  O(log n) ← Binary Search, Dijkstra
       │   ╱  ╱  ╱  ╱
       │  ╱  ╱  ╱  ╱  O(1)   ← Hash table, Union-Find
       │─╱──╱──╱──╱──╱─────────────────→ Input size (n)
```

---

## ⑥ RECOMMEND

| Thư viện / Tool | Mô tả | Link |
|------------------|--------|------|
| **`sort` (stdlib)** | Go sorting — sort.Slice, sort.Search | [pkg.go.dev/sort](https://pkg.go.dev/sort) |
| **`slices` (stdlib)** | Go 1.21+ generic sort, search | [pkg.go.dev/slices](https://pkg.go.dev/slices) |
| **`container/heap`** | Priority queue — Dijkstra, Prim, top-K | [pkg.go.dev/container/heap](https://pkg.go.dev/container/heap) |
| **`container/list`** | Doubly linked list — BFS queue, LRU | [pkg.go.dev/container/list](https://pkg.go.dev/container/list) |
| **`gonum`** | Graph algorithms, matrix, scientific computing | [gonum.org](https://www.gonum.org/) |
| **`yourbasic/graph`** | Lightweight graph library | [github.com/yourbasic/graph](https://github.com/yourbasic/graph) |
| **`dominikbraun/graph`** | Modern Go graph library with generics | [github.com/dominikbraun/graph](https://github.com/dominikbraun/graph) |

---

**Liên kết**: [← Goroutines](../goroutines/README.md) · [← GORM](../go-orm/README.md) · [← Glossaries](../glosaries/README.md)
