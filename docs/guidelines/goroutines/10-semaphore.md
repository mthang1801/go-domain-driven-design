# 10 — Semaphore

> **Package**: `golang.org/x/sync/semaphore` — Weighted semaphore cho concurrent access control.

---

## ① DEFINE

### Định nghĩa

**Semaphore** là cơ chế giới hạn số lượng goroutines truy cập đồng thời vào 1 resource. Khác với Mutex (chỉ cho 1), semaphore cho phép **tối đa N** goroutines đồng thời.

**`semaphore.Weighted`** là implementation trong Go x/ library — hỗ trợ weighted acquire (mỗi goroutine có thể "chiếm" nhiều hơn 1 slot).

### Phân biệt Semaphore vs Mutex vs Channel

| Cơ chế | Max concurrent | Weighted? | Blocking? | Context? |
|--------|---------------|-----------|-----------|----------|
| **Mutex** | 1 | ❌ | Lock block | ❌ |
| **Channel (buffered)** | N (buffer size) | ❌ | Send block khi full | ❌ |
| **semaphore.Weighted** | N (configurable) | ✅ | `Acquire` block | ✅ `ctx` |
| **errgroup.SetLimit** | N | ❌ | `Go` block | ✅ |

### Use cases

| Use case | Ví dụ |
|----------|-------|
| **Rate limiting** | Tối đa 10 concurrent HTTP requests đến external API |
| **Resource protection** | Tối đa 5 concurrent DB connections |
| **Weighted resources** | GPU tasks cần 2 slots, CPU tasks cần 1 slot |
| **Batch processing** | Xử lý 1000 files nhưng chỉ 20 cùng lúc |

### Invariants

- `Acquire(ctx, n)` block cho đến khi có ≥ n slots available
- `Release(n)` giải phóng n slots — **PHẢI** gọi đúng số đã Acquire
- `TryAcquire(n)` non-blocking — return false nếu không đủ slots
- Tổng slots released ≤ tổng slots acquired — vi phạm = panic

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Deadlock** | Acquire nhiều hơn max weight | Acquire ≤ max weight |
| **Resource leak** | Quên Release | `defer sem.Release(n)` |
| **Context expired** | Timeout trước khi acquire | Handle `ctx.Err()` |

---

## ② GRAPH

### Semaphore Flow

```
  Semaphore(3)        ← max 3 concurrent slots
  ┌──────────────┐
  │ ■ ■ ■        │    3 slots available
  └──────────────┘

  G1: Acquire(1)  → ■ □ □  (2 remaining)
  G2: Acquire(1)  → ■ ■ □  (1 remaining)
  G3: Acquire(1)  → ■ ■ ■  (0 remaining)
  G4: Acquire(1)  → BLOCK  (đợi Release)

  G1: Release(1)  → ■ ■ □  (1 available → G4 unblock)
  G4: acquired!   → ■ ■ ■  (0 remaining)
```

### Weighted Semaphore

```
  Semaphore(4)        ← 4 slots total

  GPU Task: Acquire(2)  → ■ ■ □ □   (cần 2 slots)
  CPU Task: Acquire(1)  → ■ ■ ■ □   (cần 1 slot)
  CPU Task: Acquire(1)  → ■ ■ ■ ■   (full)
  GPU Task: Acquire(2)  → BLOCK     (cần 2 nhưng chỉ có 0)

  CPU Release(1):       → ■ ■ ■ □   (1 available, GPU cần 2 → vẫn block)
  CPU Release(1):       → ■ ■ □ □   (2 available → GPU unblock!)
```

---

## ③ CODE

---

### Example 1: Basic — Giới hạn concurrent HTTP requests

**Mục tiêu**: Tối đa 5 concurrent requests đến external API. Có 20 URLs cần fetch, semaphore đảm bảo chỉ 5 goroutines chạy cùng lúc.

**Cần gì**: `golang.org/x/sync/semaphore`, `context`.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "sync"
    "time"

    "golang.org/x/sync/semaphore"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // semaphore.NewWeighted(5): tối đa 5 concurrent
    // Mỗi Acquire(ctx, 1) chiếm 1 slot
    // Mỗi Release(1) trả 1 slot
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sem := semaphore.NewWeighted(5)
    ctx := context.Background()

    urls := make([]string, 20)
    for i := range urls {
        urls[i] = fmt.Sprintf("https://api.example.com/data/%d", i+1)
    }

    var wg sync.WaitGroup
    var mu sync.Mutex
    results := make([]string, 0, 20)

    for _, url := range urls {
        wg.Add(1)
        go func(u string) {
            defer wg.Done()

            // ━━━ Acquire 1 slot — block nếu đã full ━━━
            if err := sem.Acquire(ctx, 1); err != nil {
                fmt.Printf("❌ Acquire failed for %s: %v\n", u, err)
                return
            }
            defer sem.Release(1) // ← LUÔN defer Release

            // Simulate HTTP request
            delay := time.Duration(100+rand.Intn(300)) * time.Millisecond
            time.Sleep(delay)

            result := fmt.Sprintf("✅ %s (took %v)", u, delay)

            mu.Lock()
            results = append(results, result)
            mu.Unlock()
        }(url)
    }

    wg.Wait()
    fmt.Printf("Fetched %d/%d URLs (max 5 concurrent)\n", len(results), len(urls))
}
```

**Kết quả đạt được**:
- 20 URLs nhưng chỉ 5 chạy cùng lúc — tránh overwhelm API.
- `Acquire` block goroutines thừa, tự unblock khi có slot.

**Lưu ý**:
- `defer sem.Release(1)` **ngay sau** Acquire — tránh leak slots.
- `Acquire(ctx, 1)` support context — cancel = unblock waiting goroutines.
- Khác với `errgroup.SetLimit(5)`: semaphore cho phép **weighted** access.

---

### Example 2: TryAcquire — Non-blocking check

**Mục tiêu**: Thử acquire mà không block — nếu không đủ slots, skip hoặc fallback.

**Cần gì**: `semaphore` package.

```go
package main

