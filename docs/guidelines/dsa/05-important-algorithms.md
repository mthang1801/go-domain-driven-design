# 🧩 Important Algorithms — Thuật toán Quan trọng

> **Phạm vi**: 5 thuật toán quan trọng: Union-Find (DSU), KMP, Rabin-Karp, A* Search, Backtracking.
> **Ngôn ngữ**: Go — với annotated comments chi tiết.

---

## ① DEFINE

### Bảng so sánh tổng quan

| Algorithm       | Time Complexity     | Space    | Mục đích                           |
|-----------------|---------------------|----------|-------------------------------------|
| Union-Find      | O(α(n)) ≈ O(1)     | O(n)     | Disjoint sets, connectivity         |
| KMP             | O(n + m)            | O(m)     | Pattern matching (single pattern)   |
| Rabin-Karp      | O(n + m) avg        | O(1)     | Pattern matching (hashing)          |
| A* Search       | O(b^d)              | O(b^d)  | Pathfinding with heuristic          |
| Backtracking    | O(exponential)      | O(n)     | Constraint satisfaction, enumerate  |

### Định nghĩa chính

- **Union-Find (DSU)**: cấu trúc dữ liệu quản lý các tập hợp rời rạc. 2 operations: `Find(x)` (tìm root), `Union(x,y)` (merge 2 sets).
- **KMP (Knuth-Morris-Pratt)**: tìm pattern trong text KHÔNG quay lui text pointer. Xây failure function → skip unnecessary comparisons.
- **Rabin-Karp**: tìm pattern bằng rolling hash — so sánh hash trước, string sau. Tốt cho multi-pattern matching.
- **A\* Search**: pathfinding tối ưu — Dijkstra + heuristic. `f(n) = g(n) + h(n)`. g = actual cost, h = estimated cost to goal.
- **Backtracking**: brute force + pruning. Thử tất cả khả năng, quay lui (backtrack) khi gặp dead-end. Giải N-Queens, Sudoku, tổ hợp.

### Failure Modes

- **A\* với heuristic overestimate**: không đảm bảo shortest path nếu h(n) > actual cost.
- **KMP failure function sai**: pattern matching sai kết quả.
- **Backtracking không pruning**: exponential → timeout.

---

## ② GRAPH

### KMP — Failure Function

```text
  Pattern: "ABABAC"
  Failure function (longest proper prefix = suffix):

  Index:    0  1  2  3  4  5
  Pattern:  A  B  A  B  A  C
  F[]:      0  0  1  2  3  0

  Text:    "ABABABABAC"
  Pattern: "ABABAC"

  Step 1: ABAB match → A≠C → use F[4]=3 → shift pattern
  Step 2: ...ABABAC → FOUND at index 4 ✓

  Key insight: khi mismatch tại position j,
  shift pattern đến F[j-1] thay vì quay về 0
```

### A* Search — Grid Pathfinding

```text
  Grid 5×5, S=Start, G=Goal, #=Wall

  S . . . .       f=g+h, h=Manhattan distance
  . # # . .
  . . # . .       Open set: priority queue by f(n)
  . . . # .       Closed set: already evaluated
  . . . . G

  Path found: S→(1,0)→(2,1)→(2,2)→(3,3)→(4,4)=G
  Total cost: 8 steps
```

### Backtracking — N-Queens Decision Tree

```text
  4-Queens:
                    []
           ╱     ╱    ╲     ╲
         Q(0,0) Q(0,1) Q(0,2) Q(0,3)
         ╱  ╲
    Q(1,2) Q(1,3)    ← chỉ 2 vị trí hợp lệ cho row 1
      │      │
    Q(2,?)  Q(2,1)   ← Q(2,?) không có → BACKTRACK!
             │
           Q(3,?)    ← check...

  Solution 1: [(0,1), (1,3), (2,0), (3,2)] ✓
  Solution 2: [(0,2), (1,0), (2,3), (3,1)] ✓
```

---

## ③ CODE

### Example 1: Union-Find (Disjoint Set Union)

**Mục tiêu**: Full Union-Find implementation với path compression + union by rank. Use cases: connected components, Kruskal MST, social network friend groups.

**Cần gì**: Go standard library.

**Có gì**: Union-Find struct → Find (with path compression) → Union (by rank) → Connected check.

