# 🎲 Rabin-Karp — Rolling Hash Pattern Matching

> **Phân loại**: String Pattern Matching, Hashing
> **Tóm tắt**: Rolling hash → O(1) compare per window. Best for multi-pattern matching.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(n+m) average, O(nm) worst (hash collisions) |
| **Space** | O(1) single, O(k) multi-pattern |
| **vs KMP** | KMP single pattern, Rabin-Karp multiple patterns |

### Rolling Hash Formula

```text
hash(s[i..i+m]) = s[i]*B^(m-1) + s[i+1]*B^(m-2) + ... + s[i+m-1]
hash(next window) = (hash - s[i]*B^(m-1)) * B + s[i+m]
```

---

## ③ CODE

### Example 1: Single Pattern

```go
package algo

const (
    base = 31
    mod  = 1_000_000_007
)

func RabinKarp(text, pattern string) []int {
    n, m := len(text), len(pattern)
    if m > n { return nil }

    // Compute pattern hash + B^(m-1)
    patHash, textHash, power := 0, 0, 1
    for i := 0; i < m; i++ {
        patHash = (patHash*base + int(pattern[i])) % mod
        textHash = (textHash*base + int(text[i])) % mod
        if i > 0 { power = (power * base) % mod }
    }

    var matches []int
    for i := 0; i <= n-m; i++ {
        if textHash == patHash {
            if text[i:i+m] == pattern { // verify (avoid false positive)
                matches = append(matches, i)
            }
        }
        if i < n-m {
            textHash = ((textHash-int(text[i])*power)*base + int(text[i+m])) % mod
            if textHash < 0 { textHash += mod }
        }
    }
    return matches
}
```

### Example 2: Multi-Pattern Search

```go
package algo

func RabinKarpMulti(text string, patterns []string) map[string][]int {
    results := make(map[string][]int)
    for _, p := range patterns {
        results[p] = RabinKarp(text, p)
    }
    return results
}
```

### Example 3: Plagiarism Detector (Rolling Hash Applications)

```go
package algo

// FindDuplicateSubstrings: tìm tất cả substrings trùng lặp length k
func FindDuplicateSubstrings(text string, k int) []string {
    if k > len(text) { return nil }

    seen := make(map[int][]int) // hash → list of start indices
    var duplicates []string

    hash, power := 0, 1
    for i := 0; i < k; i++ {
        hash = (hash*base + int(text[i])) % mod
        if i > 0 { power = (power * base) % mod }
    }

    seen[hash] = []int{0}
    for i := 1; i <= len(text)-k; i++ {
        hash = ((hash-int(text[i-1])*power)*base + int(text[i+k-1])) % mod
        if hash < 0 { hash += mod }

        if indices, ok := seen[hash]; ok {
            for _, idx := range indices {
                if text[idx:idx+k] == text[i:i+k] {
                    duplicates = append(duplicates, text[i:i+k])
                }
            }
        }
        seen[hash] = append(seen[hash], i)
    }
    return duplicates
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Hash collision → false positive | Always verify string match |
| 2 | Negative hash modulo | `if hash < 0 { hash += mod }` |
| 3 | Small mod → many collisions | Use large prime mod |

---

**Liên kết**: [← KMP](./02-kmp.md) · [→ A* Search](./04-a-star.md)
