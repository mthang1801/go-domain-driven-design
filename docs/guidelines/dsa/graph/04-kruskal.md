# 🌲 Kruskal — Minimum Spanning Tree

> **Phân loại**: Greedy, Edge-based MST
> **Tóm tắt**: Sort edges by weight → add edge nếu không tạo cycle (Union-Find).

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(E log E) — dominated by sort |
| **Space** | O(V) — Union-Find |
| **Best for** | Sparse graphs (E ≈ V) |
| **Data Structure** | Union-Find (Disjoint Set) |

---

## ② GRAPH

```text
  Edges sorted by weight:
  B-D:1, A-B:2, C-E:2, B-C:3, D-E:4, A-C:4, C-D:5

  Step 1: B-D (w=1) → add ✓
  Step 2: A-B (w=2) → add ✓
  Step 3: C-E (w=2) → add ✓
  Step 4: B-C (w=3) → add ✓ (connects {A,B,D} with {C,E})
  → MST complete (V-1=4 edges)

  MST weight = 1+2+2+3 = 8
```

---

## ③ CODE

### Example 1: Union-Find (DSU)

```go
package graph

type UnionFind struct {
    parent, rank []int
}

func NewUnionFind(n int) *UnionFind {
    p := make([]int, n)
    for i := range p { p[i] = i }
    return &UnionFind{parent: p, rank: make([]int, n)}
}

func (uf *UnionFind) Find(x int) int {
    if uf.parent[x] != x {
        uf.parent[x] = uf.Find(uf.parent[x]) // path compression
    }
    return uf.parent[x]
}

func (uf *UnionFind) Union(x, y int) bool {
    rx, ry := uf.Find(x), uf.Find(y)
    if rx == ry { return false }
    if uf.rank[rx] < uf.rank[ry] { rx, ry = ry, rx }
    uf.parent[ry] = rx
    if uf.rank[rx] == uf.rank[ry] { uf.rank[rx]++ }
    return true
}
```

### Example 2: Kruskal MST

```go
package graph

import (
    "fmt"
    "sort"
)

type EdgeW struct {
    From, To int
    Weight   float64
}

func (g *Graph) Kruskal() ([]EdgeW, float64) {
    var edges []EdgeW
    seen := make(map[[2]int]bool)
    for from, neighbors := range g.AdjList {
        for _, e := range neighbors {
            key := [2]int{min(from, e.To), max(from, e.To)}
            if !seen[key] {
                seen[key] = true
                edges = append(edges, EdgeW{from, e.To, e.Weight})
            }
        }
    }

    sort.Slice(edges, func(i, j int) bool {
        return edges[i].Weight < edges[j].Weight
    })

    uf := NewUnionFind(g.Vertices)
    var mst []EdgeW
    total := 0.0

    for _, e := range edges {
        if uf.Union(e.From, e.To) {
            mst = append(mst, e)
            total += e.Weight
            if len(mst) == g.Vertices-1 { break }
        }
    }
    return mst, total
}

func min(a, b int) int { if a < b { return a }; return b }
func max(a, b int) int { if a > b { return a }; return b }
```

### Example 3: Kruskal — Count Connected Components

```go
package graph

// Kruskal variant: số components = V - edges_added
func (g *Graph) CountComponents() int {
    uf := NewUnionFind(g.Vertices)
    for from, neighbors := range g.AdjList {
        for _, e := range neighbors {
            uf.Union(from, e.To)
        }
    }
    roots := make(map[int]bool)
    for v := 0; v < g.Vertices; v++ {
        roots[uf.Find(v)] = true
    }
    return len(roots)
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Kruskal trên directed graph | MST chỉ cho undirected |
| 2 | Duplicate edges undirected | Track seen edges |
| 3 | No path compression in UF | Always use path compression |

---

**Liên kết**: [← Dijkstra](./03-dijkstra.md) · [→ Prim](./05-prim.md)
