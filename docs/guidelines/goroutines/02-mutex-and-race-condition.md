# 02 — Mutex & Race Condition

> **Nền tảng**: Bảo vệ shared memory khi nhiều goroutines truy cập đồng thời.

---

## ① DEFINE

### Race Condition

**Race condition** xảy ra khi ≥ 2 goroutines truy cập cùng một biến đồng thời, và ít nhất 1 goroutine **ghi** (write). Kết quả phụ thuộc vào thứ tự thực thi — **non-deterministic**.

### Mutex (Mutual Exclusion)

**`sync.Mutex`** đảm bảo chỉ **1 goroutine** được truy cập critical section tại 1 thời điểm.

### Phân biệt Mutex vs RWMutex vs Atomic

| Cơ chế | Use case | Performance |
|--------|----------|-------------|
| **sync.Mutex** | Read + Write — exclusive access | Vừa phải |
| **sync.RWMutex** | Nhiều reader, ít writer | Tốt cho read-heavy |
| **sync/atomic** | Single variable (counter, flag) | Nhanh nhất |
| **Channel** | Communication-based sync | Flexible nhất |

### Invariants

- **Lock trước, Unlock sau** — luôn `defer mu.Unlock()` ngay sau `mu.Lock()`
- **Không lock 2 lần** (cùng goroutine) → deadlock
- **RWMutex**: nhiều `RLock` đồng thời OK, `Lock` phải đợi tất cả `RUnlock`
- **Atomic**: chỉ cho single variable, không cho struct/multi-field

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Data race** | Read + Write không sync | Dùng Mutex hoặc channel |
| **Deadlock** | Lock order khác nhau giữa goroutines | Luôn lock theo cùng thứ tự |
| **Quên Unlock** | Forget `mu.Unlock()` | Luôn `defer mu.Unlock()` |
| **Nested lock** | Lock rồi lại Lock → deadlock | Thiết kế không cần nested |

---

## ② GRAPH

### Race Condition — Visualized

```
Timeline ──────────────────────────────────────▶

Goroutine A:    read(counter=0)    write(counter=1)
                    │                    │
Goroutine B:        │   read(counter=0)  │  write(counter=1)
                    │       │            │      │
counter:         0  │    0  │         1  │   1  │
                    │       │            │      │
Expected: counter = 2 (mỗi G tăng 1)
Actual:   counter = 1 ← BUG! G_B đọc giá trị cũ (0) trước khi G_A ghi
```

### Mutex — Critical Section

```
Goroutine A          Mutex           Goroutine B
    │                  │                  │
    │── Lock() ───────▶│                  │
    │                  │◀── Lock() ───────│ ← BLOCK (đợi A unlock)
    │                  │                  │
    │  [Critical       │                  │
    │   Section:       │                  │
    │   read+write]    │                  │
    │                  │                  │
    │── Unlock() ─────▶│                  │
    │                  │── Unblock ──────▶│
    │                  │                  │
    │                  │  [Critical       │
    │                  │   Section:       │
    │                  │   read+write]    │
    │                  │                  │
    │                  │◀── Unlock() ─────│
```

### RWMutex — Multiple Readers

```
Reader A:   RLock ━━━━━━━━━━━━━━ RUnlock               Readers CAN
Reader B:     RLock ━━━━━━━━━━━━━━━ RUnlock             run in PARALLEL
Reader C:       RLock ━━━━━━━━━━━━━━━ RUnlock
                                        │
Writer D:                               Lock ━━━━ Unlock   Writer MUST
                                        ↑                   wait for ALL
                                   Đợi tất cả              readers
                                   RUnlock
```

---

## ③ CODE

---

### Example 1: Race Condition — Phát hiện bằng Go Race Detector

**Mục tiêu**: Chứng minh race condition tồn tại, và cách dùng `go run -race` để phát hiện.

**Cần gì**: Go toolchain với `-race` flag.

```go
package main

import (
    "fmt"
    "sync"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // ❌ BUG: Race condition!
    // 100 goroutines cùng tăng counter mà không sync.
    // Chạy: go run -race main.go → sẽ thấy WARNING
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    counter := 0
    var wg sync.WaitGroup

    for i := 0; i < 100; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            // Cả 100 goroutine đọc + ghi counter cùng lúc
            // → data race: kết quả không deterministic
            counter++ // ← RACE! Read-modify-write không atomic
        }()
    }

    wg.Wait()
    // Expected: 100
    // Actual: có thể là 97, 99, 100, ... (non-deterministic)
    fmt.Println("Counter:", counter)
}
```

