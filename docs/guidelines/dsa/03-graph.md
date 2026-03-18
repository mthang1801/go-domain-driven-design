# 🕸️ Graph Algorithms — Thuật toán Đồ thị

> **Phạm vi**: 5 thuật toán đồ thị cốt lõi: BFS, DFS, Dijkstra, Kruskal, Prim.
> **Ngôn ngữ**: Go — với annotated comments chi tiết.

---

## ① DEFINE

### Bảng so sánh tổng quan

| Algorithm  | Time Complexity   | Space      | Mục đích                      | Data Structure dùng |
|------------|-------------------|------------|-------------------------------|---------------------|
| BFS        | O(V + E)          | O(V)       | Duyệt theo chiều rộng        | Queue               |
| DFS        | O(V + E)          | O(V)       | Duyệt theo chiều sâu         | Stack / Recursion   |
| Dijkstra   | O((V+E) log V)    | O(V)       | Shortest path (non-negative)  | Priority Queue      |
| Kruskal    | O(E log E)        | O(V)       | Minimum Spanning Tree         | Union-Find          |
| Prim       | O((V+E) log V)    | O(V)       | Minimum Spanning Tree         | Priority Queue      |

### Định nghĩa chính

- **Graph**: tập hợp đỉnh (Vertex/Node) và cạnh (Edge) kết nối chúng.
- **Directed graph (Digraph)**: cạnh có hướng A→B ≠ B→A.
- **Undirected graph**: cạnh hai chiều A—B = B—A.
- **Weighted graph**: mỗi edge có weight (cost/distance).
- **Adjacency List**: mỗi vertex lưu danh sách neighbors → Space O(V+E), phổ biến nhất.
- **Adjacency Matrix**: matrix V×V → Space O(V²), nhanh cho check edge exists.
- **Spanning Tree**: subgraph kết nối tất cả vertices, không cycle, có V-1 edges.
- **MST (Minimum Spanning Tree)**: spanning tree với tổng weight nhỏ nhất.

### Failure Modes

- **Dijkstra với negative weight**: cho kết quả SAI → dùng Bellman-Ford.
- **BFS/DFS trên disconnected graph**: cần chạy từ mọi vertex chưa visited.
- **Cycle detection**: DFS có thể loop vô hạn → cần visited set.

---

## ② GRAPH

### Graph Representations

```text
  Undirected Graph:
        0 ——— 1
        |   ╱ |
        |  ╱  |
        | ╱   |
        2 ——— 3

  Adjacency List:           Adjacency Matrix:
  0: [1, 2]                 0  1  2  3
  1: [0, 2, 3]           0 [0, 1, 1, 0]
  2: [0, 1, 3]           1 [1, 0, 1, 1]
  3: [1, 2]              2 [1, 1, 0, 1]
                          3 [0, 1, 1, 0]
```

### BFS vs DFS Traversal Order

```text
  Graph:        0
              ╱   ╲
            1       2
           ╱ ╲       ╲
          3   4       5

  BFS (Queue):  0 → 1 → 2 → 3 → 4 → 5   (level by level)
  DFS (Stack):  0 → 1 → 3 → 4 → 2 → 5   (dive deep first)
```

### Dijkstra — Shortest Path

```text
  Weighted Graph:
        A ——2—— B
        |       |╲
        4       1  3
        |       |   ╲
        C ——5—— D ——1—— E

  Dijkstra from A:
  ┌──────┬─────┬──────────────┐
  │ Step │ Visit │ Distances   │
  ├──────┼─────┼──────────────┤
  │  1   │  A  │ A=0,B=2,C=4  │
  │  2   │  B  │ D=3,E=5      │
  │  3   │  D  │ E=4          │
  │  4   │  C  │              │
  │  5   │  E  │              │
  └──────┴─────┴──────────────┘
  Shortest: A→B=2, A→C=4, A→D=3, A→E=4
```

---

## ③ CODE

### Example 1: Graph Representation — Adjacency List

**Mục tiêu**: Implement Graph data structure bằng adjacency list — nền tảng cho tất cả graph algorithms.

**Cần gì**: Go standard library.

**Có gì**: Generic graph với Edge struct, hỗ trợ directed/undirected, weighted.

