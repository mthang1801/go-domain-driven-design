# 📐 Dynamic Programming — Quy hoạch Động

> **Phạm vi**: 5 bài toán DP kinh điển: Fibonacci, LCS, 0/1 Knapsack, Matrix Chain Multiplication, Coin Change.
> **Ngôn ngữ**: Go — với annotated comments chi tiết.

---

## ① DEFINE

### Bảng so sánh tổng quan

| Algorithm                  | Time         | Space     | Approach      | Subproblem type |
|----------------------------|-------------|-----------|---------------|-----------------|
| Fibonacci (DP)             | O(n)        | O(1)      | Bottom-up     | 1D linear       |
| LCS                        | O(m × n)    | O(m × n)  | Bottom-up     | 2D grid         |
| 0/1 Knapsack               | O(n × W)    | O(n × W)  | Bottom-up     | 2D grid         |
| Matrix Chain Multiplication| O(n³)       | O(n²)     | Bottom-up     | Interval        |
| Coin Change                | O(n × amount)| O(amount)| Bottom-up     | 1D linear       |

### Định nghĩa chính

- **Dynamic Programming (DP)**: kỹ thuật giải bài toán bằng cách chia thành subproblems chồng lấp, giải mỗi subproblem 1 lần, lưu kết quả để reuse.
- **Overlapping Subproblems**: cùng subproblem được tính nhiều lần → lưu (memoize) thay vì tính lại.
- **Optimal Substructure**: giải pháp tối ưu của bài toán lớn = tổ hợp giải pháp tối ưu của subproblems.
- **Top-down (Memoization)**: recursion + cache → "suy nghĩ tự nhiên", dễ code, có thể stack overflow.
- **Bottom-up (Tabulation)**: fill table từ base case → iterative, không stack overflow, thường nhanh hơn.
- **State**: biến số mô tả subproblem. Ví dụ: `dp[i]` = kết quả tối ưu cho i phần tử đầu tiên.
- **Transition**: công thức chuyển đổi giữa states. Ví dụ: `dp[i] = dp[i-1] + dp[i-2]` (Fibonacci).

### DP Problem-Solving Framework

```text
  1. Xác định STATE: dp[...] đại diện cho gì?
  2. Xác định BASE CASE: dp[0] = ?, dp[1] = ?
  3. Xác định TRANSITION: dp[i] = f(dp[i-1], dp[i-2], ...)
  4. Xác định ANSWER: dp[n] hoặc max/min dp[...]
  5. OPTIMIZE space nếu cần (rolling array)
```

---

## ② GRAPH

### Dynamic Programming — Top-down vs Bottom-up

```text
  Fibonacci(5) — Top-down (recursion tree, NO memoization):
                    fib(5)
                  /        \
              fib(4)       fib(3)     ← fib(3) tính 2 lần!
             /    \        /    \
          fib(3)  fib(2)  fib(2) fib(1)
          /   \
       fib(2) fib(1)

  Total calls: 15 → O(2ⁿ)

  Bottom-up (Tabulation):
  ┌────┬────┬────┬────┬────┬────┐
  │ i  │  0 │  1 │  2 │  3 │  4 │  5 │
  ├────┼────┼────┼────┼────┼────┤
  │dp[i]│ 0 │  1 │  1 │  2 │  3 │  5 │
  └────┴────┴────┴────┴────┴────┘
    →    →    →    →    →    →
  Fill left to right: O(n)
```

### 0/1 Knapsack — DP Table

```text
  Items: [(weight=1, value=6), (w=2, v=10), (w=3, v=12)]
  Capacity W = 5

  dp[i][w] = max value using items 0..i with capacity w

       w→  0   1   2   3   4   5
  i=0     [0,  6,  6,  6,  6,  6]   ← only item 0
  i=1     [0,  6, 10, 16, 16, 16]   ← items 0,1
  i=2     [0,  6, 10, 16, 18, 22]   ← items 0,1,2

  Answer: dp[2][5] = 22 (items 0 + 1 + 2: 6+10+12=28? No, w=1+2+3=6>5)
  Correction: item 0(v=6,w=1) + item 2(v=12,w=3) = 18, w=4 ✓
  Or: item 1(v=10,w=2) + item 2(v=12,w=3) = 22, w=5 ✓ ← best
```

---

## ③ CODE