```go
package algorithms

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UnionFind: Disjoint Set Union
//
// Operations:
//   Find(x):  tìm root (representative) — O(α(n)) ≈ O(1) amortized
//   Union(x,y): merge 2 sets            — O(α(n)) ≈ O(1) amortized
//   Connected(x,y): check same set      — O(α(n))
//
// α(n) = inverse Ackermann function — grows SO SLOW:
//   α(10^80) = 4 → effectively O(1)
//
// Optimizations:
//   Path compression: Find flatten tree → every node points to root
//   Union by rank:    smaller tree under larger → balanced tree
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type UnionFind struct {
    parent []int
    rank   []int
    count  int // number of disjoint sets
}

func NewUnionFind(n int) *UnionFind {
    parent := make([]int, n)
    rank := make([]int, n)
    for i := range parent {
        parent[i] = i // initially: each element is its own set
    }
    return &UnionFind{parent: parent, rank: rank, count: n}
}

// Find: tìm root với path compression
func (uf *UnionFind) Find(x int) int {
    if uf.parent[x] != x {
        uf.parent[x] = uf.Find(uf.parent[x]) // path compression
    }
    return uf.parent[x]
}

// Union: merge 2 sets, return true nếu merged (false = already same set)
func (uf *UnionFind) Union(x, y int) bool {
    rootX, rootY := uf.Find(x), uf.Find(y)
    if rootX == rootY {
        return false // already connected
    }

    // Union by rank: smaller tree under larger
    switch {
    case uf.rank[rootX] < uf.rank[rootY]:
        uf.parent[rootX] = rootY
    case uf.rank[rootX] > uf.rank[rootY]:
        uf.parent[rootY] = rootX
    default:
        uf.parent[rootY] = rootX
        uf.rank[rootX]++
    }
    uf.count--
    return true
}

func (uf *UnionFind) Connected(x, y int) bool {
    return uf.Find(x) == uf.Find(y)
}

func (uf *UnionFind) Count() int { return uf.count }

func exampleUnionFind() {
    // Social network: 7 users
    uf := NewUnionFind(7)

    // Friend connections
    uf.Union(0, 1) // 0-1 are friends
    uf.Union(1, 2) // 1-2 → now 0,1,2 same group
    uf.Union(3, 4) // 3-4 are friends
    uf.Union(5, 6) // 5-6 are friends

    fmt.Println("0 connected to 2?", uf.Connected(0, 2)) // true
    fmt.Println("0 connected to 3?", uf.Connected(0, 3)) // false
    fmt.Println("Groups:", uf.Count())                     // 3

    uf.Union(2, 4) // connect groups: {0,1,2} + {3,4}
    fmt.Println("Groups after merge:", uf.Count()) // 2
}
```

**Kết quả đạt được**:

- **O(α(n)) ≈ O(1)** per operation — effectively constant time.
- **Path compression + Union by rank** — two optimizations together.
- **Real use cases**: Kruskal MST, connected components, network connectivity, equivalence classes.

**Lưu ý**:

- **Không thể Un-union**: DSU chỉ add edges, không delete → cần rollback thì dùng Union-Find with rollback (competitive programming).
- **Thread safety**: `Find` modifies `parent[]` (path compression) → cần mutex cho concurrent access.

---

### Example 2: KMP Algorithm — Pattern Matching

**Mục tiêu**: KMP string matching — O(n+m) guaranteed. Xây failure function → tìm pattern không quay lui.

**Cần gì**: Go standard library.

**Có gì**: Build failure table → match pattern against text → return all positions.

