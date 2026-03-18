# 🎒 0/1 Knapsack Problem

> **Phân loại**: 2D Grid DP, Optimization
> **Tóm tắt**: Chọn items sao cho tổng value max, tổng weight ≤ capacity. Mỗi item chọn 0 hoặc 1 lần.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(n × W) |
| **Space** | O(n × W) → optimize O(W) |
| **Transition** | `dp[i][w] = max(dp[i-1][w], dp[i-1][w-weight[i]] + value[i])` |
| **NP-Complete** | Pseudo-polynomial (exponential in bits of W) |

---

## ② GRAPH

```text
  Items: Phone(w=1,v=6), Tablet(w=2,v=10), Camera(w=3,v=12)
  Capacity = 5

       w→  0   1   2   3   4   5
  i=0     [0,  6,  6,  6,  6,  6]
  i=1     [0,  6, 10, 16, 16, 16]
  i=2     [0,  6, 10, 16, 18, 22] ← answer = 22 (Tablet+Camera)
```

---

## ③ CODE

### Example 1: Standard 0/1 Knapsack with Item Tracking

```go
package dp

import "fmt"

type Item struct {
    Weight int
    Value  int
    Name   string
}

func Knapsack01(items []Item, cap int) (int, []Item) {
    n := len(items)
    dp := make([][]int, n+1)
    for i := range dp { dp[i] = make([]int, cap+1) }

    for i := 1; i <= n; i++ {
        item := items[i-1]
        for w := 0; w <= cap; w++ {
            dp[i][w] = dp[i-1][w]
            if w >= item.Weight {
                if v := dp[i-1][w-item.Weight] + item.Value; v > dp[i][w] {
                    dp[i][w] = v
                }
            }
        }
    }

    // Backtrack selected items
    var selected []Item
    w := cap
    for i := n; i > 0; i-- {
        if dp[i][w] != dp[i-1][w] {
            selected = append(selected, items[i-1])
            w -= items[i-1].Weight
        }
    }
    return dp[n][cap], selected
}
```

### Example 2: Space Optimized — O(W)

```go
package dp

// ⚠ Duyệt w RIGHT-TO-LEFT → tránh chọn item nhiều lần
func Knapsack01Opt(items []Item, cap int) int {
    dp := make([]int, cap+1)
    for _, item := range items {
        for w := cap; w >= item.Weight; w-- { // RIGHT to LEFT!
            if v := dp[w-item.Weight] + item.Value; v > dp[w] {
                dp[w] = v
            }
        }
    }
    return dp[cap]
}
```

### Example 3: Unbounded Knapsack (mỗi item unlimited)

```go
package dp

// Left-to-right → item có thể chọn nhiều lần
func KnapsackUnbounded(items []Item, cap int) int {
    dp := make([]int, cap+1)
    for _, item := range items {
        for w := item.Weight; w <= cap; w++ { // LEFT to RIGHT!
            if v := dp[w-item.Weight] + item.Value; v > dp[w] {
                dp[w] = v
            }
        }
    }
    return dp[cap]
}
```

### Example 4: Fractional Knapsack — Greedy O(n log n)

```go
package dp

import "sort"

// Fractional: greedy sort by value/weight ratio
func KnapsackFractional(items []Item, cap int) float64 {
    type rItem struct {
        Item
        Ratio float64
    }
    ri := make([]rItem, len(items))
    for i, it := range items {
        ri[i] = rItem{it, float64(it.Value) / float64(it.Weight)}
    }
    sort.Slice(ri, func(i, j int) bool {
        return ri[i].Ratio > ri[j].Ratio
    })

    total := 0.0
    remain := float64(cap)
    for _, it := range ri {
        if float64(it.Weight) <= remain {
            total += float64(it.Value)
            remain -= float64(it.Weight)
        } else {
            total += it.Ratio * remain
            break
        }
    }
    return total
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | 0/1: left-to-right → item chọn nhiều lần | Right-to-left |
| 2 | Greedy cho 0/1 Knapsack | Greedy chỉ cho Fractional |
| 3 | Assume polynomial | Pseudo-polynomial O(nW) |

---

**Liên kết**: [← LCS](./02-lcs.md) · [→ Matrix Chain](./04-matrix-chain.md)
