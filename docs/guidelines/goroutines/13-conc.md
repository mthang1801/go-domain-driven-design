# 13 — Conc

> **Library**: `github.com/sourcegraph/conc` — Structured concurrency, type-safe, panic-safe.

---

## ① DEFINE

### Định nghĩa

**Conc** (by Sourcegraph) cung cấp higher-level concurrency primitives trên nền `errgroup`. Ưu điểm chính: **type-safe generics**, **panic recovery built-in**, **structured concurrency** (goroutine luôn được cleanup).

### Core Components

| Component | Mô tả | Tương đương |
|-----------|-------|-------------|
| `pool.Pool` | Goroutine pool — fire-and-forget | `errgroup.Group` |
| `pool.ResultPool[T]` | Pool trả results type-safe | errgroup + channel + mutex |
| `pool.ErrorPool` | Pool với error propagation | `errgroup.Group` |
| `pool.ResultErrorPool[T]` | Pool trả results + errors | Tổng hợp |
| `iter.ForEach[T]` | Parallel iteration over slice | Custom fan-out |
| `iter.Map[T, R]` | Parallel map — transform slice | Custom fan-out + fan-in |

### Phân biệt Conc vs Errgroup vs Ants

| Đặc điểm | Conc | Errgroup | Ants |
|-----------|------|----------|------|
| **Type-safe** | ✅ Generics | ❌ | ❌ |
| **Panic recovery** | ✅ Auto | ❌ | ✅ Option |
| **Return results** | ✅ `ResultPool[T]` | ❌ | ❌ |
| **Parallel iter** | ✅ `ForEach`, `Map` | ❌ | ❌ |
| **Goroutine reuse** | ❌ | ❌ | ✅ |
| **Error handling** | ✅ All errors | ✅ First error | ❌ |
| **Dependency** | x/sync | x/sync | None |

### Invariants

- Panics LUÔN được recovered và re-raised khi `Wait()` — không mất panic info
- `ResultPool[T]` trả `[]T` type-safe — không cần type assertion
- Pool `Wait()` đợi TẤT CẢ goroutines — structured concurrency
- `WithMaxGoroutines(n)` giới hạn concurrency (như errgroup.SetLimit)

---

## ② GRAPH

### Conc Pool Types

```
  pool.Pool              pool.ErrorPool         pool.ResultPool[T]
  ┌────────────┐         ┌────────────┐         ┌─────────────────┐
  │ Go(func()) │         │ Go(func()  │         │ Go(func() T)    │
  │            │         │   error)   │         │                 │
  │ Wait()     │         │ Wait()     │         │ Wait() []T      │
  │            │         │   error    │         │                 │
  └────────────┘         └────────────┘         └─────────────────┘
   fire-and-forget        error propagation       type-safe results
   + panic recovery       + panic recovery        + panic recovery
```

### iter.Map Flow

```
  Input:  [1, 2, 3, 4, 5]

  iter.Map(input, func(n int) string {
      return fmt.Sprintf("%d²=%d", n, n*n)
  })

  Worker 1: 1 → "1²=1"   ──┐
  Worker 2: 2 → "2²=4"   ──┤
  Worker 3: 3 → "3²=9"   ──┼──▶ Output: ["1²=1", "2²=4", "3²=9", ...]
  Worker 4: 4 → "4²=16"  ──┤      (ORDER PRESERVED!)
  Worker 5: 5 → "5²=25"  ──┘
```

---

## ③ CODE

---

### Example 1: Pool types — fire-and-forget, errors, results

**Mục tiêu**: So sánh 3 pool types: `Pool`, `ErrorPool`, `ResultPool[T]`. Mỗi loại cho use case khác nhau.

**Cần gì**: `go get github.com/sourcegraph/conc`.

```go
package main

import (
    "fmt"
    "math/rand"
    "time"

    "github.com/sourcegraph/conc/pool"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 1. pool.Pool — fire-and-forget
    // Panic-safe: panic trong Go → recovered, re-raised khi Wait
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("=== Pool (fire-and-forget) ===")
    p := pool.New().WithMaxGoroutines(4) // max 4 concurrent
    for i := 0; i < 10; i++ {
        i := i
        p.Go(func() {
            time.Sleep(time.Duration(rand.Intn(100)) * time.Millisecond)
            fmt.Printf("  Task %d done\n", i)
        })
    }
    p.Wait() // block + re-raise panics nếu có
    fmt.Println()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 2. pool.ErrorPool — fire-and-forget + error collection
    // Collect TẤT CẢ errors (khác errgroup chỉ first error)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("=== ErrorPool (with errors) ===")
    ep := pool.New().WithErrors().WithMaxGoroutines(4)
    for i := 0; i < 10; i++ {
        i := i
        ep.Go(func() error {
            if i%3 == 0 {
                return fmt.Errorf("task %d failed", i)
            }
            fmt.Printf("  Task %d OK\n", i)
            return nil
        })
    }
    if err := ep.Wait(); err != nil {
        fmt.Printf("  ❌ Errors: %v\n", err) // multi-error
    }
    fmt.Println()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 3. pool.ResultPool[T] — type-safe results
    // Wait() trả []T — không cần channel + mutex
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("=== ResultPool[string] (typed results) ===")
    rp := pool.NewWithResults[string]().WithMaxGoroutines(4)
    for i := 0; i < 5; i++ {
        i := i
        rp.Go(func() string {
            return fmt.Sprintf("Result-%d: %d²=%d", i, i, i*i)
        })
    }
    results := rp.Wait() // []string — type-safe!
    for _, r := range results {
        fmt.Printf("  %s\n", r)
    }
}
```

