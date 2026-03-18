# 🔤 KMP — Knuth-Morris-Pratt

> **Phân loại**: String Pattern Matching
> **Tóm tắt**: O(n+m) string matching. Precompute failure function → never backtrack text pointer.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(n + m), n=text, m=pattern |
| **Space** | O(m) — failure table |
| **Preprocessing** | O(m) — build failure function |
| **vs Naive** | Naive O(n×m), KMP O(n+m) |

### Key Insight

**Failure function** `fail[i]` = longest proper prefix of `pattern[0..i]` that is also a suffix. Khi mismatch, thay vì reset → nhảy đến vị trí `fail[i-1]` → tận dụng phần đã match.

---

## ② GRAPH

```text
  Pattern: "ABABC"
  Failure: [0, 0, 1, 2, 0]

  i:    0  1  2  3  4
  P:    A  B  A  B  C
  F:    0  0  1  2  0

  F[3]=2 nghĩa: "ABAB" có prefix "AB" = suffix "AB" (length 2)
  → Khi mismatch tại i=4: nhảy về i=F[3]=2, không cần restart
```

---

## ③ CODE

### Example 1: Build Failure Function

```go
package algo

// buildFailure: compute prefix function (failure table)
func buildFailure(pattern string) []int {
    m := len(pattern)
    fail := make([]int, m)
    k := 0

    for i := 1; i < m; i++ {
        for k > 0 && pattern[k] != pattern[i] {
            k = fail[k-1] // fall back
        }
        if pattern[k] == pattern[i] {
            k++
        }
        fail[i] = k
    }
    return fail
}
```

### Example 2: KMP Search (all occurrences)

```go
package algo

func KMPSearch(text, pattern string) []int {
    n, m := len(text), len(pattern)
    if m == 0 { return nil }
    fail := buildFailure(pattern)
    var matches []int
    q := 0

    for i := 0; i < n; i++ {
        for q > 0 && pattern[q] != text[i] {
            q = fail[q-1]
        }
        if pattern[q] == text[i] {
            q++
        }
        if q == m {
            matches = append(matches, i-m+1)
            q = fail[q-1] // continue searching
        }
    }
    return matches
}
```

### Example 3: Count Occurrences

```go
package algo

func KMPCount(text, pattern string) int {
    return len(KMPSearch(text, pattern))
}
```

### Example 4: KMP for Shortest Period

```go
package algo

// ShortestPeriod: s = "abcabc" → period = "abc" (len 3)
func ShortestPeriod(s string) int {
    fail := buildFailure(s)
    n := len(s)
    period := n - fail[n-1]
    if n%period == 0 {
        return period
    }
    return n
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Confuse failure function direction | Prefix = suffix, proper only |
| 2 | Forget `q = fail[q-1]` after match | Miss overlapping matches |
| 3 | Unicode strings | Use `[]rune` thay `[]byte` |

---

**Liên kết**: [← Union-Find](./01-union-find.md) · [→ Rabin-Karp](./03-rabin-karp.md)