```go
package graph

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Edge: cạnh có weight
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Edge struct {
    To     int     // destination vertex
    Weight float64 // edge weight (1 cho unweighted)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Graph: adjacency list representation
//
// Space: O(V + E) — mỗi vertex lưu list of edges
// Add Edge: O(1)
// Check Edge: O(degree(v)) — iterate neighbors
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Graph struct {
    AdjList  map[int][]Edge
    Directed bool
    Vertices int
}

func NewGraph(vertices int, directed bool) *Graph {
    return &Graph{
        AdjList:  make(map[int][]Edge),
        Directed: directed,
        Vertices: vertices,
    }
}

func (g *Graph) AddEdge(from, to int, weight float64) {
    g.AdjList[from] = append(g.AdjList[from], Edge{To: to, Weight: weight})
    if !g.Directed {
        g.AdjList[to] = append(g.AdjList[to], Edge{To: from, Weight: weight})
    }
}

func (g *Graph) Print() {
    for v := 0; v < g.Vertices; v++ {
        fmt.Printf("%d: ", v)
        for _, e := range g.AdjList[v] {
            fmt.Printf("→%d(w=%.0f) ", e.To, e.Weight)
        }
        fmt.Println()
    }
}
```

---

### Example 2: BFS — Breadth-First Search

**Mục tiêu**: BFS traversal + shortest path (unweighted) + level-order processing.

**Cần gì**: Go standard library.

**Có gì**: BFS dùng queue → duyệt level-by-level → tìm shortest path trong unweighted graph.

```go
package graph

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BFS: duyệt theo chiều rộng — level by level
//
// Data structure: Queue (FIFO)
// Time: O(V + E) — visit mỗi vertex và edge 1 lần
// Space: O(V) — visited array + queue
//
// Use cases:
// - Shortest path trong unweighted graph
// - Level-order traversal
// - Connected components
// - Bipartite check
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) BFS(start int) []int {
    visited := make(map[int]bool)
    queue := []int{start}
    visited[start] = true
    var order []int

    for len(queue) > 0 {
        // Dequeue
        vertex := queue[0]
        queue = queue[1:]
        order = append(order, vertex)

        // Enqueue unvisited neighbors
        for _, edge := range g.AdjList[vertex] {
            if !visited[edge.To] {
                visited[edge.To] = true
                queue = append(queue, edge.To)
            }
        }
    }
    return order
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BFSShortestPath: tìm đường đi ngắn nhất (unweighted graph)
//
// Return: distance map + parent map (để reconstruct path)
// Distance = số edges từ start đến mỗi vertex
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) BFSShortestPath(start int) (dist map[int]int, parent map[int]int) {
    dist = make(map[int]int)
    parent = make(map[int]int)
    visited := make(map[int]bool)

    queue := []int{start}
    visited[start] = true
    dist[start] = 0
    parent[start] = -1

    for len(queue) > 0 {
        vertex := queue[0]
        queue = queue[1:]

        for _, edge := range g.AdjList[vertex] {
            if !visited[edge.To] {
                visited[edge.To] = true
                dist[edge.To] = dist[vertex] + 1
                parent[edge.To] = vertex
                queue = append(queue, edge.To)
            }
        }
    }
    return
}

// ReconstructPath: reconstruct path từ parent map
func ReconstructPath(parent map[int]int, target int) []int {
    var path []int
    for v := target; v != -1; v = parent[v] {
        path = append([]int{v}, path...) // prepend
    }
    return path
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// BFSLevelOrder: duyệt theo level — return [][]int
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) BFSLevelOrder(start int) [][]int {
    visited := make(map[int]bool)
    queue := []int{start}
    visited[start] = true
    var levels [][]int

    for len(queue) > 0 {
        levelSize := len(queue)
        var currentLevel []int

        for i := 0; i < levelSize; i++ {
            vertex := queue[0]
            queue = queue[1:]
            currentLevel = append(currentLevel, vertex)

            for _, edge := range g.AdjList[vertex] {
                if !visited[edge.To] {
                    visited[edge.To] = true
                    queue = append(queue, edge.To)
                }
            }
        }
        levels = append(levels, currentLevel)
    }
    return levels
}

func exampleBFS() {
    g := NewGraph(6, false) // undirected
    g.AddEdge(0, 1, 1)
    g.AddEdge(0, 2, 1)
    g.AddEdge(1, 3, 1)
    g.AddEdge(1, 4, 1)
    g.AddEdge(2, 5, 1)

    fmt.Println("BFS:", g.BFS(0))           // [0 1 2 3 4 5]
    fmt.Println("Levels:", g.BFSLevelOrder(0)) // [[0] [1 2] [3 4 5]]

    dist, parent := g.BFSShortestPath(0)
    fmt.Println("Distance to 5:", dist[5])           // 2
    fmt.Println("Path to 5:", ReconstructPath(parent, 5)) // [0 2 5]
}
```

