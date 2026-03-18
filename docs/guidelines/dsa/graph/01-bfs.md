# 🌊 BFS — Breadth-First Search

> **Phân loại**: Graph Traversal, Queue-based
> **Tóm tắt**: Duyệt theo chiều rộng — level by level. Tìm shortest path trong unweighted graph.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(V + E) |
| **Space** | O(V) — queue + visited |
| **Data Structure** | Queue (FIFO) |
| **Use cases** | Shortest path (unweighted), level-order, connected components, bipartite check |

---

## ② GRAPH

```text
        0
      /   \
    1       2          BFS from 0:
   / \       \         Level 0: [0]
  3   4       5        Level 1: [1, 2]
                       Level 2: [3, 4, 5]
                       Order: 0 → 1 → 2 → 3 → 4 → 5
```

---

## ③ CODE

### Example 1: Graph Structure + BFS Traversal

```go
package graph

import "fmt"

type Edge struct {
    To     int
    Weight float64
}

type Graph struct {
    AdjList  map[int][]Edge
    Directed bool
    Vertices int
}

func NewGraph(v int, directed bool) *Graph {
    return &Graph{AdjList: make(map[int][]Edge), Directed: directed, Vertices: v}
}

func (g *Graph) AddEdge(from, to int, w float64) {
    g.AdjList[from] = append(g.AdjList[from], Edge{To: to, Weight: w})
    if !g.Directed {
        g.AdjList[to] = append(g.AdjList[to], Edge{To: from, Weight: w})
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BFS: duyệt theo chiều rộng — level by level
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) BFS(start int) []int {
    visited := make(map[int]bool)
    queue := []int{start}
    visited[start] = true
    var order []int

    for len(queue) > 0 {
        vertex := queue[0]
        queue = queue[1:]
        order = append(order, vertex)

        for _, edge := range g.AdjList[vertex] {
            if !visited[edge.To] {
                visited[edge.To] = true
                queue = append(queue, edge.To)
            }
        }
    }
    return order
}
```

### Example 2: BFS Shortest Path (unweighted)

```go
package graph

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BFSShortestPath: distance + parent map → reconstruct path
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) BFSShortestPath(start int) (dist map[int]int, parent map[int]int) {
    dist = map[int]int{start: 0}
    parent = map[int]int{start: -1}
    visited := map[int]bool{start: true}
    queue := []int{start}

    for len(queue) > 0 {
        v := queue[0]
        queue = queue[1:]
        for _, e := range g.AdjList[v] {
            if !visited[e.To] {
                visited[e.To] = true
                dist[e.To] = dist[v] + 1
                parent[e.To] = v
                queue = append(queue, e.To)
            }
        }
    }
    return
}

func ReconstructPath(parent map[int]int, target int) []int {
    var path []int
    for v := target; v != -1; v = parent[v] {
        path = append([]int{v}, path...)
    }
    return path
}
```

### Example 3: Level-Order BFS

```go
package graph

// BFSLevelOrder: nhóm vertices theo level
func (g *Graph) BFSLevelOrder(start int) [][]int {
    visited := map[int]bool{start: true}
    queue := []int{start}
    var levels [][]int

    for len(queue) > 0 {
        size := len(queue)
        var level []int
        for i := 0; i < size; i++ {
            v := queue[0]
            queue = queue[1:]
            level = append(level, v)
            for _, e := range g.AdjList[v] {
                if !visited[e.To] {
                    visited[e.To] = true
                    queue = append(queue, e.To)
                }
            }
        }
        levels = append(levels, level)
    }
    return levels
}
```

### Example 4: BFS Connected Components

```go
package graph

// ConnectedComponents: đếm và liệt kê connected components
func (g *Graph) ConnectedComponents() [][]int {
    visited := make(map[int]bool)
    var components [][]int

    for v := 0; v < g.Vertices; v++ {
        if !visited[v] {
            // BFS từ v → 1 component
            queue := []int{v}
            visited[v] = true
            var comp []int
            for len(queue) > 0 {
                u := queue[0]
                queue = queue[1:]
                comp = append(comp, u)
                for _, e := range g.AdjList[u] {
                    if !visited[e.To] {
                        visited[e.To] = true
                        queue = append(queue, e.To)
                    }
                }
            }
            components = append(components, comp)
        }
    }
    return components
}
```

### Example 5: Bipartite Check

```go
package graph

// IsBipartite: check nếu graph chia được thành 2 nhóm không liên kết nội bộ
func (g *Graph) IsBipartite() bool {
    color := make(map[int]int) // 0=uncolored, 1=red, 2=blue

    for v := 0; v < g.Vertices; v++ {
        if color[v] != 0 { continue }

        queue := []int{v}
        color[v] = 1

        for len(queue) > 0 {
            u := queue[0]
            queue = queue[1:]
            for _, e := range g.AdjList[u] {
                if color[e.To] == 0 {
                    color[e.To] = 3 - color[u] // alternate 1↔2
                    queue = append(queue, e.To)
                } else if color[e.To] == color[u] {
                    return false // same color adjacent → NOT bipartite
                }
            }
        }
    }
    return true
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | BFS trên disconnected graph | Loop tất cả vertices |
| 2 | Queue `[1:]` garbage | Production: dùng `container/list` |
| 3 | BFS cho weighted graph → sai | Dùng Dijkstra |

---

**Liên kết**: [← README](./README.md) · [→ DFS](./02-dfs.md)