### Example 1: Fibonacci — Recursion → Memo → Bottom-up → Space Optimized

**Mục tiêu**: 4 approaches cho Fibonacci — từ O(2ⁿ) recursive đến O(n) time O(1) space.

**Cần gì**: Go standard library.

**Có gì**: 4 implementations so sánh complexity.

```go
package dp

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 1. Naive Recursion — O(2ⁿ) time, O(n) stack
// ⚠ KHÔNG DÙNG — exponential time
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func FibNaive(n int) int {
    if n <= 1 {
        return n
    }
    return FibNaive(n-1) + FibNaive(n-2) // ← recalculate same values
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 2. Top-down Memoization — O(n) time, O(n) space
// Recursion + cache: mỗi fib(k) tính 1 lần
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func FibMemo(n int) int {
    memo := make(map[int]int)
    return fibMemoHelper(n, memo)
}

func fibMemoHelper(n int, memo map[int]int) int {
    if n <= 1 {
        return n
    }
    if val, ok := memo[n]; ok {
        return val // ← cache hit
    }
    memo[n] = fibMemoHelper(n-1, memo) + fibMemoHelper(n-2, memo)
    return memo[n]
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 3. Bottom-up Tabulation — O(n) time, O(n) space
// Fill table iteratively: base cases → answer
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func FibBottomUp(n int) int {
    if n <= 1 {
        return n
    }
    dp := make([]int, n+1)
    dp[0], dp[1] = 0, 1
    for i := 2; i <= n; i++ {
        dp[i] = dp[i-1] + dp[i-2]
    }
    return dp[n]
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 4. Space Optimized — O(n) time, O(1) space ✅ BEST
//
// Chỉ cần 2 biến prev: dp[i] chỉ phụ thuộc dp[i-1] và dp[i-2]
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func FibOptimized(n int) int {
    if n <= 1 {
        return n
    }
    prev2, prev1 := 0, 1 // dp[i-2], dp[i-1]
    for i := 2; i <= n; i++ {
        current := prev1 + prev2
        prev2 = prev1
        prev1 = current
    }
    return prev1
}
```

**Kết quả đạt được**:

- **4 approaches**: Naive O(2ⁿ) → Memo O(n)/O(n) → Bottom-up O(n)/O(n) → Optimized O(n)/O(1).
- **Space optimization pattern**: nếu dp[i] chỉ phụ thuộc dp[i-1], dp[i-2] → chỉ cần 2 biến.

**Lưu ý**:

- **Rolling array trick**: áp dụng bất kỳ DP nào mà state chỉ phụ thuộc row trước.
- **Large Fibonacci**: int overflow → dùng `big.Int` cho n > 93.
- **Matrix exponentiation**: O(log n) — nhưng constant factor lớn, chỉ tốt cho n rất lớn.

---

### Example 2: Longest Common Subsequence (LCS)

**Mục tiêu**: Tìm longest common subsequence của 2 strings — nền tảng cho diff tools, DNA alignment.

**Cần gì**: Go standard library.

**Có gì**: 2 strings → DP table → length + reconstruct LCS.

```go
package dp

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LCS: Longest Common Subsequence
//
// Subsequence: giữ thứ tự, KHÔNG cần liên tiếp
// "ABCDE" & "ACE" → LCS = "ACE" (length 3)
//
// State: dp[i][j] = length of LCS of s1[0..i-1] và s2[0..j-1]
// Transition:
//   if s1[i-1] == s2[j-1]: dp[i][j] = dp[i-1][j-1] + 1  ← match
//   else: dp[i][j] = max(dp[i-1][j], dp[i][j-1])         ← skip 1
//
// Time: O(m × n)
// Space: O(m × n) — có thể optimize O(min(m,n))
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func LCS(s1, s2 string) (int, string) {
    m, n := len(s1), len(s2)
    dp := make([][]int, m+1)
    for i := range dp {
        dp[i] = make([]int, n+1)
    }

    // Fill DP table
    for i := 1; i <= m; i++ {
        for j := 1; j <= n; j++ {
            if s1[i-1] == s2[j-1] {
                dp[i][j] = dp[i-1][j-1] + 1 // match → extend LCS
            } else {
                dp[i][j] = max(dp[i-1][j], dp[i][j-1]) // skip
            }
        }
    }

    // Reconstruct LCS string (backtrack từ dp[m][n])
    lcs := make([]byte, 0, dp[m][n])
    i, j := m, n
    for i > 0 && j > 0 {
        if s1[i-1] == s2[j-1] {
            lcs = append([]byte{s1[i-1]}, lcs...) // prepend
            i--
            j--
        } else if dp[i-1][j] > dp[i][j-1] {
            i-- // came from top
        } else {
            j-- // came from left
        }
    }

    return dp[m][n], string(lcs)
}

func max(a, b int) int {
    if a > b {
        return a
    }
    return b
}

func exampleLCS() {
    length, lcs := LCS("ABCBDAB", "BDCABA")
    fmt.Printf("LCS length: %d, LCS: %s\n", length, lcs)
    // LCS length: 4, LCS: BCBA

    // Real-world: diff tool
    length2, lcs2 := LCS("hello world", "hello golang")
    fmt.Printf("LCS: '%s' (length %d)\n", lcs2, length2)
    // LCS: 'hello ol' (length 8)
}
```

