# 🕸️ Graph Algorithms — Tổng quan & Hướng dẫn

> **Mục đích**: 5 thuật toán đồ thị cốt lõi: BFS, DFS, Dijkstra, Kruskal, Prim.

---

## 📑 Mục lục

| # | Algorithm | Time | Space | Mục đích | Detail |
|---|-----------|------|-------|----------|--------|
| 1 | **BFS** | O(V+E) | O(V) | Duyệt chiều rộng, shortest path (unweighted) | [→ 01-bfs.md](./01-bfs.md) |
| 2 | **DFS** | O(V+E) | O(V) | Duyệt chiều sâu, cycle detection, topo sort | [→ 02-dfs.md](./02-dfs.md) |
| 3 | **Dijkstra** | O((V+E)log V) | O(V) | Shortest path (non-negative weights) | [→ 03-dijkstra.md](./03-dijkstra.md) |
| 4 | **Kruskal** | O(E log E) | O(V) | MST (sparse graph) | [→ 04-kruskal.md](./04-kruskal.md) |
| 5 | **Prim** | O((V+E)log V) | O(V) | MST (dense graph) | [→ 05-prim.md](./05-prim.md) |

---

## 🔑 Graph Representations

```text
  Adjacency List: O(V+E) space — best for sparse
  0: [1, 2]
  1: [0, 2, 3]
  2: [0, 1, 3]

  Adjacency Matrix: O(V²) space — best for dense
      0  1  2  3
  0 [ 0, 1, 1, 0 ]
  1 [ 1, 0, 1, 1 ]
  2 [ 1, 1, 0, 1 ]
```

## 🗺️ Selection

```text
  Shortest path? → Dijkstra (non-negative) / Bellman-Ford (negative)
  MST?           → Kruskal (sparse) / Prim (dense)
  Traverse?      → BFS (level-order) / DFS (explore deep)
  Cycle?         → DFS (3-color)
  Topo sort?     → DFS (post-order reverse)
```

---

## ⑥ RECOMMEND

| Library | Mô tả |
|---------|--------|
| **`container/heap`** | Priority queue cho Dijkstra, Prim |
| **`gonum/graph`** | Full graph library |
| **`dominikbraun/graph`** | Modern Go generics graph |

---

**Liên kết**: [← Searching](../searching/README.md) · [→ Dynamic Programming](../dynamic-programming/README.md) · [← DSA Overview](../README.md)