**Cách phát hiện**:
```bash
go run -race main.go
# WARNING: DATA RACE
# Write at 0x00c0000b4010 by goroutine 7:
# Previous write at 0x00c0000b4010 by goroutine 6:
```

**Kết quả đạt được**:
- Hiểu race condition: kết quả khác nhau mỗi lần chạy.
- `go run -race` phát hiện race tại compile/runtime.

**Lưu ý**:
- **LUÔN** chạy tests với `-race`: `go test -race ./...`
- `-race` làm chậm 2-10x — chỉ dùng trong dev/test, không dùng production.
- Race detector phát hiện 100% races **nếu code path được execute** — thiếu test = thiếu coverage.

---

### Example 2: sync.Mutex — Fix Race Condition

**Mục tiêu**: Dùng `sync.Mutex` để bảo vệ counter — chỉ 1 goroutine truy cập tại 1 thời điểm.

**Cần gì**: `sync` package.

```go
package main

import (
    "fmt"
    "sync"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SafeCounter: goroutine-safe counter sử dụng Mutex
// Pattern: embed Mutex trong struct chứa shared data
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type SafeCounter struct {
    mu    sync.Mutex // protects counter
    count int
}

func (c *SafeCounter) Increment() {
    c.mu.Lock()         // ← Chỉ 1 goroutine vào critical section
    defer c.mu.Unlock() // ← LUÔN defer Unlock ngay sau Lock
    c.count++           // ← Critical section: safe read-modify-write
}

func (c *SafeCounter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.count // ← Đọc cũng cần lock để tránh đọc giá trị "cũ"
}

func main() {
    counter := &SafeCounter{}
    var wg sync.WaitGroup

    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            counter.Increment()
        }()
    }

    wg.Wait()
    fmt.Println("Counter:", counter.Value()) // Luôn = 1000 ✅
}
```

**Kết quả đạt được**:
- Counter **luôn = 1000** — deterministic.
- Race-free: `go run -race` không có warnings.

**Lưu ý**:
- `defer mu.Unlock()` ngay sau `Lock()` — tránh quên unlock khi panic.
- **ĐỌC cũng cần lock** nếu có goroutine khác đang ghi.
- Mutex KHÔNG reentrant (không thể Lock 2 lần trong cùng goroutine → deadlock).

---

### Example 3: sync.RWMutex — Tối ưu read-heavy workload

**Mục tiêu**: Cho phép nhiều goroutines đọc song song (RLock), chỉ block khi có goroutine ghi (Lock). Phù hợp cho cache, config, read-heavy data.

**Cần gì**: `sync` package.

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Cache: read-heavy → dùng RWMutex
// - Nhiều goroutines đọc đồng thời: RLock (không block nhau)
// - 1 goroutine ghi: Lock (block tất cả readers và writers)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type Cache struct {
    mu    sync.RWMutex
    items map[string]string
}

func NewCache() *Cache {
    return &Cache{items: make(map[string]string)}
}

// Get: nhiều goroutines có thể gọi đồng thời (RLock)
func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()         // ← Read lock: không block readers khác
    defer c.mu.RUnlock()
    val, ok := c.items[key]
    return val, ok
}

// Set: chỉ 1 goroutine ghi tại 1 thời điểm (Lock)
func (c *Cache) Set(key, value string) {
    c.mu.Lock()          // ← Write lock: block TẤT CẢ readers + writers
    defer c.mu.Unlock()
    c.items[key] = value
}