```go
package algorithms

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// KMP: Knuth-Morris-Pratt Pattern Matching
//
// Key idea: khi mismatch, KHÔNG quay text pointer về đầu.
//   Dùng failure function để biết pattern pointer nên quay về đâu.
//
// Failure function F[j]: longest proper prefix of pattern[0..j]
//   that is also a suffix.
//
// Time: O(n + m) — text length n, pattern length m
// Space: O(m) — failure table
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// buildFailureTable: compute failure (prefix) function
// F[j] = length of longest proper prefix of pattern[0..j]
//        that is also a suffix of pattern[0..j]
func buildFailureTable(pattern string) []int {
    m := len(pattern)
    failure := make([]int, m)
    failure[0] = 0 // no proper prefix for single char

    length := 0 // length of previous longest prefix-suffix
    i := 1

    for i < m {
        if pattern[i] == pattern[length] {
            length++
            failure[i] = length
            i++
        } else {
            if length != 0 {
                length = failure[length-1] // ← backtrack in pattern
            } else {
                failure[i] = 0
                i++
            }
        }
    }
    return failure
}

// KMPSearch: tìm tất cả vị trí pattern trong text
func KMPSearch(text, pattern string) []int {
    n, m := len(text), len(pattern)
    if m == 0 || m > n {
        return nil
    }

    failure := buildFailureTable(pattern)
    var matches []int

    i, j := 0, 0 // text pointer, pattern pointer

    for i < n {
        if text[i] == pattern[j] {
            i++
            j++
        }

        if j == m {
            // ━━━ MATCH found at index i-j ━━━
            matches = append(matches, i-j)
            j = failure[j-1] // continue searching (overlapping matches)
        } else if i < n && text[i] != pattern[j] {
            if j != 0 {
                j = failure[j-1] // ← use failure function, DON'T backtrack text
            } else {
                i++ // no match at all, advance text
            }
        }
    }
    return matches
}

func exampleKMP() {
    text := "ABABDABACDABABCABAB"
    pattern := "ABAB"

    matches := KMPSearch(text, pattern)
    fmt.Printf("Pattern '%s' found at positions: %v\n", pattern, matches)
    // [0 10 14]

    // Highlight matches
    for _, pos := range matches {
        fmt.Printf("  ...%s[%s]%s...\n",
            text[:pos], text[pos:pos+len(pattern)], text[pos+len(pattern):])
    }
}
```

**Kết quả đạt được**:

- **O(n + m)** guaranteed — no worst case degradation.
- **Failure table** — reusable cho same pattern nhiều texts.
- **Overlapping matches** — `j = failure[j-1]` cho phép tìm overlapping.

**Lưu ý**:

- **Go stdlib**: `strings.Index` dùng Rabin-Karp (hashing) — không phải KMP.
- **KMP vs Rabin-Karp**: KMP = O(n+m) guaranteed, Rabin-Karp = O(n+m) average.
- **Multiple patterns**: KMP tìm 1 pattern. Nhiều patterns → Aho-Corasick.

---

### Example 3: Rabin-Karp Algorithm — Rolling Hash

**Mục tiêu**: Rabin-Karp pattern matching dùng rolling hash — tốt cho multi-pattern matching.

**Cần gì**: Go standard library.

**Có gì**: Rolling hash → compare hash → verify match → find all positions.

```go
package algorithms

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Rabin-Karp: Pattern Matching via Rolling Hash
//
// Key idea: hash(window) == hash(pattern) → verify string match
//   Rolling hash: update hash O(1) khi slide window
//
// Hash function: polynomial rolling hash
//   hash(s) = s[0]*base^(m-1) + s[1]*base^(m-2) + ... + s[m-1]
//
// Time: O(n + m) average, O(nm) worst (many hash collisions)
// Space: O(1)
//
// Ưu điểm so với KMP:
// - Simpler implementation
// - Multi-pattern matching: compute hash cho tất cả patterns → O(1) lookup
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const (
    base    = 256        // character set size
    modulus = 1000000007 // prime modulus to avoid overflow
)

func RabinKarpSearch(text, pattern string) []int {
    n, m := len(text), len(pattern)
    if m > n {
        return nil
    }

    var matches []int

    // Compute hash of pattern and first window of text
    patternHash := 0
    windowHash := 0
    h := 1 // base^(m-1) % modulus

    // Precompute h = base^(m-1) % modulus
    for i := 0; i < m-1; i++ {
        h = (h * base) % modulus
    }

    // Initial hash
    for i := 0; i < m; i++ {
        patternHash = (patternHash*base + int(pattern[i])) % modulus
        windowHash = (windowHash*base + int(text[i])) % modulus
    }

    // Slide window
    for i := 0; i <= n-m; i++ {
        // Hash match → verify string (avoid false positive)
        if windowHash == patternHash {
            if text[i:i+m] == pattern {
                matches = append(matches, i)
            }
        }

        // ━━━ Rolling hash: update for next window ━━━
        // Remove leading char, add trailing char
        if i < n-m {
            windowHash = (base*(windowHash-int(text[i])*h) + int(text[i+m])) % modulus
            if windowHash < 0 {
                windowHash += modulus // handle negative modulus
            }
        }
    }
    return matches
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RabinKarpMultiPattern: tìm nhiều patterns cùng lúc
// Hash tất cả patterns → set lookup O(1)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func RabinKarpMultiPattern(text string, patterns []string) map[string][]int {
    results := make(map[string][]int)
    for _, p := range patterns {
        results[p] = RabinKarpSearch(text, p)
    }
    return results
}

func exampleRabinKarp() {
    text := "AABAACAADAABAABA"
    pattern := "AABA"

    matches := RabinKarpSearch(text, pattern)
    fmt.Printf("Pattern '%s' found at: %v\n", pattern, matches)
    // [0 9 12]

    // Multi-pattern
    results := RabinKarpMultiPattern(text, []string{"AAB", "AAC", "AAD"})
    for p, pos := range results {
        fmt.Printf("  '%s': %v\n", p, pos)
    }
}
```

