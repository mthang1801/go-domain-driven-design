# ⭐ Important Algorithms — Tổng quan & Hướng dẫn

> **Mục đích**: 5 thuật toán quan trọng: Union-Find, KMP, Rabin-Karp, A* Search, Backtracking.

---

## 📑 Mục lục

| # | Algorithm | Time | Mục đích | Detail |
|---|-----------|------|----------|--------|
| 1 | **Union-Find** | O(α(n)) ≈ O(1) | Disjoint sets, connectivity | [→ 01-union-find.md](./01-union-find.md) |
| 2 | **KMP** | O(n + m) | Pattern matching | [→ 02-kmp.md](./02-kmp.md) |
| 3 | **Rabin-Karp** | O(n + m) avg | Multi-pattern matching | [→ 03-rabin-karp.md](./03-rabin-karp.md) |
| 4 | **A\* Search** | O(b^d) | Pathfinding with heuristic | [→ 04-a-star.md](./04-a-star.md) |
| 5 | **Backtracking** | O(exponential) | N-Queens, Sudoku, CSP | [→ 05-backtracking.md](./05-backtracking.md) |

---

## 🗺️ Selection

```text
  Connectivity / sets?   → Union-Find
  String matching?       → KMP (single) / Rabin-Karp (multi)
  Pathfinding + heuristic? → A*
  Constraint satisfaction? → Backtracking
```

---

**Liên kết**: [← Dynamic Programming](../dynamic-programming/README.md) · [← DSA Overview](../README.md)