**Kết quả đạt được**:

- **BFS traversal** — duyệt level-by-level.
- **Shortest path** (unweighted) — distance + reconstruct path.
- **Level-order** — nhóm vertices theo level (distance từ start).

**Lưu ý**:

- **Queue trong Go**: dùng slice — `queue[1:]` tạo garbage → production dùng `container/list` hoặc circular buffer.
- **Unweighted only**: BFS tìm shortest path CHỈ cho unweighted graph. Weighted → Dijkstra.
- **Disconnected graph**: BFS từ 1 vertex không visit toàn bộ → cần loop qua tất cả vertices.

---

### Example 3: DFS — Depth-First Search

**Mục tiêu**: DFS recursive + iterative, cycle detection, topological sort.

**Cần gì**: Go standard library.

**Có gì**: DFS variants cho các use cases phổ biến.

```go
package graph

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DFS (Recursive): duyệt theo chiều sâu
//
// Data structure: Stack (implicit via recursion)
// Time: O(V + E)
// Space: O(V) — recursion stack depth
//
// Use cases:
// - Cycle detection
// - Topological sort
// - Connected components
// - Path finding (not shortest)
// - Strongly connected components (Tarjan/Kosaraju)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) DFS(start int) []int {
    visited := make(map[int]bool)
    var order []int
    g.dfsHelper(start, visited, &order)
    return order
}

func (g *Graph) dfsHelper(vertex int, visited map[int]bool, order *[]int) {
    visited[vertex] = true
    *order = append(*order, vertex)

    for _, edge := range g.AdjList[vertex] {
        if !visited[edge.To] {
            g.dfsHelper(edge.To, visited, order)
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DFSIterative: dùng explicit stack — tránh stack overflow
// Dùng khi: graph rất sâu (depth > 10000)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) DFSIterative(start int) []int {
    visited := make(map[int]bool)
    stack := []int{start}
    var order []int

    for len(stack) > 0 {
        // Pop
        vertex := stack[len(stack)-1]
        stack = stack[:len(stack)-1]

        if visited[vertex] {
            continue
        }
        visited[vertex] = true
        order = append(order, vertex)

        // Push neighbors (reverse order cho consistent traversal)
        neighbors := g.AdjList[vertex]
        for i := len(neighbors) - 1; i >= 0; i-- {
            if !visited[neighbors[i].To] {
                stack = append(stack, neighbors[i].To)
            }
        }
    }
    return order
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HasCycle: cycle detection cho directed graph
//
// 3 states: White (unvisited), Gray (in-progress), Black (done)
// Cycle = gặp Gray node → back edge → cycle!
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const (
    White = 0 // unvisited
    Gray  = 1 // in current DFS path
    Black = 2 // fully explored
)

func (g *Graph) HasCycle() bool {
    color := make(map[int]int) // default White
    for v := 0; v < g.Vertices; v++ {
        if color[v] == White {
            if g.hasCycleDFS(v, color) {
                return true
            }
        }
    }
    return false
}

func (g *Graph) hasCycleDFS(v int, color map[int]int) bool {
    color[v] = Gray // entering DFS → mark in-progress

    for _, edge := range g.AdjList[v] {
        if color[edge.To] == Gray {
            return true // ← back edge → CYCLE!
        }
        if color[edge.To] == White {
            if g.hasCycleDFS(edge.To, color) {
                return true
            }
        }
    }

    color[v] = Black // leaving DFS → fully explored
    return false
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// TopologicalSort: DAG ordering — mỗi edge u→v, u xuất hiện trước v
//
// Use case: build dependencies, task scheduling, course prerequisites
// Yêu cầu: Directed Acyclic Graph (DAG) — có cycle → error
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) TopologicalSort() ([]int, error) {
    if !g.Directed {
        return nil, fmt.Errorf("topological sort requires directed graph")
    }
    if g.HasCycle() {
        return nil, fmt.Errorf("graph has cycle — topological sort impossible")
    }

    visited := make(map[int]bool)
    var stack []int

    var dfs func(v int)
    dfs = func(v int) {
        visited[v] = true
        for _, edge := range g.AdjList[v] {
            if !visited[edge.To] {
                dfs(edge.To)
            }
        }
        stack = append(stack, v) // post-order → push after all descendants
    }

    for v := 0; v < g.Vertices; v++ {
        if !visited[v] {
            dfs(v)
        }
    }

    // Reverse stack → topological order
    result := make([]int, len(stack))
    for i, v := range stack {
        result[len(stack)-1-i] = v
    }
    return result, nil
}

func exampleDFS() {
    // DAG: build dependencies
    g := NewGraph(6, true) // directed
    g.AddEdge(5, 2, 1) // 5 depends on 2
    g.AddEdge(5, 0, 1)
    g.AddEdge(4, 0, 1)
    g.AddEdge(4, 1, 1)
    g.AddEdge(2, 3, 1)
    g.AddEdge(3, 1, 1)

    fmt.Println("DFS:", g.DFS(5))         // [5 2 3 1 0]
    fmt.Println("Cycle:", g.HasCycle())    // false

    topo, _ := g.TopologicalSort()
    fmt.Println("Topological:", topo)      // [5 4 2 3 1 0] or similar
}
```