func main() {
    cache := NewCache()
    var wg sync.WaitGroup

    // 1 writer (chậm)
    wg.Add(1)
    go func() {
        defer wg.Done()
        for i := 0; i < 5; i++ {
            key := fmt.Sprintf("key-%d", i)
            cache.Set(key, fmt.Sprintf("value-%d", i))
            fmt.Printf("[Writer] Set %s\n", key)
            time.Sleep(100 * time.Millisecond)
        }
    }()

    // 10 readers (nhanh, đồng thời)
    for r := 0; r < 10; r++ {
        wg.Add(1)
        go func(readerID int) {
            defer wg.Done()
            for i := 0; i < 5; i++ {
                key := fmt.Sprintf("key-%d", i)
                if val, ok := cache.Get(key); ok {
                    fmt.Printf("[Reader %d] Got %s=%s\n", readerID, key, val)
                }
                time.Sleep(50 * time.Millisecond)
            }
        }(r)
    }

    wg.Wait()
}
```

**Kết quả đạt được**:
- 10 readers chạy **song song** — không block nhau (RLock).
- Writer chỉ block khi có goroutine đang hold RLock — performance tốt hơn Mutex cho read-heavy.

**Lưu ý**:
- **RWMutex chỉ tốt khi read >> write** (ratio ≥ 10:1). Nếu read ≈ write → Mutex đơn giản hơn.
- Writer bị **starvation** nếu readers liên tục — RWMutex ưu tiên readers.
- Dùng `RLock` khi ĐỌC, `Lock` khi GHI — nhầm lẫn → race condition.

---

### Example 4: sync/atomic — Lightweight cho single variable

**Mục tiêu**: Dùng atomic operations cho counter đơn giản — nhanh hơn Mutex vì không cần lock/unlock.

**Cần gì**: `sync/atomic` package.

```go
package main

import (
    "fmt"
    "sync"
    "sync/atomic"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // atomic: CPU-level instruction, không cần lock
    // Chỉ cho SINGLE variable: int32, int64, uint64, uintptr, pointer
    // Nhanh hơn Mutex 2-5x cho simple operations
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var counter atomic.Int64 // Go 1.19+ — type-safe atomic
    var wg sync.WaitGroup

    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            counter.Add(1) // ← Atomic increment: hardware-level, no lock
        }()
    }

    wg.Wait()
    fmt.Println("Counter:", counter.Load()) // Luôn = 1000 ✅

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Compare-And-Swap (CAS) — conditional atomic update
    // "Chỉ update nếu giá trị hiện tại = expected"
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    var flag atomic.Bool
    swapped := flag.CompareAndSwap(false, true) // ← Chỉ set true nếu đang false
    fmt.Println("Swapped:", swapped)            // true (lần đầu)
    swapped = flag.CompareAndSwap(false, true)
    fmt.Println("Swapped:", swapped)            // false (đã là true)
}
```

**Kết quả đạt được**:
- Atomic operations nhanh hơn Mutex 2-5x cho single variable.
- `CompareAndSwap` cho phép lock-free algorithms.

**Lưu ý**:
- **Chỉ cho single variable** — không dùng cho struct hoặc multi-field update.
- Go 1.19+: dùng `atomic.Int64`, `atomic.Bool` — type-safe, dễ đọc hơn `atomic.AddInt64(&x, 1)`.
- Khi cần update > 1 field cùng lúc → phải dùng Mutex.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên `-race` flag** | Luôn: `go test -race ./...` |
| 2 | **Quên `defer Unlock`** | Luôn `defer mu.Unlock()` ngay sau `Lock()` |
| 3 | **Copy Mutex** | Mutex KHÔNG được copy (pass by value) → dùng pointer |
| 4 | **Nested lock** | Lock A → Lock B → Deadlock | Luôn lock theo cùng thứ tự |
| 5 | **RLock cho write** | Dùng `RLock` khi ghi → race condition |
| 6 | **Atomic cho struct** | Atomic chỉ cho single var | Dùng Mutex cho struct |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Go Blog — Race Detector | https://go.dev/doc/articles/race_detector |
| sync package | https://pkg.go.dev/sync |
| sync/atomic | https://pkg.go.dev/sync/atomic |
| Go Memory Model | https://go.dev/ref/mem |

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **Thay thế Mutex** | `sync.Map` | Built-in concurrent map — tốt cho cache key-value đơn giản |
| **Thay thế Mutex cho counter** | `atomic.Int64` | 2-5x nhanh hơn Mutex cho single var |
| **Lock-free queue** | `github.com/enriquebris/goconcurrentqueue` | Lock-free FIFO queue |
| **Distributed lock** | Redis `SETNX` / `Redlock` | Cross-process locking |
| **Testing** | `go test -race -count=100` | Chạy nhiều lần để phát hiện rare races |
| **Profiling** | `go tool pprof -mutex` | Detect mutex contention |
| **Kết hợp GORM** | RWMutex + in-memory cache + GORM | Cache DB reads, mutex cho consistency — xem [go-orm/06-migration-and-advanced.md](../go-orm/06-migration-and-advanced.md) |
