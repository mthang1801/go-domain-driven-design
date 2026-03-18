# 🌲 Union-Find (Disjoint Set Union — DSU)

> **Phân loại**: Data Structure, Near O(1) amortized
> **Tóm tắt**: Quản lý tập hợp rời rạc — Union (gộp) + Find (tìm representative).

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Union** | O(α(n)) ≈ O(1) amortized |
| **Find** | O(α(n)) ≈ O(1) amortized |
| **Space** | O(n) |
| **Optimizations** | Path compression + Union by rank |

α(n) = inverse Ackermann function — grows EXTREMELY slow (α(2^65536) = 5).

### Use cases

- **Kruskal MST** — check cycle.
- **Connected components** — network connectivity.
- **Accounts merge** — group overlapping emails.
- **Image segmentation** — connected pixels.

---

## ② GRAPH

```text
  Union(1,2): {1,2}  {3}  {4,5}
  Union(3,4): {1,2}  {3,4,5}
  Union(2,4): {1,2,3,4,5}

  Path compression before:     After Find(5):
       1                          1
      / \                      / | \ \
     2   3                    2  3  4  5
         |
         4
         |
         5
```

---

## ③ CODE

### Example 1: Full Union-Find

```go
package algo

type UnionFind struct {
    parent []int
    rank   []int
    count  int // number of components
}

func NewUnionFind(n int) *UnionFind {
    p := make([]int, n)
    for i := range p { p[i] = i }
    return &UnionFind{parent: p, rank: make([]int, n), count: n}
}

// Find with path compression — near O(1)
func (uf *UnionFind) Find(x int) int {
    if uf.parent[x] != x {
        uf.parent[x] = uf.Find(uf.parent[x])
    }
    return uf.parent[x]
}

// Union by rank — near O(1)
func (uf *UnionFind) Union(x, y int) bool {
    rx, ry := uf.Find(x), uf.Find(y)
    if rx == ry { return false }

    if uf.rank[rx] < uf.rank[ry] { rx, ry = ry, rx }
    uf.parent[ry] = rx
    if uf.rank[rx] == uf.rank[ry] { uf.rank[rx]++ }
    uf.count--
    return true
}

func (uf *UnionFind) Connected(x, y int) bool {
    return uf.Find(x) == uf.Find(y)
}

func (uf *UnionFind) Components() int { return uf.count }
```

### Example 2: Weighted Union-Find

```go
package algo

// WeightedUF: Union-Find with weighted edges (size tracking)
type WeightedUF struct {
    parent []int
    size   []int
    count  int
}

func NewWeightedUF(n int) *WeightedUF {
    p := make([]int, n)
    s := make([]int, n)
    for i := range p { p[i] = i; s[i] = 1 }
    return &WeightedUF{p, s, n}
}

func (uf *WeightedUF) Find(x int) int {
    root := x
    for root != uf.parent[root] { root = uf.parent[root] }
    for x != root { // path compression
        next := uf.parent[x]
        uf.parent[x] = root
        x = next
    }
    return root
}

// Union by size: attach smaller tree to larger
func (uf *WeightedUF) Union(x, y int) bool {
    rx, ry := uf.Find(x), uf.Find(y)
    if rx == ry { return false }
    if uf.size[rx] < uf.size[ry] { rx, ry = ry, rx }
    uf.parent[ry] = rx
    uf.size[rx] += uf.size[ry]
    uf.count--
    return true
}

// ComponentSize: size of component containing x
func (uf *WeightedUF) ComponentSize(x int) int {
    return uf.size[uf.Find(x)]
}
```

### Example 3: Network Connectivity

```go
package algo

import "fmt"

func ExampleNetworkConnectivity() {
    n := 10 // 10 computers
    uf := NewUnionFind(n)

    connections := [][2]int{
        {0, 1}, {1, 2}, {3, 4}, {5, 6},
        {6, 7}, {7, 8}, {8, 9},
    }
    for _, c := range connections {
        uf.Union(c[0], c[1])
    }

    fmt.Println("Components:", uf.Components()) // 3
    fmt.Println("0-2 connected:", uf.Connected(0, 2)) // true
    fmt.Println("0-3 connected:", uf.Connected(0, 3)) // false

    // Merge networks
    uf.Union(2, 3)
    fmt.Println("After merge: 0-4 connected:", uf.Connected(0, 4)) // true
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | No path compression → O(n) | Always compress |
| 2 | No rank/size → degenerate tree | Union by rank/size |
| 3 | Forget to check `rx == ry` | Return false for same set |

---

**Liên kết**: [← README](./README.md) · [→ KMP](./02-kmp.md)