**Kết quả đạt được**:
- `Pool`: fire-and-forget, panic-safe.
- `ErrorPool`: collect ALL errors (multi-error).
- `ResultPool[string]`: type-safe results, no channel/mutex needed.

**Lưu ý**:
- **Panic recovery**: Conc pools LUÔN recover panics và re-raise khi `Wait()`. Errgroup KHÔNG.
- `ErrorPool` collect **TẤT CẢ** errors — errgroup chỉ **first** error.
- `WithMaxGoroutines(n)` = `errgroup.SetLimit(n)`.

---

### Example 2: iter.ForEach & iter.Map — Parallel iteration

**Mục tiêu**: Parallel iteration over slices: `ForEach` cho side-effects, `Map` cho transformation. Order preserved.

**Cần gì**: `github.com/sourcegraph/conc/iter`.

```go
package main

import (
    "fmt"
    "strings"
    "time"

    "github.com/sourcegraph/conc/iter"
)

type User struct {
    ID    int
    Name  string
    Email string
}

func main() {
    users := []User{
        {1, "Alice", "alice@example.com"},
        {2, "Bob", "bob@example.com"},
        {3, "Charlie", "charlie@example.com"},
        {4, "Diana", "diana@example.com"},
        {5, "Eve", "eve@example.com"},
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // iter.ForEach: parallel for-each (side-effects)
    // Mỗi element xử lý song song, đợi tất cả xong
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("=== ForEach (send welcome emails) ===")
    iter.ForEach(users, func(u *User) {
        time.Sleep(100 * time.Millisecond) // simulate sending email
        fmt.Printf("  📧 Sent welcome email to %s (%s)\n", u.Name, u.Email)
    })
    fmt.Println()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // iter.Map: parallel map — transform slice
    // ✅ ORDER PRESERVED (khác fan-out/fan-in)
    // Input [T] → Output [R] (type-safe)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("=== Map (transform users → display names) ===")
    displayNames := iter.Map(users, func(u *User) string {
        time.Sleep(50 * time.Millisecond) // simulate processing
        return fmt.Sprintf("%s <%s>", strings.ToUpper(u.Name), u.Email)
    })
    for i, name := range displayNames {
        fmt.Printf("  [%d] %s\n", i, name)
    }
    // Output ORDER = Input ORDER ✅

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // iter.Map with numbers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("\n=== Map (parallel square) ===")
    numbers := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
    squares := iter.Map(numbers, func(n *int) int {
        return (*n) * (*n)
    })
    fmt.Println("  Squares:", squares) // [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
}
```

**Kết quả đạt được**:
- `ForEach`: parallel side-effects (send emails, update cache).
- `Map`: parallel transformation — **ORDER PRESERVED** (khác fan-out/fan-in).
- Type-safe: `iter.Map[User, string]` → `[]string`.

**Lưu ý**:
- **Order preserved** trong `Map` — rất tiện so với fan-out + sort.
- Default concurrency = `runtime.NumCPU()`. Dùng `iter.ForEachIdx` cho index.
- Conc `iter` callback nhận **pointer** (`*User`) — modify in-place nếu cần.
- `ForEach` blocking — đợi TẤT CẢ elements xong.

---

### Example 3: Panic safety — So sánh Conc vs Errgroup

**Mục tiêu**: Chứng minh Conc recover panics gracefully, trong khi errgroup crash.

```go
package main

import (
    "fmt"

    "github.com/sourcegraph/conc/pool"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Conc: panic recovered, re-raised as panic khi Wait()
    // Errgroup: panic → crash process (unrecovered)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    // Safe way: recover panic từ Conc pool
    func() {
        defer func() {
            if r := recover(); r != nil {
                fmt.Printf("✅ Recovered panic from pool: %v\n", r)
            }
        }()

        p := pool.New().WithMaxGoroutines(2)
        p.Go(func() {
            fmt.Println("  Task 1: working...")
        })
        p.Go(func() {
            panic("💥 Task 2 panicked!")
        })
        p.Go(func() {
            fmt.Println("  Task 3: working...")
        })
        p.Wait() // ← re-raises panic here
    }()

    fmt.Println("\n✅ Program continues after pool panic!")
    fmt.Println("   (errgroup would have crashed the entire process)")
}
```

**Kết quả đạt được**:
- Conc pool recover panic → re-raise khi `Wait()` → caller có thể handle.
- Program tiếp tục chạy sau panic (nếu caller recover).

**Lưu ý**:
- **Errgroup không recover panics** — 1 goroutine panic = crash process.
- Conc panic recovery = production safety net — không mất request.
- Stack trace preserved trong panic info — debugging dễ dàng.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên WithMaxGoroutines** | Unlimited goroutines | Luôn set limit |
| 2 | **Modify shared state trong ForEach** | Race condition | Dùng mutex hoặc per-element |
| 3 | **Ignore Wait() panic** | Un-recovered panic | Luôn defer recover nếu cần |
| 4 | **Map callback heavy** | All CPUs busy | Tune max goroutines |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Conc GitHub | https://github.com/sourcegraph/conc |
| Conc GoDoc | https://pkg.go.dev/github.com/sourcegraph/conc |
| Conc Blog Post | https://about.sourcegraph.com/blog/building-conc-better-structured-concurrency-for-go |
