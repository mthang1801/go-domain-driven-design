# 🏔️ DFS — Depth-First Search

> **Phân loại**: Graph Traversal, Stack/Recursion-based
> **Tóm tắt**: Duyệt theo chiều sâu — đi sâu nhất có thể rồi backtrack.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(V + E) |
| **Space** | O(V) — stack depth |
| **Data Structure** | Stack (implicit recursion / explicit) |
| **Use cases** | Cycle detection, topological sort, connected components, path finding |

---

## ② GRAPH

```text
        0                DFS from 0:
      /   \              0 → 1 → 3 → 4 → 2 → 5
    1       2            (dive deep before exploring siblings)
   / \       \
  3   4       5

  Cycle detection (3-color):
  White (unvisited) → Gray (in-progress) → Black (done)
  Gặp Gray node → CYCLE!
```

---

## ③ CODE

### Example 1: Recursive DFS

```go
package graph

func (g *Graph) DFS(start int) []int {
    visited := make(map[int]bool)
    var order []int
    g.dfsHelper(start, visited, &order)
    return order
}

func (g *Graph) dfsHelper(v int, visited map[int]bool, order *[]int) {
    visited[v] = true
    *order = append(*order, v)
    for _, e := range g.AdjList[v] {
        if !visited[e.To] {
            g.dfsHelper(e.To, visited, order)
        }
    }
}
```

### Example 2: Iterative DFS — tránh stack overflow

```go
package graph

// DFSIterative: explicit stack — safe cho deep graphs (depth > 10K)
func (g *Graph) DFSIterative(start int) []int {
    visited := make(map[int]bool)
    stack := []int{start}
    var order []int

    for len(stack) > 0 {
        v := stack[len(stack)-1]
        stack = stack[:len(stack)-1]

        if visited[v] { continue }
        visited[v] = true
        order = append(order, v)

        neighbors := g.AdjList[v]
        for i := len(neighbors) - 1; i >= 0; i-- {
            if !visited[neighbors[i].To] {
                stack = append(stack, neighbors[i].To)
            }
        }
    }
    return order
}
```

### Example 3: Cycle Detection — 3-Color DFS

```go
package graph

const (
    White = 0 // unvisited
    Gray  = 1 // in current DFS path
    Black = 2 // fully explored
)

// HasCycle: detect cycle in directed graph
func (g *Graph) HasCycle() bool {
    color := make(map[int]int)
    for v := 0; v < g.Vertices; v++ {
        if color[v] == White {
            if g.hasCycleDFS(v, color) { return true }
        }
    }
    return false
}

func (g *Graph) hasCycleDFS(v int, color map[int]int) bool {
    color[v] = Gray
    for _, e := range g.AdjList[v] {
        if color[e.To] == Gray { return true } // back edge → CYCLE
        if color[e.To] == White {
            if g.hasCycleDFS(e.To, color) { return true }
        }
    }
    color[v] = Black
    return false
}
```

### Example 4: Topological Sort — DAG Ordering

```go
package graph

import "fmt"

// TopologicalSort: DFS post-order → reverse = topo order
// Yêu cầu: Directed Acyclic Graph (DAG)
func (g *Graph) TopologicalSort() ([]int, error) {
    if !g.Directed {
        return nil, fmt.Errorf("requires directed graph")
    }
    if g.HasCycle() {
        return nil, fmt.Errorf("graph has cycle")
    }

    visited := make(map[int]bool)
    var stack []int

    var dfs func(v int)
    dfs = func(v int) {
        visited[v] = true
        for _, e := range g.AdjList[v] {
            if !visited[e.To] { dfs(e.To) }
        }
        stack = append(stack, v) // post-order
    }

    for v := 0; v < g.Vertices; v++ {
        if !visited[v] { dfs(v) }
    }

    // Reverse
    result := make([]int, len(stack))
    for i, v := range stack {
        result[len(stack)-1-i] = v
    }
    return result, nil
}
```

### Example 5: Find All Paths (DFS Backtracking)

```go
package graph

// AllPaths: tìm tất cả đường từ src → dst
func (g *Graph) AllPaths(src, dst int) [][]int {
    var results [][]int
    visited := make(map[int]bool)
    path := []int{src}
    visited[src] = true

    g.allPathsDFS(src, dst, visited, path, &results)
    return results
}

func (g *Graph) allPathsDFS(curr, dst int, visited map[int]bool, path []int, results *[][]int) {
    if curr == dst {
        p := make([]int, len(path))
        copy(p, path)
        *results = append(*results, p)
        return
    }

    for _, e := range g.AdjList[curr] {
        if !visited[e.To] {
            visited[e.To] = true
            g.allPathsDFS(e.To, dst, visited, append(path, e.To), results)
            visited[e.To] = false // backtrack
        }
    }
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Recursive → stack overflow | Iterative DFS |
| 2 | Cycle → infinite loop | Visited check |
| 3 | Topo sort trên cyclic graph | Check cycle first |

---

**Liên kết**: [← BFS](./01-bfs.md) · [→ Dijkstra](./03-dijkstra.md)
