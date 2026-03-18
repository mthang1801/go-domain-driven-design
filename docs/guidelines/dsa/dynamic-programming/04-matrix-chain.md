# 🔢 Matrix Chain Multiplication

> **Phân loại**: Interval DP
> **Tóm tắt**: Tìm thứ tự nhân ma trận tối ưu (minimize scalar multiplications).

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(n³) |
| **Space** | O(n²) |
| **Transition** | `dp[i][j] = min(dp[i][k] + dp[k+1][j] + dims[i-1]*dims[k]*dims[j])` for k∈[i,j) |
| **Pattern** | Interval DP — subproblems on intervals [i, j] |

---

## ② GRAPH

```text
  A(10×30) × B(30×5) × C(5×60):

  (AB)C = 10×30×5 + 10×5×60 = 1500 + 3000 = 4500 ✓
  A(BC) = 30×5×60 + 10×30×60 = 9000 + 18000 = 27000 ✗

  → (AB)C is 6x better!
```

---

## ③ CODE

### Example 1: Standard Matrix Chain Order

```go
package dp

import (
    "fmt"
    "math"
)

func MatrixChainOrder(dims []int) (int, string) {
    n := len(dims) - 1
    if n <= 1 { return 0, "A1" }

    dp := make([][]int, n+1)
    split := make([][]int, n+1)
    for i := range dp {
        dp[i] = make([]int, n+1)
        split[i] = make([]int, n+1)
    }

    for l := 2; l <= n; l++ { // chain length
        for i := 1; i <= n-l+1; i++ {
            j := i + l - 1
            dp[i][j] = math.MaxInt64
            for k := i; k < j; k++ {
                cost := dp[i][k] + dp[k+1][j] + dims[i-1]*dims[k]*dims[j]
                if cost < dp[i][j] {
                    dp[i][j] = cost
                    split[i][j] = k
                }
            }
        }
    }
    return dp[1][n], buildParens(split, 1, n)
}

func buildParens(split [][]int, i, j int) string {
    if i == j { return fmt.Sprintf("A%d", i) }
    k := split[i][j]
    return fmt.Sprintf("(%s × %s)", buildParens(split, i, k), buildParens(split, k+1, j))
}
```

### Example 2: Memoization Version

```go
package dp

import "math"

func MatrixChainMemo(dims []int) int {
    n := len(dims) - 1
    memo := make(map[[2]int]int)
    return mcmHelper(dims, 1, n, memo)
}

func mcmHelper(dims []int, i, j int, memo map[[2]int]int) int {
    if i == j { return 0 }
    if v, ok := memo[[2]int{i, j}]; ok { return v }

    best := math.MaxInt64
    for k := i; k < j; k++ {
        cost := mcmHelper(dims, i, k, memo) + mcmHelper(dims, k+1, j, memo) + dims[i-1]*dims[k]*dims[j]
        if cost < best { best = cost }
    }
    memo[[2]int{i, j}] = best
    return best
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Confuse `dims[i-1]` vs `dims[i]` | Matrix i has dims[i-1]×dims[i] |
| 2 | O(n³) too slow for n > 500 | Hu-Shing algorithm O(n log n) |
| 3 | Forget to fill by chain length | l=2,3,...,n order |

---

**Liên kết**: [← Knapsack](./03-knapsack.md) · [→ Coin Change](./05-coin-change.md)
