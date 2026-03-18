# 🪙 Coin Change Problem

> **Phân loại**: 1D DP, Unbounded Knapsack variant
> **Tóm tắt**: Min coins / count ways để tạo amount từ coin denominations.

---

## ① DEFINE

| Variant | Time | Space | Mô tả |
|---------|------|-------|--------|
| **Min Coins** | O(n×amount) | O(amount) | Số xu tối thiểu |
| **Count Ways** | O(n×amount) | O(amount) | Tổng số cách |

---

## ② GRAPH

```text
  coins = [1, 5, 10], amount = 12

  dp: [0, 1, 2, 3, 4, 1, 2, 3, 4, 5, 1, 2, 3]
       ↑                 ↑              ↑
      0xu               5+1=1xu        10+1+1=3xu

  Answer: dp[12] = 3 (10 + 1 + 1)
```

---

## ③ CODE

### Example 1: Min Coins

```go
package dp

import "math"

func CoinChangeMin(coins []int, amount int) int {
    dp := make([]int, amount+1)
    for i := range dp { dp[i] = math.MaxInt64 }
    dp[0] = 0

    for a := 1; a <= amount; a++ {
        for _, coin := range coins {
            if coin <= a && dp[a-coin] != math.MaxInt64 {
                if dp[a-coin]+1 < dp[a] {
                    dp[a] = dp[a-coin] + 1
                }
            }
        }
    }
    if dp[amount] == math.MaxInt64 { return -1 }
    return dp[amount]
}
```

### Example 2: Count Ways (Combinations)

```go
package dp

// ⚠ Coins outer loop → combinations (không phân biệt order)
func CoinChangeCount(coins []int, amount int) int {
    dp := make([]int, amount+1)
    dp[0] = 1
    for _, coin := range coins { // coins outer → combos
        for a := coin; a <= amount; a++ {
            dp[a] += dp[a-coin]
        }
    }
    return dp[amount]
}

// Amount outer → permutations (phân biệt order)
func CoinChangePermutations(coins []int, amount int) int {
    dp := make([]int, amount+1)
    dp[0] = 1
    for a := 1; a <= amount; a++ { // amount outer → perms
        for _, coin := range coins {
            if coin <= a { dp[a] += dp[a-coin] }
        }
    }
    return dp[amount]
}
```

### Example 3: Min Coins with Trace

```go
package dp

import "math"

func CoinChangeTrace(coins []int, amount int) (int, []int) {
    dp := make([]int, amount+1)
    used := make([]int, amount+1)
    for i := range dp { dp[i] = math.MaxInt64 }
    dp[0] = 0

    for a := 1; a <= amount; a++ {
        for _, coin := range coins {
            if coin <= a && dp[a-coin] != math.MaxInt64 && dp[a-coin]+1 < dp[a] {
                dp[a] = dp[a-coin] + 1
                used[a] = coin
            }
        }
    }

    if dp[amount] == math.MaxInt64 { return -1, nil }

    var result []int
    for a := amount; a > 0; a -= used[a] {
        result = append(result, used[a])
    }
    return dp[amount], result
}
```

### Example 4: Greedy Fails — Why DP is needed

```go
package dp

import "fmt"

// Greedy: always pick largest coin first
// FAILS for some coin sets!
func CoinChangeGreedy(coins []int, amount int) int {
    // Sort DESC
    sorted := make([]int, len(coins))
    copy(sorted, coins)
    for i := 0; i < len(sorted)-1; i++ {
        for j := i+1; j < len(sorted); j++ {
            if sorted[j] > sorted[i] { sorted[i], sorted[j] = sorted[j], sorted[i] }
        }
    }

    count := 0
    for _, coin := range sorted {
        count += amount / coin
        amount %= coin
    }
    if amount != 0 { return -1 }
    return count
}

func main() {
    // Greedy works: coins = [1, 5, 10, 25]
    fmt.Println("Greedy [1,5,10,25] for 36:", CoinChangeGreedy([]int{1, 5, 10, 25}, 36)) // 3

    // Greedy FAILS: coins = [1, 3, 4]
    fmt.Println("Greedy [1,3,4] for 6:", CoinChangeGreedy([]int{1, 3, 4}, 6)) // 3 (4+1+1) ❌
    fmt.Println("DP     [1,3,4] for 6:", CoinChangeMin([]int{1, 3, 4}, 6))    // 2 (3+3) ✅
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Greedy cho coin change | Greedy chỉ đúng cho canonical coin sets |
| 2 | Combos vs Perms: loop order | Coins outer = combos, Amount outer = perms |
| 3 | Forget `dp[a-coin] != MaxInt` check | Guard overflow |

---

**Liên kết**: [← Matrix Chain](./04-matrix-chain.md) · [← README](./README.md)