**Kết quả đạt được**:

- **LCS length + reconstruct** — backtrack từ DP table.
- **Nền tảng cho diff tools**: `git diff`, `diff`, DNA alignment đều dùng LCS.

**Lưu ý**:

- **Space optimization**: chỉ cần 2 rows (rolling array) → O(min(m,n)) space. Nhưng KHÔNG thể reconstruct.
- **Subsequence ≠ Substring**: subsequence không cần liên tiếp, substring phải liên tiếp.
- **Multiple LCS**: có thể có nhiều LCS cùng length — backtracking khác nhau cho LCS khác nhau.

---

### Example 3: 0/1 Knapsack Problem

**Mục tiêu**: Chọn items vào knapsack sao cho tổng value lớn nhất, tổng weight ≤ capacity.

**Cần gì**: Go standard library.

**Có gì**: Items (weight, value) + capacity → DP → max value + which items.

```go
package dp

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Knapsack01: 0/1 Knapsack Problem
//
// Bài toán: N items, mỗi item có weight và value.
//           Knapsack capacity = W.
//           Chọn subset items → max value, tổng weight ≤ W.
//           Mỗi item chỉ chọn 0 hoặc 1 lần (0/1).
//
// State: dp[i][w] = max value dùng items 0..i-1 với capacity w
// Transition:
//   Không chọn item i: dp[i][w] = dp[i-1][w]
//   Chọn item i (nếu w >= weight[i]):
//     dp[i][w] = dp[i-1][w-weight[i]] + value[i]
//   dp[i][w] = max(chọn, không chọn)
//
// Time: O(n × W)
// Space: O(n × W) → optimize O(W)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Item struct {
    Weight int
    Value  int
    Name   string
}

func Knapsack01(items []Item, capacity int) (int, []Item) {
    n := len(items)
    dp := make([][]int, n+1)
    for i := range dp {
        dp[i] = make([]int, capacity+1)
    }

    // Fill DP table
    for i := 1; i <= n; i++ {
        item := items[i-1]
        for w := 0; w <= capacity; w++ {
            dp[i][w] = dp[i-1][w] // không chọn item i

            if w >= item.Weight {
                // Chọn item i
                withItem := dp[i-1][w-item.Weight] + item.Value
                if withItem > dp[i][w] {
                    dp[i][w] = withItem
                }
            }
        }
    }

    // Backtrack: tìm items đã chọn
    var selected []Item
    w := capacity
    for i := n; i > 0; i-- {
        if dp[i][w] != dp[i-1][w] {
            selected = append(selected, items[i-1])
            w -= items[i-1].Weight
        }
    }

    return dp[n][capacity], selected
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Knapsack01Optimized: Space O(W) — rolling array
// ⚠ Duyệt w từ PHẢI qua TRÁI để tránh dùng lại item
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func Knapsack01Optimized(items []Item, capacity int) int {
    dp := make([]int, capacity+1)

    for _, item := range items {
        // ⚠ Duyệt từ capacity → item.Weight (RIGHT to LEFT)
        // Nếu left to right: item bị chọn nhiều lần → Unbounded Knapsack
        for w := capacity; w >= item.Weight; w-- {
            withItem := dp[w-item.Weight] + item.Value
            if withItem > dp[w] {
                dp[w] = withItem
            }
        }
    }
    return dp[capacity]
}

func exampleKnapsack() {
    items := []Item{
        {Weight: 1, Value: 6, Name: "📱 Phone"},
        {Weight: 2, Value: 10, Name: "💻 Tablet"},
        {Weight: 3, Value: 12, Name: "📷 Camera"},
        {Weight: 5, Value: 20, Name: "🎮 Console"},
    }

    maxValue, selected := Knapsack01(items, 5)
    fmt.Printf("Max value: %d\n", maxValue)
    for _, item := range selected {
        fmt.Printf("  %s (w=%d, v=%d)\n", item.Name, item.Weight, item.Value)
    }
}
```

