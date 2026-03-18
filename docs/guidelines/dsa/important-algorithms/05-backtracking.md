# 🔙 Backtracking

> **Phân loại**: Brute Force + Pruning
> **Tóm tắt**: CHOOSE → EXPLORE → UNCHOOSE. Systematic enumeration with early termination.

---

## ① DEFINE

| Metric | Value |
|--------|-------|
| **Time** | O(exponential) — tùy bài toán |
| **Space** | O(depth) — recursion stack |
| **Pattern** | Choose → Explore → Unchoose |

### Template

```text
func backtrack(state, choices):
    if isSolution(state):
        record(state)
        return
    for choice in choices:
        if isValid(choice):
            CHOOSE: apply(choice)
            EXPLORE: backtrack(next_state, remaining_choices)
            UNCHOOSE: undo(choice)
```

---

## ② GRAPH

```text
  N-Queens (N=4):
  Explore tree:

       root
      / | \ \
    Q1  Q2  Q3  Q4    ← row 0
    /|  /|
  Q3 Q4 Q1 Q4         ← row 1 (prune conflicts)
  ...
  Solution found: [1, 3, 0, 2]

    . Q . .
    . . . Q
    Q . . .
    . . Q .
```

---

## ③ CODE

### Example 1: N-Queens Solver

```go
package algo

import "fmt"

func SolveNQueens(n int) [][]int {
    var results [][]int
    board := make([]int, n) // board[row] = col
    cols := make([]bool, n)
    diag1 := make([]bool, 2*n)
    diag2 := make([]bool, 2*n)

    var backtrack func(row int)
    backtrack = func(row int) {
        if row == n {
            sol := make([]int, n)
            copy(sol, board)
            results = append(results, sol)
            return
        }
        for col := 0; col < n; col++ {
            if cols[col] || diag1[row-col+n] || diag2[row+col] {
                continue // PRUNE
            }
            // CHOOSE
            board[row] = col
            cols[col] = true
            diag1[row-col+n] = true
            diag2[row+col] = true

            // EXPLORE
            backtrack(row + 1)

            // UNCHOOSE
            cols[col] = false
            diag1[row-col+n] = false
            diag2[row+col] = false
        }
    }

    backtrack(0)
    return results
}

func PrintNQueens(solution []int) {
    n := len(solution)
    for _, col := range solution {
        for j := 0; j < n; j++ {
            if j == col { fmt.Print("Q ") } else { fmt.Print(". ") }
        }
        fmt.Println()
    }
}
```

### Example 2: Sudoku Solver

```go
package algo

func SolveSudoku(board *[9][9]int) bool {
    for r := 0; r < 9; r++ {
        for c := 0; c < 9; c++ {
            if board[r][c] != 0 { continue }

            for num := 1; num <= 9; num++ {
                if isValidSudoku(board, r, c, num) {
                    board[r][c] = num     // CHOOSE
                    if SolveSudoku(board) { return true } // EXPLORE
                    board[r][c] = 0       // UNCHOOSE
                }
            }
            return false // no valid number → backtrack
        }
    }
    return true // all cells filled
}

func isValidSudoku(board *[9][9]int, row, col, num int) bool {
    for i := 0; i < 9; i++ {
        if board[row][i] == num { return false } // row
        if board[i][col] == num { return false } // col
        // 3×3 box
        r := 3*(row/3) + i/3
        c := 3*(col/3) + i%3
        if board[r][c] == num { return false }
    }
    return true
}
```

### Example 3: Permutations

```go
package algo

func Permutations(nums []int) [][]int {
    var results [][]int
    used := make([]bool, len(nums))
    var current []int

    var backtrack func()
    backtrack = func() {
        if len(current) == len(nums) {
            perm := make([]int, len(current))
            copy(perm, current)
            results = append(results, perm)
            return
        }
        for i, num := range nums {
            if used[i] { continue }
            used[i] = true
            current = append(current, num)
            backtrack()
            current = current[:len(current)-1]
            used[i] = false
        }
    }
    backtrack()
    return results
}
```

### Example 4: Subsets (Power Set)

```go
package algo

func Subsets(nums []int) [][]int {
    var results [][]int
    var current []int

    var backtrack func(start int)
    backtrack = func(start int) {
        sub := make([]int, len(current))
        copy(sub, current)
        results = append(results, sub)

        for i := start; i < len(nums); i++ {
            current = append(current, nums[i])
            backtrack(i + 1)
            current = current[:len(current)-1]
        }
    }
    backtrack(0)
    return results
}
```

### Example 5: Combination Sum

```go
package algo

func CombinationSum(candidates []int, target int) [][]int {
    var results [][]int
    var current []int

    var backtrack func(start, remain int)
    backtrack = func(start, remain int) {
        if remain == 0 {
            combo := make([]int, len(current))
            copy(combo, current)
            results = append(results, combo)
            return
        }
        for i := start; i < len(candidates); i++ {
            if candidates[i] > remain { continue }
            current = append(current, candidates[i])
            backtrack(i, remain-candidates[i]) // i: can reuse
            current = current[:len(current)-1]
        }
    }
    backtrack(0, target)
    return results
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Forget UNCHOOSE → state polluted | Always undo choice |
| 2 | Slice append without copy → shared memory | `copy` trước khi record |
| 3 | No pruning → TLE | Add constraints early |
| 4 | Duplicate results | Sort + skip same adjacent |

---

**Liên kết**: [← A* Search](./04-a-star.md) · [← README](./README.md)
