# 🐇 Fibonacci — DP Foundation

> **Phân loại**: 1D Linear DP
> **Tóm tắt**: 4 approaches từ O(2ⁿ) → O(n)/O(1). Nền tảng tư duy DP.

---

## ① DEFINE

| Approach | Time | Space |
|----------|------|-------|
| Naive Recursion | O(2ⁿ) | O(n) stack |
| Memoization (Top-down) | O(n) | O(n) |
| Tabulation (Bottom-up) | O(n) | O(n) |
| Space Optimized | O(n) | O(1) ✅ |

---

## ② GRAPH

```text
  Naive fib(5):                    Bottom-up:
         fib(5)                    dp: [0, 1, 1, 2, 3, 5]
        /      \                        →  →  →  →  →
    fib(4)    fib(3)  ← duplicate!
    /    \     /   \
  fib(3) fib(2) ...                15 calls → 6 with memo → 5 iterations
```

---

## ③ CODE

### Example 1: Naive Recursion — O(2ⁿ) ❌

```go
func FibNaive(n int) int {
    if n <= 1 { return n }
    return FibNaive(n-1) + FibNaive(n-2)
}
```

### Example 2: Memoization — O(n)/O(n)

```go
func FibMemo(n int) int {
    memo := make(map[int]int)
    return fibHelper(n, memo)
}
func fibHelper(n int, memo map[int]int) int {
    if n <= 1 { return n }
    if v, ok := memo[n]; ok { return v }
    memo[n] = fibHelper(n-1, memo) + fibHelper(n-2, memo)
    return memo[n]
}
```

### Example 3: Tabulation — O(n)/O(n)

```go
func FibTab(n int) int {
    if n <= 1 { return n }
    dp := make([]int, n+1)
    dp[0], dp[1] = 0, 1
    for i := 2; i <= n; i++ {
        dp[i] = dp[i-1] + dp[i-2]
    }
    return dp[n]
}
```

### Example 4: Space Optimized — O(n)/O(1) ✅

```go
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Rolling variable: chỉ cần 2 biến prev
// dp[i] chỉ phụ thuộc dp[i-1] và dp[i-2]
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func FibOptimized(n int) int {
    if n <= 1 { return n }
    prev2, prev1 := 0, 1
    for i := 2; i <= n; i++ {
        curr := prev1 + prev2
        prev2 = prev1
        prev1 = curr
    }
    return prev1
}
```

### Example 5: Matrix Exponentiation — O(log n)

```go
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// [F(n+1), F(n)] = [[1,1],[1,0]]^n
// Matrix power by squaring → O(log n)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Matrix [2][2]int

func multiply(a, b Matrix) Matrix {
    return Matrix{
        {a[0][0]*b[0][0] + a[0][1]*b[1][0], a[0][0]*b[0][1] + a[0][1]*b[1][1]},
        {a[1][0]*b[0][0] + a[1][1]*b[1][0], a[1][0]*b[0][1] + a[1][1]*b[1][1]},
    }
}

func matPow(m Matrix, n int) Matrix {
    result := Matrix{{1, 0}, {0, 1}} // identity
    for n > 0 {
        if n%2 == 1 { result = multiply(result, m) }
        m = multiply(m, m)
        n /= 2
    }
    return result
}

func FibMatrix(n int) int {
    if n <= 1 { return n }
    base := Matrix{{1, 1}, {1, 0}}
    result := matPow(base, n-1)
    return result[0][0]
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | int overflow n > 93 | `math/big.Int` |
| 2 | Naive recursion cho n > 40 | Memo hoặc bottom-up |
| 3 | Quên base case dp[0], dp[1] | Handle explicitly |

---

**Liên kết**: [← README](./README.md) · [→ LCS](./02-lcs.md)
