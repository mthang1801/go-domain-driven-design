# 🔗 LCS — Longest Common Subsequence

> **Phân loại**: 2D Grid DP
> **Tóm tắt**: Tìm longest common subsequence của 2 strings. Nền tảng cho diff tools, DNA alignment.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(m × n) |
| **Space** | O(m × n) → optimize O(min(m,n)) |
| **Transition** | match: `dp[i][j]=dp[i-1][j-1]+1`, skip: `max(dp[i-1][j], dp[i][j-1])` |

Subsequence ≠ Substring: subsequence không cần liên tiếp.

---

## ② GRAPH

```text
  s1 = "ABCBDAB"    s2 = "BDCABA"
  LCS = "BCBA" (length 4)

       ""  B  D  C  A  B  A
  ""  [ 0  0  0  0  0  0  0 ]
  A   [ 0  0  0  0  1  1  1 ]
  B   [ 0  1  1  1  1  2  2 ]
  C   [ 0  1  1  2  2  2  2 ]
  B   [ 0  1  1  2  2  3  3 ]
  D   [ 0  1  2  2  2  3  3 ]
  A   [ 0  1  2  2  3  3  4 ]
  B   [ 0  1  2  2  3  4  4 ]
```

---

## ③ CODE

### Example 1: Standard LCS with Reconstruction

```go
package dp

func LCS(s1, s2 string) (int, string) {
    m, n := len(s1), len(s2)
    dp := make([][]int, m+1)
    for i := range dp { dp[i] = make([]int, n+1) }

    for i := 1; i <= m; i++ {
        for j := 1; j <= n; j++ {
            if s1[i-1] == s2[j-1] {
                dp[i][j] = dp[i-1][j-1] + 1
            } else {
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
            }
        }
    }

    // Reconstruct
    lcs := make([]byte, 0, dp[m][n])
    i, j := m, n
    for i > 0 && j > 0 {
        if s1[i-1] == s2[j-1] {
            lcs = append([]byte{s1[i-1]}, lcs...)
            i--; j--
        } else if dp[i-1][j] > dp[i][j-1] {
            i--
        } else {
            j--
        }
    }
    return dp[m][n], string(lcs)
}

func max(a, b int) int { if a > b { return a }; return b }
```

### Example 2: Space Optimized — Rolling Array

```go
package dp

// LCSLength: O(min(m,n)) space — chỉ cần 2 rows
func LCSLength(s1, s2 string) int {
    m, n := len(s1), len(s2)
    if m < n { s1, s2 = s2, s1; m, n = n, m } // s2 shorter

    prev := make([]int, n+1)
    curr := make([]int, n+1)

    for i := 1; i <= m; i++ {
        for j := 1; j <= n; j++ {
            if s1[i-1] == s2[j-1] {
                curr[j] = prev[j-1] + 1
            } else {
                curr[j] = max(prev[j], curr[j-1])
            }
        }
        prev, curr = curr, prev
        for k := range curr { curr[k] = 0 }
    }
    return prev[n]
}
```

### Example 3: Diff Tool — LCS applied

```go
package dp

import "fmt"

// Diff: compute diff between 2 strings using LCS
func Diff(old, new string) {
    _, lcs := LCS(old, new)
    li := 0
    for _, c := range old {
        if li < len(lcs) && byte(c) == lcs[li] {
            fmt.Printf("  %c\n", c) // unchanged
            li++
        } else {
            fmt.Printf("- %c\n", c) // removed
        }
    }
    li = 0
    for _, c := range new {
        if li < len(lcs) && byte(c) == lcs[li] {
            li++ // skip (already printed)
        } else {
            fmt.Printf("+ %c\n", c) // added
        }
    }
}
```

### Example 4: Parallel LCS — errgroup

```go
package dp

import (
    "context"
    "golang.org/x/sync/errgroup"
)

type LCSResult struct {
    S1, S2 string
    Length int
    LCS    string
}

func ParallelLCS(pairs [][2]string, workers int) ([]LCSResult, error) {
    results := make([]LCSResult, len(pairs))
    eg, ctx := errgroup.WithContext(context.Background())
    eg.SetLimit(workers)

    for i, pair := range pairs {
        idx, s1, s2 := i, pair[0], pair[1]
        eg.Go(func() error {
            select {
            case <-ctx.Done(): return ctx.Err()
            default:
            }
            length, lcs := LCS(s1, s2)
            results[idx] = LCSResult{s1, s2, length, lcs}
            return nil
        })
    }
    return results, eg.Wait()
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Space O(m×n) OOM | Rolling array O(min(m,n)) |
| 2 | Reconstruct with rolling array | Cannot — need full table |
| 3 | Confuse subsequence vs substring | Substring = contiguous |

---

**Liên kết**: [← Fibonacci](./01-fibonacci.md) · [→ Knapsack](./03-knapsack.md)