**Kết quả đạt được**:

- **DFS recursive + iterative** — cùng kết quả, iterative tránh stack overflow.
- **Cycle detection** — 3-color DFS (White/Gray/Black).
- **Topological Sort** — DAG ordering cho dependencies.

**Lưu ý**:

- **Recursive DFS**: stack depth = graph depth → stack overflow cho deep graph (> 10K).
- **Topological Sort**: chỉ cho DAG — có cycle → impossible.
- **Connected components**: chạy DFS/BFS từ mỗi unvisited vertex, mỗi lần = 1 component.

---

### Example 4: Dijkstra — Shortest Path

**Mục tiêu**: Dijkstra's algorithm tìm shortest path từ 1 vertex đến tất cả vertices (single-source shortest path).

**Cần gì**: Go standard library, `container/heap`.

**Có gì**: Weighted graph → priority queue (min-heap) → shortest distances.

```go
package graph

import (
    "container/heap"
    "fmt"
    "math"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Priority Queue cho Dijkstra — min-heap by distance
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Item struct {
    Vertex   int
    Distance float64
}

type PriorityQueue []*Item

func (pq PriorityQueue) Len() int            { return len(pq) }
func (pq PriorityQueue) Less(i, j int) bool  { return pq[i].Distance < pq[j].Distance }
func (pq PriorityQueue) Swap(i, j int)       { pq[i], pq[j] = pq[j], pq[i] }

func (pq *PriorityQueue) Push(x interface{}) {
    *pq = append(*pq, x.(*Item))
}

func (pq *PriorityQueue) Pop() interface{} {
    old := *pq
    n := len(old)
    item := old[n-1]
    *pq = old[:n-1]
    return item
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Dijkstra: single-source shortest path
//
// Greedy: luôn chọn vertex có distance nhỏ nhất (via priority queue)
//
// Time: O((V + E) log V) — with binary heap
// Space: O(V) — distance array + priority queue
//
// ⚠ KHÔNG DÙNG cho negative weights → dùng Bellman-Ford
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) Dijkstra(start int) (dist map[int]float64, parent map[int]int) {
    dist = make(map[int]float64)
    parent = make(map[int]int)

    // Initialize: tất cả distance = ∞
    for v := 0; v < g.Vertices; v++ {
        dist[v] = math.Inf(1)
        parent[v] = -1
    }
    dist[start] = 0

    // Priority Queue (min-heap)
    pq := &PriorityQueue{}
    heap.Init(pq)
    heap.Push(pq, &Item{Vertex: start, Distance: 0})

    for pq.Len() > 0 {
        // Extract minimum
        current := heap.Pop(pq).(*Item)
        u := current.Vertex

        // Skip nếu đã có distance tốt hơn (lazy deletion)
        if current.Distance > dist[u] {
            continue
        }

        // Relax edges
        for _, edge := range g.AdjList[u] {
            v := edge.To
            newDist := dist[u] + edge.Weight

            if newDist < dist[v] {
                dist[v] = newDist
                parent[v] = u
                heap.Push(pq, &Item{Vertex: v, Distance: newDist})
            }
        }
    }
    return
}

func exampleDijkstra() {
    g := NewGraph(5, false) // undirected weighted
    g.AddEdge(0, 1, 2)  // A—B: 2
    g.AddEdge(0, 2, 4)  // A—C: 4
    g.AddEdge(1, 2, 1)  // B—C: 1
    g.AddEdge(1, 3, 7)  // B—D: 7
    g.AddEdge(2, 4, 3)  // C—E: 3
    g.AddEdge(3, 4, 1)  // D—E: 1

    dist, parent := g.Dijkstra(0)

    for v := 0; v < 5; v++ {
        path := ReconstructPath(parent, v)
        fmt.Printf("  0 → %d: distance=%.0f, path=%v\n", v, dist[v], path)
    }
    // Output:
    // 0 → 0: distance=0, path=[0]
    // 0 → 1: distance=2, path=[0 1]
    // 0 → 2: distance=3, path=[0 1 2]
    // 0 → 3: distance=7, path=[0 1 2 4 3] hoặc [0 1 3]
    // 0 → 4: distance=6, path=[0 1 2 4]
}
```