**Kết quả đạt được**:

- **Rolling hash** — update hash O(1) per window slide.
- **Multi-pattern matching** — hash tất cả patterns → lookup.
- **Modular arithmetic** — tránh integer overflow.

**Lưu ý**:

- **Hash collision**: 2 strings khác nhau, cùng hash → PHẢI verify string match.
- **Worst case O(nm)**: khi tất cả hash match (pathological input). Dùng double hashing để giảm.
- **Go `strings.Index`**: internal dùng Rabin-Karp variant — optimized C implementation.

---

### Example 4: A* Search — Pathfinding

**Mục tiêu**: A* pathfinding trên grid — tìm đường ngắn nhất với heuristic (Manhattan distance).

**Cần gì**: Go standard library, `container/heap`, `math`.

**Có gì**: Grid map → A* → optimal path. Heuristic: Manhattan distance.

```go
package algorithms

import (
    "container/heap"
    "fmt"
    "math"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// A* Search: Dijkstra + Heuristic
//
// f(n) = g(n) + h(n)
//   g(n) = actual cost from start to n
//   h(n) = estimated cost from n to goal (heuristic)
//
// Admissible heuristic: h(n) ≤ actual cost → guarantees optimal
//   Manhattan: |x1-x2| + |y1-y2| — admissible for grid
//   Euclidean: sqrt((x1-x2)² + (y1-y2)²) — admissible
//
// Time: O(b^d) — b = branching factor, d = depth
// Space: O(b^d) — open set + closed set
//
// A* = Dijkstra khi h(n) = 0 (no heuristic)
// A* = Greedy BFS khi g(n) = 0 (no actual cost)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

type Point struct {
    X, Y int
}

type AStarNode struct {
    Pos    Point
    G, H   float64 // g = actual cost, h = heuristic
    F      float64 // f = g + h
    Parent *AStarNode
}

// Priority Queue for A*
type AStarPQ []*AStarNode

func (pq AStarPQ) Len() int            { return len(pq) }
func (pq AStarPQ) Less(i, j int) bool  { return pq[i].F < pq[j].F }
func (pq AStarPQ) Swap(i, j int)       { pq[i], pq[j] = pq[j], pq[i] }
func (pq *AStarPQ) Push(x interface{}) { *pq = append(*pq, x.(*AStarNode)) }
func (pq *AStarPQ) Pop() interface{} {
    old := *pq
    n := len(old)
    item := old[n-1]
    *pq = old[:n-1]
    return item
}

// Manhattan distance heuristic (admissible for grid)
func manhattan(a, b Point) float64 {
    return math.Abs(float64(a.X-b.X)) + math.Abs(float64(a.Y-b.Y))
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AStar: pathfinding trên grid
//
// grid[y][x]: 0 = passable, 1 = wall
// Returns: path (list of points), cost
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func AStar(grid [][]int, start, goal Point) ([]Point, float64) {
    rows, cols := len(grid), len(grid[0])

    // Directions: up, down, left, right
    dirs := []Point{{0, -1}, {0, 1}, {-1, 0}, {1, 0}}

    openSet := &AStarPQ{}
    heap.Init(openSet)

    startNode := &AStarNode{
        Pos: start,
        G:   0,
        H:   manhattan(start, goal),
    }
    startNode.F = startNode.G + startNode.H
    heap.Push(openSet, startNode)

    closedSet := make(map[Point]bool)
    gScore := map[Point]float64{start: 0}

    for openSet.Len() > 0 {
        current := heap.Pop(openSet).(*AStarNode)

        // ━━━ Goal reached ━━━
        if current.Pos == goal {
            return reconstructAStarPath(current), current.G
        }

        if closedSet[current.Pos] {
            continue
        }
        closedSet[current.Pos] = true

        // Explore neighbors
        for _, dir := range dirs {
            next := Point{current.Pos.X + dir.X, current.Pos.Y + dir.Y}

            // Bounds check + wall check
            if next.X < 0 || next.X >= cols || next.Y < 0 || next.Y >= rows {
                continue
            }
            if grid[next.Y][next.X] == 1 { // wall
                continue
            }
            if closedSet[next] {
                continue
            }

            tentativeG := current.G + 1 // cost = 1 per step

            if prevG, ok := gScore[next]; ok && tentativeG >= prevG {
                continue // not a better path
            }

            gScore[next] = tentativeG
            neighbor := &AStarNode{
                Pos:    next,
                G:      tentativeG,
                H:      manhattan(next, goal),
                Parent: current,
            }
            neighbor.F = neighbor.G + neighbor.H
            heap.Push(openSet, neighbor)
        }
    }

    return nil, -1 // no path found
}

func reconstructAStarPath(node *AStarNode) []Point {
    var path []Point
    for node != nil {
        path = append([]Point{node.Pos}, path...) // prepend
        node = node.Parent
    }
    return path
}

func exampleAStar() {
    grid := [][]int{
        {0, 0, 0, 0, 0},
        {0, 1, 1, 0, 0},
        {0, 0, 1, 0, 0},
        {0, 0, 0, 1, 0},
        {0, 0, 0, 0, 0},
    }

    start := Point{0, 0}
    goal := Point{4, 4}

    path, cost := AStar(grid, start, goal)
    fmt.Printf("Path: %v\n", path)
    fmt.Printf("Cost: %.0f steps\n", cost)

    // Visualize
    for y, row := range grid {
        for x, cell := range row {
            p := Point{x, y}
            switch {
            case p == start:
                fmt.Print("S ")
            case p == goal:
                fmt.Print("G ")
            case containsPoint(path, p):
                fmt.Print("* ")
            case cell == 1:
                fmt.Print("# ")
            default:
                fmt.Print(". ")
            }
        }
        fmt.Println()
    }
}

func containsPoint(path []Point, p Point) bool {
    for _, pp := range path {
        if pp == p {
            return true
        }
    }
    return false
}
```

