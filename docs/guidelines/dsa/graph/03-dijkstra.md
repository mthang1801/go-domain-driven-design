# 🛤️ Dijkstra — Shortest Path

> **Phân loại**: Greedy, Single-source shortest path
> **Tóm tắt**: Tìm shortest path từ 1 vertex đến tất cả vertices. Greedy + Priority Queue.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O((V+E) log V) with binary heap |
| **Space** | O(V) |
| **Yêu cầu** | Non-negative edge weights |
| **⚠ Limitation** | KHÔNG dùng cho negative weights → dùng Bellman-Ford |

---

## ② GRAPH

```text
      A ——2—— B
      |       |╲
      4       1  3
      |       |   ╲
      C ——5—— D ——1—— E

  Dijkstra from A:
  Step 1: Visit A → dist[B]=2, dist[C]=4
  Step 2: Visit B → dist[D]=3, dist[E]=5
  Step 3: Visit D → dist[E]=4 (better!)
  Step 4: Visit C
  Step 5: Visit E

  Result: A→B=2, A→C=4, A→D=3, A→E=4
```

---

## ③ CODE

### Example 1: Dijkstra with Min-Heap

```go
package graph

import (
    "container/heap"
    "math"
)

type Item struct {
    Vertex   int
    Distance float64
}

type PQ []*Item
func (pq PQ) Len() int            { return len(pq) }
func (pq PQ) Less(i, j int) bool  { return pq[i].Distance < pq[j].Distance }
func (pq PQ) Swap(i, j int)       { pq[i], pq[j] = pq[j], pq[i] }
func (pq *PQ) Push(x interface{}) { *pq = append(*pq, x.(*Item)) }
func (pq *PQ) Pop() interface{} {
    old := *pq; n := len(old); item := old[n-1]; *pq = old[:n-1]; return item
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Dijkstra: single-source shortest path
//
// Greedy: always pick vertex with minimum distance
// Lazy deletion: skip stale entries instead of decrease-key
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) Dijkstra(start int) (dist map[int]float64, parent map[int]int) {
    dist = make(map[int]float64)
    parent = make(map[int]int)
    for v := 0; v < g.Vertices; v++ {
        dist[v] = math.Inf(1)
        parent[v] = -1
    }
    dist[start] = 0

    pq := &PQ{}
    heap.Init(pq)
    heap.Push(pq, &Item{start, 0})

    for pq.Len() > 0 {
        curr := heap.Pop(pq).(*Item)
        u := curr.Vertex

        if curr.Distance > dist[u] { continue } // stale entry

        for _, e := range g.AdjList[u] {
            nd := dist[u] + e.Weight
            if nd < dist[e.To] {
                dist[e.To] = nd
                parent[e.To] = u
                heap.Push(pq, &Item{e.To, nd})
            }
        }
    }
    return
}
```

### Example 2: Dijkstra — Shortest Path with Path Reconstruction

```go
package graph

import "fmt"

func (g *Graph) ShortestPath(src, dst int) (float64, []int) {
    dist, parent := g.Dijkstra(src)
    if dist[dst] == math.Inf(1) {
        return -1, nil
    }
    path := ReconstructPath(parent, dst)
    return dist[dst], path
}

func exampleDijkstra() {
    g := NewGraph(5, false)
    g.AddEdge(0, 1, 2)
    g.AddEdge(0, 2, 4)
    g.AddEdge(1, 2, 1)
    g.AddEdge(1, 3, 7)
    g.AddEdge(2, 4, 3)
    g.AddEdge(3, 4, 1)

    cost, path := g.ShortestPath(0, 4)
    fmt.Printf("Cost: %.0f, Path: %v\n", cost, path)
    // Cost: 6, Path: [0 1 2 4]
}
```

### Example 3: Multi-Source Dijkstra

```go
package graph

import (
    "container/heap"
    "math"
)

// MultiSourceDijkstra: shortest distance từ ANY source
// Use case: "nearest hospital from every city"
func (g *Graph) MultiSourceDijkstra(sources []int) map[int]float64 {
    dist := make(map[int]float64)
    for v := 0; v < g.Vertices; v++ {
        dist[v] = math.Inf(1)
    }

    pq := &PQ{}
    heap.Init(pq)
    for _, s := range sources {
        dist[s] = 0
        heap.Push(pq, &Item{s, 0})
    }

    for pq.Len() > 0 {
        curr := heap.Pop(pq).(*Item)
        if curr.Distance > dist[curr.Vertex] { continue }
        for _, e := range g.AdjList[curr.Vertex] {
            nd := dist[curr.Vertex] + e.Weight
            if nd < dist[e.To] {
                dist[e.To] = nd
                heap.Push(pq, &Item{e.To, nd})
            }
        }
    }
    return dist
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Negative weights → sai | Bellman-Ford |
| 2 | Stale PQ entries → slow | Lazy deletion check |
| 3 | Forget parent init -1 | Initialize all parents |

---

**Liên kết**: [← DFS](./02-dfs.md) · [→ Kruskal](./04-kruskal.md)