**Kết quả đạt được**:

- **Dijkstra with min-heap** — O((V+E) log V).
- **Lazy deletion**: skip outdated entries thay vì decrease-key.
- **Path reconstruction**: parent map → trace back.

**Lưu ý**:

- **⚠ Negative weights**: Dijkstra cho kết quả SAI → dùng Bellman-Ford O(VE).
- **Lazy deletion**: heap có thể chứa stale entries → check `dist[u]` trước khi relax.
- **`container/heap`**: Go cung cấp heap interface — implement 5 methods.
- **Fibonacci heap**: O((V + E) + V log V) — nhanh hơn binary heap nhưng complex.

---

### Example 5: Kruskal — Minimum Spanning Tree

**Mục tiêu**: Kruskal's algorithm — sort edges by weight → add edge nếu không tạo cycle (Union-Find).

**Cần gì**: Go standard library, `sort`.

**Có gì**: Weighted undirected graph → MST bằng greedy edge selection + Union-Find.

```go
package graph

import (
    "fmt"
    "sort"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Union-Find (Disjoint Set Union) — nền tảng cho Kruskal
//
// Operations:
// - Find(x): tìm root (representative) của set chứa x
// - Union(x, y): merge 2 sets
//
// Optimizations:
// - Path compression: Find flatten tree → amortized O(α(n)) ≈ O(1)
// - Union by rank: attach smaller tree dưới larger tree
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type UnionFind struct {
    parent []int
    rank   []int
}

func NewUnionFind(n int) *UnionFind {
    parent := make([]int, n)
    rank := make([]int, n)
    for i := range parent {
        parent[i] = i // mỗi phần tử là root của chính nó
    }
    return &UnionFind{parent: parent, rank: rank}
}

func (uf *UnionFind) Find(x int) int {
    if uf.parent[x] != x {
        uf.parent[x] = uf.Find(uf.parent[x]) // path compression
    }
    return uf.parent[x]
}

func (uf *UnionFind) Union(x, y int) bool {
    rootX, rootY := uf.Find(x), uf.Find(y)
    if rootX == rootY {
        return false // already same set → would create cycle
    }
    // Union by rank
    switch {
    case uf.rank[rootX] < uf.rank[rootY]:
        uf.parent[rootX] = rootY
    case uf.rank[rootX] > uf.rank[rootY]:
        uf.parent[rootY] = rootX
    default:
        uf.parent[rootY] = rootX
        uf.rank[rootX]++
    }
    return true
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EdgeWeight: edge struct cho Kruskal (sortable)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type EdgeWeight struct {
    From, To int
    Weight   float64
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Kruskal: MST bằng greedy edge selection
//
// 1. Sort tất cả edges by weight (ascending)
// 2. Duyệt edges: nếu 2 vertices khác set → add edge + union
// 3. Stop khi MST có V-1 edges
//
// Time: O(E log E) — dominated by sort
// Space: O(V) — Union-Find
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) Kruskal() ([]EdgeWeight, float64) {
    // Collect all edges
    var edges []EdgeWeight
    seen := make(map[[2]int]bool) // avoid duplicates for undirected

    for from, neighbors := range g.AdjList {
        for _, e := range neighbors {
            key := [2]int{min(from, e.To), max(from, e.To)}
            if !seen[key] {
                seen[key] = true
                edges = append(edges, EdgeWeight{From: from, To: e.To, Weight: e.Weight})
            }
        }
    }

    // Sort edges by weight
    sort.Slice(edges, func(i, j int) bool {
        return edges[i].Weight < edges[j].Weight
    })

    uf := NewUnionFind(g.Vertices)
    var mst []EdgeWeight
    totalWeight := 0.0

    for _, edge := range edges {
        // Nếu 2 vertices khác component → add edge (không tạo cycle)
        if uf.Union(edge.From, edge.To) {
            mst = append(mst, edge)
            totalWeight += edge.Weight

            // MST complete khi có V-1 edges
            if len(mst) == g.Vertices-1 {
                break
            }
        }
    }

    return mst, totalWeight
}

func exampleKruskal() {
    g := NewGraph(6, false)
    g.AddEdge(0, 1, 4)
    g.AddEdge(0, 2, 4)
    g.AddEdge(1, 2, 2)
    g.AddEdge(1, 0, 4)
    g.AddEdge(2, 3, 3)
    g.AddEdge(2, 5, 2)
    g.AddEdge(2, 4, 4)
    g.AddEdge(3, 4, 3)
    g.AddEdge(5, 4, 3)

    mst, total := g.Kruskal()
    fmt.Printf("MST total weight: %.0f\n", total)
    for _, e := range mst {
        fmt.Printf("  %d — %d (w=%.0f)\n", e.From, e.To, e.Weight)
    }
}
```