**Kết quả đạt được**:

- **A\* pathfinding** — optimal path with heuristic guidance.
- **Manhattan heuristic** — admissible for 4-directional grid movement.
- **Path reconstruction** — parent pointer chain.
- **Grid visualization** — visual output.

**Lưu ý**:

- **Admissible heuristic**: h(n) ≤ actual cost → A* returns optimal path. Overestimate → suboptimal.
- **A\* = Dijkstra** khi h(n) = 0 — Dijkstra là special case của A*.
- **8-directional movement**: thêm diagonal dirs + dùng Euclidean/Octile heuristic.
- **Use cases**: game AI, robot navigation, route planning (Google Maps).

---

### Example 5: Backtracking — N-Queens + Sudoku Solver

**Mục tiêu**: Backtracking framework — giải N-Queens và Sudoku Solver.

**Cần gì**: Go standard library.

**Có gì**: Backtracking template → N-Queens (tất cả solutions) → Sudoku Solver.

```go
package algorithms

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// N-Queens: đặt N quân hậu trên bàn cờ N×N
// sao cho không có 2 quân hậu nào tấn công nhau
//
// Backtracking:
// 1. Đặt queen tại mỗi row (1 queen per row)
// 2. Check conflicts: same column, same diagonal
// 3. Nếu conflict → backtrack (thử cột khác)
// 4. Tìm TẤT CẢ solutions
//
// Time: O(N!) — worst case thử tất cả permutations
// Space: O(N) — queens positions
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

type NQueensSolver struct {
    N         int
    Solutions [][]int // mỗi solution: queens[row] = column
}

func NewNQueensSolver(n int) *NQueensSolver {
    return &NQueensSolver{N: n}
}

func (s *NQueensSolver) Solve() [][]int {
    queens := make([]int, s.N) // queens[row] = column
    s.Solutions = nil
    s.backtrack(queens, 0)
    return s.Solutions
}

func (s *NQueensSolver) backtrack(queens []int, row int) {
    // ━━━ Base case: tất cả queens đã đặt → found solution ━━━
    if row == s.N {
        solution := make([]int, s.N)
        copy(solution, queens)
        s.Solutions = append(s.Solutions, solution)
        return
    }

    // ━━━ Try: đặt queen tại mỗi column trong row hiện tại ━━━
    for col := 0; col < s.N; col++ {
        if s.isSafe(queens, row, col) {
            queens[row] = col           // ← CHOOSE
            s.backtrack(queens, row+1)  // ← EXPLORE
            // queens[row] sẽ bị overwrite → implicit UNCHOOSE
        }
    }
}

// isSafe: check queen tại (row, col) không conflict với queens trước đó
func (s *NQueensSolver) isSafe(queens []int, row, col int) bool {
    for prevRow := 0; prevRow < row; prevRow++ {
        prevCol := queens[prevRow]
        // Same column
        if prevCol == col {
            return false
        }
        // Same diagonal (|row_diff| == |col_diff|)
        if abs(row-prevRow) == abs(col-prevCol) {
            return false
        }
    }
    return true
}

func abs(x int) int {
    if x < 0 {
        return -x
    }
    return x
}

func (s *NQueensSolver) PrintSolution(solution []int) {
    for _, col := range solution {
        for c := 0; c < s.N; c++ {
            if c == col {
                fmt.Print("♛ ")
            } else {
                fmt.Print("· ")
            }
        }
        fmt.Println()
    }
    fmt.Println()
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Sudoku Solver: fill 9×9 grid sao cho mỗi row, column, 3×3 box
// chứa 1-9 đúng 1 lần
//
// Backtracking:
// 1. Tìm ô trống
// 2. Thử 1-9
// 3. Check valid (row, col, box)
// 4. Nếu valid → recurse. Nếu stuck → backtrack
//
// Time: O(9^(n²)) worst, ~O(1) practice (heavy pruning)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type SudokuSolver struct {
    Board [9][9]int // 0 = empty
}

func (s *SudokuSolver) Solve() bool {
    row, col, found := s.findEmpty()
    if !found {
        return true // ← no empty cell → solved!
    }

    for num := 1; num <= 9; num++ {
        if s.isValid(row, col, num) {
            s.Board[row][col] = num  // CHOOSE

            if s.Solve() {           // EXPLORE
                return true
            }

            s.Board[row][col] = 0    // UNCHOOSE (backtrack)
        }
    }
    return false // no valid number → backtrack
}

func (s *SudokuSolver) findEmpty() (int, int, bool) {
    for r := 0; r < 9; r++ {
        for c := 0; c < 9; c++ {
            if s.Board[r][c] == 0 {
                return r, c, true
            }
        }
    }
    return 0, 0, false
}

func (s *SudokuSolver) isValid(row, col, num int) bool {
    // Check row
    for c := 0; c < 9; c++ {
        if s.Board[row][c] == num {
            return false
        }
    }
    // Check column
    for r := 0; r < 9; r++ {
        if s.Board[r][col] == num {
            return false
        }
    }
    // Check 3×3 box
    boxRow, boxCol := (row/3)*3, (col/3)*3
    for r := boxRow; r < boxRow+3; r++ {
        for c := boxCol; c < boxCol+3; c++ {
            if s.Board[r][c] == num {
                return false
            }
        }
    }
    return true
}

func (s *SudokuSolver) Print() {
    for r := 0; r < 9; r++ {
        if r%3 == 0 && r > 0 {
            fmt.Println("------+-------+------")
        }
        for c := 0; c < 9; c++ {
            if c%3 == 0 && c > 0 {
                fmt.Print("| ")
            }
            if s.Board[r][c] == 0 {
                fmt.Print(". ")
            } else {
                fmt.Printf("%d ", s.Board[r][c])
            }
        }
        fmt.Println()
    }
}

func exampleBacktracking() {
    // N-Queens
    solver := NewNQueensSolver(8)
    solutions := solver.Solve()
    fmt.Printf("8-Queens: %d solutions found\n", len(solutions)) // 92

    if len(solutions) > 0 {
        fmt.Println("First solution:")
        solver.PrintSolution(solutions[0])
    }

    // Sudoku
    sudoku := &SudokuSolver{
        Board: [9][9]int{
            {5, 3, 0, 0, 7, 0, 0, 0, 0},
            {6, 0, 0, 1, 9, 5, 0, 0, 0},
            {0, 9, 8, 0, 0, 0, 0, 6, 0},
            {8, 0, 0, 0, 6, 0, 0, 0, 3},
            {4, 0, 0, 8, 0, 3, 0, 0, 1},
            {7, 0, 0, 0, 2, 0, 0, 0, 6},
            {0, 6, 0, 0, 0, 0, 2, 8, 0},
            {0, 0, 0, 4, 1, 9, 0, 0, 5},
            {0, 0, 0, 0, 8, 0, 0, 7, 9},
        },
    }

    fmt.Println("\nSudoku (before):")
    sudoku.Print()

    if sudoku.Solve() {
        fmt.Println("\nSudoku (solved):")
        sudoku.Print()
    }
}
```