import (
    "fmt"
    "time"

    "golang.org/x/sync/semaphore"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Scenario: Request handler với rate limiting
    // Nếu tất cả slots busy → trả "429 Too Many Requests"
    // thay vì block caller (khác với Acquire)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sem := semaphore.NewWeighted(3) // max 3 concurrent handlers

    for i := 1; i <= 10; i++ {
        // ━━━ TryAcquire: return true/false ngay lập tức ━━━
        if !sem.TryAcquire(1) {
            fmt.Printf("Request %d: 🚫 429 Too Many Requests (all slots busy)\n", i)
            continue
        }

        go func(reqID int) {
            defer sem.Release(1)
            fmt.Printf("Request %d: ✅ Processing...\n", reqID)
            time.Sleep(500 * time.Millisecond) // simulate work
            fmt.Printf("Request %d: ✅ Done\n", reqID)
        }(i)

        time.Sleep(100 * time.Millisecond) // simulate request arrival rate
    }

    time.Sleep(2 * time.Second) // wait for processing
}
```

**Kết quả đạt được**:
- Requests 1-3: xử lý (3 slots available).
- Requests 4+: tùy timing — nếu slots busy → reject ngay (429).
- **Non-blocking**: caller không phải đợi.

**Lưu ý**:
- `TryAcquire` phù hợp cho **HTTP handlers** — trả 429/503 thay vì timeout.
- `Acquire` phù hợp cho **background workers** — đợi slot rảnh.

---

### Example 3: Weighted Semaphore — Khác nhau resource weights

**Mục tiêu**: Tasks có trọng số khác nhau: GPU task cần 2 slots, CPU task cần 1 slot. Tổng cộng 4 slots — phối hợp resource allocation.

**Cần gì**: `semaphore` package to demonstrate weighted allocation.

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"

    "golang.org/x/sync/semaphore"
)

type Task struct {
    Name   string
    Weight int64  // slots cần thiết
    Work   time.Duration
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Total capacity: 4 slots
    // GPU tasks: cần 2 slots mỗi task
    // CPU tasks: cần 1 slot mỗi task
    //
    // Scenario:
    //   2 GPU tasks (2 slots each) = 4 slots → full
    //   4 CPU tasks (1 slot each) = 4 slots → full
    //   1 GPU + 2 CPU = 2 + 2 = 4 slots → full
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    sem := semaphore.NewWeighted(4)
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    tasks := []Task{
        {"GPU-Render-1", 2, 800 * time.Millisecond},
        {"CPU-Hash-1",   1, 300 * time.Millisecond},
        {"GPU-Train-1",  2, 1200 * time.Millisecond},
        {"CPU-Hash-2",   1, 200 * time.Millisecond},
        {"CPU-Hash-3",   1, 400 * time.Millisecond},
        {"GPU-Render-2", 2, 600 * time.Millisecond},
        {"CPU-Hash-4",   1, 150 * time.Millisecond},
    }

    var wg sync.WaitGroup
    for _, task := range tasks {
        wg.Add(1)
        go func(t Task) {
            defer wg.Done()

            fmt.Printf("[%s] ⏳ Waiting for %d slot(s)...\n", t.Name, t.Weight)

            // Acquire: đợi đủ slots (weight)
            if err := sem.Acquire(ctx, t.Weight); err != nil {
                fmt.Printf("[%s] ❌ Context cancelled: %v\n", t.Name, err)
                return
            }
            defer sem.Release(t.Weight) // ← release ĐÚNG SỐ đã acquire

            fmt.Printf("[%s] ▶️  Running (using %d slot(s))...\n", t.Name, t.Weight)
            time.Sleep(t.Work)
            fmt.Printf("[%s] ✅ Done\n", t.Name)
        }(task)
    }

    wg.Wait()
    fmt.Println("\nAll tasks completed!")
}
```

**Kết quả đạt được**:
- GPU tasks (weight=2) chiếm nhiều slots hơn CPU tasks (weight=1).
- Scheduler tự cân bằng: GPU task phải đợi lâu hơn nếu không đủ slots.
- Context timeout bảo vệ toàn bộ — tasks đợi quá lâu sẽ bị cancel.

**Lưu ý**:
- `Release(n)` phải = `Acquire(n)` — release thừa = **panic**.
- Weighted semaphore lý tưởng cho **mixed workloads** (GPU/CPU, heavy/light tasks).
- Nếu tất cả tasks cùng weight=1 → dùng channel semaphore hoặc `errgroup.SetLimit` đơn giản hơn.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Release != Acquire** | Release ĐÚNG SỐ đã Acquire — thừa = panic |
| 2 | **Quên Release** | `defer sem.Release(n)` ngay sau Acquire |
| 3 | **Acquire > max weight** | Acquire(10) với max=5 → deadlock forever |
| 4 | **Không check ctx error** | `Acquire` return error khi ctx cancel — phải handle |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| semaphore package | https://pkg.go.dev/golang.org/x/sync/semaphore |
| Go x/sync repo | https://github.com/golang/sync |
