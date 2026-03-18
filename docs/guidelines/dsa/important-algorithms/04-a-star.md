# ⭐ A* Search — Heuristic Pathfinding

> **Phân loại**: Informed Search, Best-first
> **Tóm tắt**: f(n) = g(n) + h(n). Dijkstra + heuristic → faster pathfinding.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(b^d) — depends on heuristic quality |
| **Space** | O(b^d) |
| **Optimal** | Yes, if h(n) ≤ actual cost (admissible) |
| **Complete** | Yes, if finite branching |
| **vs Dijkstra** | Dijkstra = A* with h=0 |

### f(n) = g(n) + h(n)

- **g(n)**: actual cost from start to n
- **h(n)**: estimated cost from n to goal (heuristic)
- **Admissible**: h(n) ≤ actual cost → optimal guaranteed

### Heuristics for Grid

| Heuristic | Formula | Grid type |
|-----------|---------|-----------|
| Manhattan | \|x₁-x₂\| + \|y₁-y₂\| | 4-directional |
| Euclidean | √((x₁-x₂)² + (y₁-y₂)²) | Any direction |
| Chebyshev | max(\|Δx\|, \|Δy\|) | 8-directional |

---

## ② GRAPH

```text
  Grid: . = free, # = wall, S = start, G = goal

  S . . # .     A* path (Manhattan heuristic):
  . # . # .     S → → ↓
  . # . . .            ↓ → → ↓
  . . . # G                   G
```

---

## ③ CODE

### Example 1: A* on Grid

```go
package algo

import "container/heap"

type Point struct{ X, Y int }

type AStarNode struct {
    Pos    Point
    G, H   float64
    Parent *AStarNode
}

func (n *AStarNode) F() float64 { return n.G + n.H }

type AStarPQ []*AStarNode
func (pq AStarPQ) Len() int            { return len(pq) }
func (pq AStarPQ) Less(i, j int) bool  { return pq[i].F() < pq[j].F() }
func (pq AStarPQ) Swap(i, j int)       { pq[i], pq[j] = pq[j], pq[i] }
func (pq *AStarPQ) Push(x interface{}) { *pq = append(*pq, x.(*AStarNode)) }
func (pq *AStarPQ) Pop() interface{} {
    old := *pq; n := len(old); item := old[n-1]; *pq = old[:n-1]; return item
}

func manhattan(a, b Point) float64 {
    dx, dy := a.X-b.X, a.Y-b.Y
    if dx < 0 { dx = -dx }
    if dy < 0 { dy = -dy }
    return float64(dx + dy)
}

func AStar(grid [][]int, start, goal Point) []Point {
    rows, cols := len(grid), len(grid[0])
    dirs := [][2]int{{0, 1}, {0, -1}, {1, 0}, {-1, 0}}

    openSet := &AStarPQ{}
    heap.Init(openSet)
    heap.Push(openSet, &AStarNode{Pos: start, G: 0, H: manhattan(start, goal)})

    gScore := map[Point]float64{start: 0}
    closed := map[Point]bool{}

    for openSet.Len() > 0 {
        curr := heap.Pop(openSet).(*AStarNode)
        if curr.Pos == goal {
            var path []Point
            for n := curr; n != nil; n = n.Parent {
                path = append([]Point{n.Pos}, path...)
            }
            return path
        }

        if closed[curr.Pos] { continue }
        closed[curr.Pos] = true

        for _, d := range dirs {
            next := Point{curr.Pos.X + d[0], curr.Pos.Y + d[1]}
            if next.X < 0 || next.X >= rows || next.Y < 0 || next.Y >= cols { continue }
            if grid[next.X][next.Y] == 1 || closed[next] { continue } // wall

            ng := curr.G + 1
            if g, ok := gScore[next]; !ok || ng < g {
                gScore[next] = ng
                heap.Push(openSet, &AStarNode{
                    Pos: next, G: ng, H: manhattan(next, goal), Parent: curr,
                })
            }
        }
    }
    return nil // no path
}
```

### Example 2: 8-Directional A*

```go
package algo

import (
    "container/heap"
    "math"
)

func chebyshev(a, b Point) float64 {
    dx := math.Abs(float64(a.X - b.X))
    dy := math.Abs(float64(a.Y - b.Y))
    return math.Max(dx, dy)
}

func AStar8Dir(grid [][]int, start, goal Point) []Point {
    rows, cols := len(grid), len(grid[0])
    dirs := [][2]int{{0,1},{0,-1},{1,0},{-1,0},{1,1},{1,-1},{-1,1},{-1,-1}}

    openSet := &AStarPQ{}
    heap.Init(openSet)
    heap.Push(openSet, &AStarNode{Pos: start, G: 0, H: chebyshev(start, goal)})

    gScore := map[Point]float64{start: 0}
    closed := map[Point]bool{}

    for openSet.Len() > 0 {
        curr := heap.Pop(openSet).(*AStarNode)
        if curr.Pos == goal {
            var path []Point
            for n := curr; n != nil; n = n.Parent {
                path = append([]Point{n.Pos}, path...)
            }
            return path
        }
        if closed[curr.Pos] { continue }
        closed[curr.Pos] = true

        for _, d := range dirs {
            next := Point{curr.Pos.X + d[0], curr.Pos.Y + d[1]}
            if next.X < 0 || next.X >= rows || next.Y < 0 || next.Y >= cols { continue }
            if grid[next.X][next.Y] == 1 || closed[next] { continue }

            cost := 1.0
            if d[0] != 0 && d[1] != 0 { cost = math.Sqrt(2) } // diagonal
            ng := curr.G + cost

            if g, ok := gScore[next]; !ok || ng < g {
                gScore[next] = ng
                heap.Push(openSet, &AStarNode{
                    Pos: next, G: ng, H: chebyshev(next, goal), Parent: curr,
                })
            }
        }
    }
    return nil
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Non-admissible heuristic → suboptimal | h(n) ≤ actual cost |
| 2 | Forget closed set → infinite loops | Track visited nodes |
| 3 | Memory for large maps | IDA* (iterative deepening) |

---

**Liên kết**: [← Rabin-Karp](./03-rabin-karp.md) · [→ Backtracking](./05-backtracking.md)