**Kết quả đạt được**:

- **Kruskal MST** — greedy + Union-Find.
- **Union-Find** với path compression + union by rank → amortized O(α(n)) ≈ O(1).
- **Edge sorting** — O(E log E) dominates.

**Lưu ý**:

- **Kruskal vs Prim**: Kruskal tốt cho **sparse graph** (ít edges), Prim tốt cho **dense graph**.
- **Union-Find** reusable cho nhiều bài toán khác: connected components, cycle detection, network connectivity.
- **Disconnected graph**: Kruskal tạo MST forest (nhiều trees) thay vì 1 MST.

---

### Example 6: Prim — Minimum Spanning Tree

**Mục tiêu**: Prim's algorithm — grow MST từ 1 vertex, greedy chọn edge nhẹ nhất kết nối vertex mới.

**Cần gì**: Go standard library, `container/heap`, `math`.

**Có gì**: Weighted undirected graph → priority queue → MST.

```go
package graph

import (
    "container/heap"
    "fmt"
    "math"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Prim: MST bằng greedy vertex expansion
//
// 1. Start từ vertex bất kỳ
// 2. Priority queue: chọn edge nhẹ nhất kết nối vertex mới
// 3. Repeat cho đến khi tất cả vertices thuộc MST
//
// Time: O((V + E) log V) — with binary heap
// Space: O(V)
//
// Khi nào dùng Prim vs Kruskal?
// - Prim: dense graph (E ≈ V²) — adjacency matrix, giống Dijkstra
// - Kruskal: sparse graph (E ≈ V) — edge list, đơn giản hơn
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func (g *Graph) Prim(start int) ([]EdgeWeight, float64) {
    inMST := make(map[int]bool)
    key := make(map[int]float64)   // minimum weight to reach vertex
    parent := make(map[int]int)

    // Initialize: all keys = ∞
    for v := 0; v < g.Vertices; v++ {
        key[v] = math.Inf(1)
        parent[v] = -1
    }
    key[start] = 0

    // Priority Queue
    pq := &PriorityQueue{}
    heap.Init(pq)
    heap.Push(pq, &Item{Vertex: start, Distance: 0})

    for pq.Len() > 0 {
        current := heap.Pop(pq).(*Item)
        u := current.Vertex

        if inMST[u] {
            continue // already in MST
        }
        inMST[u] = true

        // Explore neighbors
        for _, edge := range g.AdjList[u] {
            v := edge.To
            if !inMST[v] && edge.Weight < key[v] {
                key[v] = edge.Weight
                parent[v] = u
                heap.Push(pq, &Item{Vertex: v, Distance: edge.Weight})
            }
        }
    }

    // Build MST edges
    var mst []EdgeWeight
    totalWeight := 0.0
    for v := 0; v < g.Vertices; v++ {
        if parent[v] != -1 {
            mst = append(mst, EdgeWeight{From: parent[v], To: v, Weight: key[v]})
            totalWeight += key[v]
        }
    }

    return mst, totalWeight
}

func examplePrim() {
    g := NewGraph(5, false)
    g.AddEdge(0, 1, 2)
    g.AddEdge(0, 3, 6)
    g.AddEdge(1, 2, 3)
    g.AddEdge(1, 3, 8)
    g.AddEdge(1, 4, 5)
    g.AddEdge(2, 4, 7)
    g.AddEdge(3, 4, 9)

    mst, total := g.Prim(0)
    fmt.Printf("Prim MST total weight: %.0f\n", total)
    for _, e := range mst {
        fmt.Printf("  %d — %d (w=%.0f)\n", e.From, e.To, e.Weight)
    }
}
```