**Kết quả đạt được**:

- **0/1 Knapsack** — full DP table + backtrack items.
- **Space optimized** — O(W) rolling array.
- **Right-to-left iteration** — critical cho 0/1 (vs left-to-right cho unbounded).

**Lưu ý**:

- **0/1 vs Unbounded**: 0/1 = mỗi item 1 lần (right→left), Unbounded = unlimited (left→right).
- **Pseudo-polynomial**: O(nW) — polynomial trong n nhưng exponential trong bit-length of W.
- **NP-Complete**: không có polynomial algorithm chính xác cho general case.
- **Fractional Knapsack**: greedy (sort by value/weight ratio) → O(n log n).

---

### Example 4: Matrix Chain Multiplication

**Mục tiêu**: Tìm thứ tự nhân ma trận tối ưu (minimize số phép nhân scalar).

**Cần gì**: Go standard library.

**Có gì**: Dimensions → DP interval → optimal parenthesization.

```go
package dp

import (
    "fmt"
    "math"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MatrixChainOrder: tìm cách đặt ngoặc tối ưu cho nhân ma trận
//
// Bài toán: nhân A1 × A2 × ... × An
// Dimensions: dims = [d0, d1, d2, ..., dn]
//   Ai = matrix dims[i-1] × dims[i]
//
// (A × B) khác thứ tự → cùng kết quả, KHÁC cost:
//   A(10×30) × B(30×5) × C(5×60):
//   (AB)C = 10×30×5 + 10×5×60 = 1500 + 3000 = 4500
//   A(BC) = 30×5×60 + 10×30×60 = 9000 + 18000 = 27000
//   → (AB)C gấp 6x tốt hơn!
//
// State: dp[i][j] = min cost nhân Ai × ... × Aj
// Transition: dp[i][j] = min(dp[i][k] + dp[k+1][j] + dims[i-1]*dims[k]*dims[j])
//             for k = i to j-1
//
// Time: O(n³)
// Space: O(n²)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func MatrixChainOrder(dims []int) (int, string) {
    n := len(dims) - 1 // number of matrices
    if n <= 1 {
        return 0, "A1"
    }

    // dp[i][j] = min multiplications for matrices i..j
    dp := make([][]int, n+1)
    split := make([][]int, n+1) // split point for reconstruction
    for i := range dp {
        dp[i] = make([]int, n+1)
        split[i] = make([]int, n+1)
    }

    // Fill by chain length (l = 2, 3, ..., n)
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

    // Reconstruct optimal parenthesization
    parens := buildParens(split, 1, n)
    return dp[1][n], parens
}

func buildParens(split [][]int, i, j int) string {
    if i == j {
        return fmt.Sprintf("A%d", i)
    }
    k := split[i][j]
    left := buildParens(split, i, k)
    right := buildParens(split, k+1, j)
    return fmt.Sprintf("(%s × %s)", left, right)
}

func exampleMatrixChain() {
    // 4 matrices: A1(10×30), A2(30×5), A3(5×60), A4(60×10)
    dims := []int{10, 30, 5, 60, 10}
    minCost, parens := MatrixChainOrder(dims)
    fmt.Printf("Min cost: %d\n", minCost)
    fmt.Printf("Optimal: %s\n", parens)
    // Min cost: 4500 (varies based on optimal split)
    // Optimal: ((A1 × A2) × (A3 × A4))
}
```

**Kết quả đạt được**:

- **Optimal parenthesization** — minimize scalar multiplications.
- **Interval DP pattern**: `dp[i][j]` — subproblem trên interval `[i, j]`.
- **Reconstruct**: split table → build parenthesization string.

**Lưu ý**:

- **O(n³)**: 3 nested loops — chỉ practical cho n < 500.
- **Interval DP**: pattern phổ biến — burst balloons, palindrome partitioning.
- **Catalan number**: số cách parenthesization = C(n-1) — exponential without DP.

---

### Example 5: Coin Change Problem

**Mục tiêu**: Tìm số đồng xu tối thiểu để tạo thành amount. Variant: đếm số cách tạo amount.

**Cần gì**: Go standard library.

**Có gì**: Coin denominations + target amount → DP → min coins + all ways.

```go
package dp

import (
    "fmt"
    "math"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CoinChangeMin: số đồng xu tối thiểu để tạo amount
//
// State: dp[a] = min coins cần cho amount a
// Base: dp[0] = 0 (0 xu cho amount 0)
// Transition: dp[a] = min(dp[a - coin] + 1) for each coin
//
// Time: O(n × amount)
// Space: O(amount)
//
// Ví dụ: coins = [1, 5, 10], amount = 12
//   dp[12] = min(dp[11]+1, dp[7]+1, dp[2]+1) = min(3, 2+1, 2+1) = 3
//   Answer: 10 + 1 + 1 = 3 coins
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CoinChangeMin(coins []int, amount int) int {
    dp := make([]int, amount+1)
    for i := range dp {
        dp[i] = math.MaxInt64 // initialize "impossible"
    }
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

    if dp[amount] == math.MaxInt64 {
        return -1 // impossible
    }
    return dp[amount]
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CoinChangeCount: đếm SỐ CÁCH tạo amount
//
// State: dp[a] = số cách tạo amount a
// Base: dp[0] = 1 (1 cách cho amount 0: chọn 0 xu)
// Transition: dp[a] += dp[a - coin] for each coin
//
// ⚠ Order of loops matters:
//   coins outer → combinations (không phân biệt thứ tự): [1,5] = [5,1]
//   amount outer → permutations (phân biệt thứ tự): [1,5] ≠ [5,1]
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CoinChangeCount(coins []int, amount int) int {
    dp := make([]int, amount+1)
    dp[0] = 1

    // ━━━ Coins outer → combinations ━━━
    for _, coin := range coins {
        for a := coin; a <= amount; a++ {
            dp[a] += dp[a-coin]
        }
    }
    return dp[amount]
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CoinChangeWithTrace: reconstruct which coins used
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func CoinChangeWithTrace(coins []int, amount int) (int, []int) {
    dp := make([]int, amount+1)
    usedCoin := make([]int, amount+1) // which coin was used at each step
    for i := range dp {
        dp[i] = math.MaxInt64
    }
    dp[0] = 0

    for a := 1; a <= amount; a++ {
        for _, coin := range coins {
            if coin <= a && dp[a-coin] != math.MaxInt64 {
                if dp[a-coin]+1 < dp[a] {
                    dp[a] = dp[a-coin] + 1
                    usedCoin[a] = coin
                }
            }
        }
    }

    if dp[amount] == math.MaxInt64 {
        return -1, nil
    }

    // Reconstruct
    var result []int
    for a := amount; a > 0; a -= usedCoin[a] {
        result = append(result, usedCoin[a])
    }
    return dp[amount], result
}

func exampleCoinChange() {
    coins := []int{1, 5, 10, 25}

    // Min coins
    minCoins := CoinChangeMin(coins, 36)
    fmt.Printf("Min coins for 36: %d\n", minCoins) // 3 (25+10+1)

    // Count ways
    ways := CoinChangeCount(coins, 10)
    fmt.Printf("Ways to make 10: %d\n", ways) // 4 ways

    // With trace
    minC, used := CoinChangeWithTrace(coins, 36)
    fmt.Printf("Min coins: %d, used: %v\n", minC, used)
    // used: [1 10 25]
}
```

**Kết quả đạt được**:

- **Min coins** — O(n × amount).
- **Count combinations** — coins outer loop.
- **Reconstruct** — trace which coins used.

**Lưu ý**:

- **Combinations vs Permutations**: loop order matters! Coins outer = combinations.
- **Greedy KHÔNG luôn đúng**: coins = [1, 3, 4], amount = 6 → greedy: 4+1+1=3, DP: 3+3=2 ✓.
- **Unbounded Knapsack**: Coin Change = Unbounded Knapsack variant (mỗi coin unlimited).

---

### Example 6: Combo — DP + Goroutines: Parallel LCS Matrix

