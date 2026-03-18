# 🌳 Prim — Minimum Spanning Tree

> **Phân loại**: Greedy, Vertex-based MST
> **Tóm tắt**: Grow MST từ 1 vertex, greedy chọn edge nhẹ nhất kết nối vertex mới.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O((V+E) log V) with binary heap |
| **Space** | O(V) |
| **Best for** | Dense graphs (E ≈ V²) |
| **So sánh Kruskal** | Prim = vertex-based, Kruskal = edge-based |

---

## ② GRAPH

```text
  Start from A:
  Step 1: Add A, edges {A-B:2, A-C:4}
  Step 2: Pick A-B(2) → MST={A-B}
  Step 3: Add B's edges → {A-C:4, B-C:1, B-D:7}
  Step 4: Pick B-C(1) → MST={A-B, B-C}
  Step 5: Pick C-E(3) → MST={A-B, B-C, C-E}
  Step 6: Pick E-D(1) → MST complete
```

---

## ③ CODE

### Example 1: Prim with Priority Queue

```go
package graph

import (
    "container/heap"
    "math"
)

func (g *Graph) Prim(start int) ([]EdgeW, float64) {
    inMST := make(map[int]bool)
    key := make(map[int]float64)
    parent := make(map[int]int)

    for v := 0; v < g.Vertices; v++ {
        key[v] = math.Inf(1)
        parent[v] = -1
    }
    key[start] = 0

    pq := &PQ{}
    heap.Init(pq)
    heap.Push(pq, &Item{start, 0})

    for pq.Len() > 0 {
        curr := heap.Pop(pq).(*Item)
        u := curr.Vertex
        if inMST[u] { continue }
        inMST[u] = true

        for _, e := range g.AdjList[u] {
            if !inMST[e.To] && e.Weight < key[e.To] {
                key[e.To] = e.Weight
                parent[e.To] = u
                heap.Push(pq, &Item{e.To, e.Weight})
            }
        }
    }

    var mst []EdgeW
    total := 0.0
    for v := 0; v < g.Vertices; v++ {
        if parent[v] != -1 {
            mst = append(mst, EdgeW{parent[v], v, key[v]})
            total += key[v]
        }
    }
    return mst, total
}
```

### Example 2: Prim với Adjacency Matrix — O(V²) cho Dense Graph

```go
package graph

import "math"

// PrimMatrix: O(V²) — tốt hơn heap-based khi E ≈ V²
func PrimMatrix(adjMatrix [][]float64) (float64, []int) {
    n := len(adjMatrix)
    inMST := make([]bool, n)
    key := make([]float64, n)
    parent := make([]int, n)

    for i := range key {
        key[i] = math.Inf(1)
        parent[i] = -1
    }
    key[0] = 0

    for count := 0; count < n; count++ {
        // Find min key vertex not in MST
        u, minKey := -1, math.Inf(1)
        for v := 0; v < n; v++ {
            if !inMST[v] && key[v] < minKey {
                u, minKey = v, key[v]
            }
        }
        if u == -1 { break }
        inMST[u] = true

        for v := 0; v < n; v++ {
            if !inMST[v] && adjMatrix[u][v] > 0 && adjMatrix[u][v] < key[v] {
                key[v] = adjMatrix[u][v]
                parent[v] = u
            }
        }
    }

    total := 0.0
    for _, k := range key { total += k }
    return total, parent
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Prim trên disconnected graph | Check all vertices visited |
| 2 | Key = path distance (Dijkstra) | Key = edge weight (Prim) |
| 3 | Dense graph + heap = slow | Use adjacency matrix O(V²) |

---

**Liên kết**: [← Kruskal](./04-kruskal.md) · [← README](./README.md)