**Kết quả đạt được**:

- **Prim MST** — grow tree, giống Dijkstra structure.
- **Priority Queue** reuse từ Dijkstra — cùng `container/heap` interface.

**Lưu ý**:

- **Prim giống Dijkstra**: cùng greedy + priority queue, nhưng key = edge weight (Prim) vs path distance (Dijkstra).
- **Dense graph**: Prim + adjacency matrix → O(V²) — nhanh hơn Kruskal O(E log E) khi E ≈ V².
- **Same MST**: Kruskal và Prim cho cùng MST (nếu unique weights).

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Dijkstra + negative weights | Dùng Bellman-Ford |
| 2 | BFS/DFS không xử lý disconnected graph | Loop qua tất cả unvisited vertices |
| 3 | DFS recursive stack overflow | Dùng iterative DFS + explicit stack |
| 4 | Forget visited check → infinite loop | Luôn mark visited TRƯỚC khi enqueue/push |
| 5 | Kruskal trên directed graph | MST chỉ cho undirected — directed dùng Edmonds' algorithm |
| 6 | Dijkstra lazy deletion memory leak | Limit queue size hoặc dùng indexed priority queue |
| 7 | Topological sort trên graph có cycle | Check cycle trước — return error |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| `container/heap` | [pkg.go.dev/container/heap](https://pkg.go.dev/container/heap) |
| Visualgo — Graph | [visualgo.net/graphds](https://visualgo.net/en/graphds) |
| Dijkstra Visualization | [visualgo.net/sssp](https://visualgo.net/en/sssp) |
| Union-Find | [cp-algorithms.com](https://cp-algorithms.com/data_structures/disjoint_set_union.html) |

---

## ⑥ RECOMMEND

| Tool / Library | Mô tả | Khi nào dùng |
|----------------|--------|---------------|
| **`container/heap`** | Go stdlib priority queue | Dijkstra, Prim, Top-K |
| **`gonum/graph`** | Full graph library — algorithms, builders | Production graph processing |
| **`yourbasic/graph`** | Lightweight graph — BFS, DFS, shortest path | Quick prototyping |
| **`dominikbraun/graph`** | Modern Go graph library with generics | Go 1.18+ projects |

---

**Liên kết**: [← Searching](./02-searching.md) · [→ Dynamic Programming](./04-dynamic-programming.md) · [← README](./README.md)