**Mục tiêu**: Tính LCS cho nhiều cặp strings đồng thời bằng errgroup — phù hợp bulk text comparison.

**Cần gì**: Go standard library, `golang.org/x/sync/errgroup`.

**Có gì**: N cặp strings → errgroup parallel LCS → results.

```go
package dp

import (
    "context"
    "fmt"
    "time"

    "golang.org/x/sync/errgroup"
)

type LCSResult struct {
    S1     string
    S2     string
    Length int
    LCS    string
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// ParallelLCS: compute LCS cho nhiều cặp strings đồng thời
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func ParallelLCS(pairs [][2]string, maxWorkers int) ([]LCSResult, error) {
    results := make([]LCSResult, len(pairs))

    eg, ctx := errgroup.WithContext(context.Background())
    eg.SetLimit(maxWorkers)

    for i, pair := range pairs {
        idx := i
        s1, s2 := pair[0], pair[1]

        eg.Go(func() error {
            select {
            case <-ctx.Done():
                return ctx.Err()
            default:
            }

            length, lcs := LCS(s1, s2)
            results[idx] = LCSResult{
                S1: s1, S2: s2,
                Length: length, LCS: lcs,
            }
            return nil
        })
    }

    if err := eg.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}

func exampleParallelLCS() {
    pairs := [][2]string{
        {"ALGORITHM", "ALTRUISTIC"},
        {"DYNAMIC", "DYNASTY"},
        {"PROGRAMMING", "PROGRESS"},
        {"KNAPSACK", "SNACK"},
        {"FIBONACCI", "BINARY"},
    }

    start := time.Now()
    results, _ := ParallelLCS(pairs, 4)
    elapsed := time.Since(start)

    for _, r := range results {
        fmt.Printf("  LCS(\"%s\", \"%s\") = \"%s\" (len=%d)\n",
            r.S1, r.S2, r.LCS, r.Length)
    }
    fmt.Printf("Total time: %v (parallel)\n", elapsed)
}
```

**Kết quả đạt được**:

- **Parallel LCS computation** — N cặp strings xử lý đồng thời.
- **errgroup** — concurrent control + error propagation.
- **Real use case**: plagiarism detection, DNA sequence alignment, diff tools.

**Lưu ý**:

- LCS cho strings dài (> 10K chars) → memory O(m×n) → space-optimize hoặc dùng Hirschberg algorithm.
- Kết hợp goroutines chi tiết hơn — xem [goroutines/05-errgroup](../goroutines/05-errgroup.md).

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Top-down recursion quá sâu → stack overflow | Dùng bottom-up iterative |
| 2 | Knapsack 0/1: duyệt w left→right → item chọn nhiều lần | Phải right→left cho 0/1 |
| 3 | Coin Change: greedy thay DP → kết quả sai | Greedy không optimal cho mọi coin set |
| 4 | LCS space O(m×n) cho strings dài | Rolling array O(min(m,n)) |
| 5 | DP state thiếu dimension → wrong answer | Xác định rõ state cần bao nhiêu chiều |
| 6 | Integer overflow trong DP table | Dùng int64 hoặc big.Int |
| 7 | Quên base case → panic index out of range | Luôn handle dp[0], dp[1] |

---

## ⑤ REF

| Resource | Link |
|----------|------|
| DP Patterns | [patterns.substack.com/p/dp-patterns](https://patterns.substack.com/p/dp-patterns) |
| CSES Problem Set — DP | [cses.fi/problemset](https://cses.fi/problemset/) |
| Leetcode DP Problems | [leetcode.com/tag/dynamic-programming](https://leetcode.com/tag/dynamic-programming/) |
| Visualgo — DP | [visualgo.net/dp](https://visualgo.net/en/dp) |

---

## ⑥ RECOMMEND

| Tool / Library | Mô tả | Khi nào dùng |
|----------------|--------|---------------|
| **`math/big`** | Arbitrary precision integers | Fibonacci lớn (n > 93) |
| **Memoization pattern** | `map[string]int` cache | Top-down DP |
| **`sync.Map`** | Thread-safe memo cache | Concurrent DP |
| **Generic DP utilities** | Build your own | Reusable DP patterns |

---

**Liên kết**: [← Graph](./03-graph.md) · [→ Important Algorithms](./05-important-algorithms.md) · [← README](./README.md)