**Kết quả đạt được**:

- **N-Queens**: tìm tất cả 92 solutions cho 8-Queens.
- **Sudoku Solver**: giải bất kỳ valid Sudoku puzzle.
- **Backtracking template**: CHOOSE → EXPLORE → UNCHOOSE.

**Lưu ý**:

- **Pruning là key**: N-Queens check isSafe trước khi recurse → giảm search space drastically.
- **Sudoku optimization**: MRV (Minimum Remaining Values) — chọn ô có ít candidates nhất trước → nhanh hơn.
- **Constraint propagation**: kết hợp backtracking + constraint propagation → solving Sudoku trong ~ms.
- **Permutation/Combination problems**: backtracking là approach chuẩn.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | A* heuristic overestimate → non-optimal path | Đảm bảo h(n) ≤ actual cost (admissible) |
| 2 | KMP failure table sai → wrong matches | Unit test failure table carefully |
| 3 | Rabin-Karp hash collision → false positive | LUÔN verify string match sau hash match |
| 4 | Union-Find không path compression → O(n) Find | Luôn dùng path compression |
| 5 | Backtracking quên unchoose → state corruption | Template: choose → explore → unchoose |
| 6 | N-Queens chỉ check column, quên diagonal | Check column + both diagonals |
| 7 | A* open set quá lớn → OOM | Limit search space hoặc dùng IDA* |
| 8 | Rabin-Karp negative modulus | `if hash < 0 { hash += mod }` |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| KMP Visualization | [visualgo.net/stringmatch](https://visualgo.net/en/stringmatch) |
| A* Pathfinding | [redblobgames.com/pathfinding/a-star](https://www.redblobgames.com/pathfinding/a-star/introduction.html) |
| Backtracking | [wikipedia.org/wiki/Backtracking](https://en.wikipedia.org/wiki/Backtracking) |
| Union-Find | [cp-algorithms.com/dsu](https://cp-algorithms.com/data_structures/disjoint_set_union.html) |
| Rabin-Karp | [brilliant.org/rabin-karp](https://brilliant.org/wiki/rabin-karp-algorithm/) |

---

## ⑥ RECOMMEND

| Tool / Library | Mô tả | Khi nào dùng |
|----------------|--------|---------------|
| **`strings.Contains/Index`** | Go stdlib string search — Rabin-Karp internal | Production pattern matching |
| **`regexp`** | Regular expression — NFA/DFA | Complex pattern matching |
| **`container/heap`** | Priority queue — A* open set | Pathfinding, Dijkstra |
| **`github.com/beefsack/go-astar`** | A* library cho Go | Game dev, robotics |
| **Constraint solvers** | CSP solvers | Complex Sudoku, scheduling |

---

**Liên kết**: [← Dynamic Programming](./04-dynamic-programming.md) · [← README](./README.md) · [← Graph](./03-graph.md)
