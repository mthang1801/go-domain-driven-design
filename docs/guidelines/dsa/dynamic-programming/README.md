# 📐 Dynamic Programming — Tổng quan & Hướng dẫn

> **Mục đích**: 5 bài toán DP kinh điển: Fibonacci, LCS, 0/1 Knapsack, Matrix Chain, Coin Change.

---

## 📑 Mục lục

| # | Algorithm | Time | Space | Detail |
|---|-----------|------|-------|--------|
| 1 | **Fibonacci** | O(n) | O(1) | [→ 01-fibonacci.md](./01-fibonacci.md) |
| 2 | **LCS** | O(m×n) | O(m×n) | [→ 02-lcs.md](./02-lcs.md) |
| 3 | **0/1 Knapsack** | O(n×W) | O(n×W) | [→ 03-knapsack.md](./03-knapsack.md) |
| 4 | **Matrix Chain** | O(n³) | O(n²) | [→ 04-matrix-chain.md](./04-matrix-chain.md) |
| 5 | **Coin Change** | O(n×amount) | O(amount) | [→ 05-coin-change.md](./05-coin-change.md) |

---

## 🔑 DP Problem-Solving Framework

```text
  1. STATE:      dp[...] đại diện gì?
  2. BASE CASE:  dp[0] = ?, dp[1] = ?
  3. TRANSITION: dp[i] = f(dp[i-1], dp[i-2], ...)
  4. ANSWER:     dp[n] hoặc max/min dp[...]
  5. OPTIMIZE:   rolling array nếu dp[i] chỉ phụ thuộc dp[i-1]
```

## 🗺️ Top-down vs Bottom-up

| | Top-down (Memoization) | Bottom-up (Tabulation) |
|---|---|---|
| **Approach** | Recursion + cache | Iterative fill table |
| **Code** | Tự nhiên, dễ viết | Cần suy nghĩ order |
| **Stack** | O(n) recursion | No recursion |
| **Subproblems** | Chỉ tính cần thiết | Tính tất cả |

---

## ⑥ RECOMMEND

| Tool | Khi nào |
|------|---------|
| **`math/big`** | Fibonacci lớn (n > 93) |
| **Rolling array** | Space optimization |
| **`sync.Map`** | Concurrent memoization |

---

**Liên kết**: [← Graph](../graph/README.md) · [→ Important Algorithms](../important-algorithms/README.md) · [← DSA Overview](../README.md)
