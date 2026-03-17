# 09 — Or-done & Tee Channels

> **Nâng cao**: Channel patterns cho composition — xử lý done signals và channel splitting.

---

## ① DEFINE

### Or-done Channel

**Or-done** pattern wraps một channel read để tự động abort khi `done` (hoặc `ctx.Done()`) signal. Thay vì viết `select { case <-done; case v := <-ch }` ở mọi nơi → extract thành helper function.

### Tee Channel

**Tee** channel nhận 1 input → split thành **2 outputs** hoàn toàn giống nhau (giống lệnh `tee` trong Unix). Mọi value từ input được gửi vào CẢ 2 output channels.

### Or Channel

**Or** channel combine N `done` channels → 1 channel đóng khi **BẤT KỲ** input channel nào đóng. Pattern cho "first one wins" — race nhiều operations.

### Use cases

| Pattern | Use case |
|---------|---------|
| **Or-done** | Wrap channel reads trong pipeline stages để dễ cancel |
| **Tee** | Gửi dữ liệu cho 2 consumers khác nhau (log + process) |
| **Or** | Race timeout vs result, first successful response |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Goroutine leak (tee)** | Consumer chậm → tee goroutine block | Buffer channels hoặc context |
| **Or channel leak** | Recursive goroutines không cleanup | Dùng context.Context thay thế |
| **Tee out-of-sync** | 1 consumer nhanh, 1 chậm → block cả hai | Dùng buffered channels hoặc async consumers |

---

## ② GRAPH

### Or-done Pattern

```
Trước (verbose):                    Sau (or-done wrapper):

for {                               for v := range orDone(ctx, ch) {
    select {                             process(v)
    case <-ctx.Done():               }
        return
    case v, ok := <-ch:
        if !ok { return }
        process(v)
    }
}

→ Giảm boilerplate, readable hơn
```

### Tee Channel

```
                      ┌──▶ output1 ──▶ Consumer A (log)
  input ──▶ tee() ───┤
                      └──▶ output2 ──▶ Consumer B (process)

  Mỗi value từ input → copy vào CẢ 2 outputs
  input: [1, 2, 3]
  output1: [1, 2, 3]  (exact copy)
  output2: [1, 2, 3]  (exact copy)
```

### Or Channel

```
  done1 ──┐
           │
  done2 ──┼──▶ or() ──▶ closes khi BẤT KỲ input đóng
           │
  done3 ──┘

  Timeline:
  done1: ━━━━━━━━━━━ (vẫn mở)
  done2: ━━━━ close!
  done3: ━━━━━━━━━━━ (vẫn mở)
  or():  ━━━━ close! ← done2 đóng → or đóng ngay
```

---

## ③ CODE

---

### Example 1: Or-done — Clean channel iteration with cancellation

**Mục tiêu**: Tạo `orDone` helper function — wraps `<-chan T` thành cancellation-aware iteration. Giảm boilerplate `select { case <-done }` trong mọi pipeline stage.

**Cần gì**: Go standard library, `context` package.

```go
package main

import (
    "context"
    "fmt"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// orDone: wraps channel read with context cancellation
//
// TRƯỚC (verbose — phải viết ở MỌI nơi đọc channel):
//   for {
//       select {
//       case <-ctx.Done(): return
//       case v, ok := <-ch:
//           if !ok { return }
//           // use v
//       }
//   }
//
// SAU (clean — dùng range):
//   for v := range orDone(ctx, ch) {
//       // use v
//   }
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func orDone[T any](ctx context.Context, ch <-chan T) <-chan T {
    out := make(chan T)
    go func() {
        defer close(out)
        for {
            select {
            case <-ctx.Done():
                return
            case v, ok := <-ch:
                if !ok {
                    return // channel closed
                }
                select {
                case out <- v:
                case <-ctx.Done():
                    return
                }
            }
        }
    }()
    return out
}

// Simulate data source
func dataSource(count int) <-chan int {
    ch := make(chan int)
    go func() {
        defer close(ch)
        for i := 1; i <= count; i++ {
            ch <- i
            time.Sleep(100 * time.Millisecond)
        }
    }()
    return ch
}

func main() {
    // ━━━ Context cancel sau 350ms ━━━
    ctx, cancel := context.WithTimeout(context.Background(), 350*time.Millisecond)
    defer cancel()

    source := dataSource(100) // sản xuất 100 items (10s nếu không cancel)

    // ━━━ orDone: tự dừng khi context cancel ━━━
    fmt.Println("Reading with orDone (auto-cancel at 350ms):")
    count := 0
    for v := range orDone(ctx, source) {
        count++
        fmt.Printf("  Received: %d\n", v)
    }
    fmt.Printf("Stopped after %d items (ctx: %v)\n", count, ctx.Err())
}
```

**Kết quả đạt được**:
- Đọc ~3 items (300ms) rồi auto-stop khi context timeout (350ms).
- `orDone` dùng generics (Go 1.18+) — type-safe, reusable cho bất kỳ `<-chan T`.
- Code clean: `for v := range orDone(ctx, ch)` thay vì nested select.

**Lưu ý**:
- `orDone` tạo 1 goroutine — overhead nhỏ nhưng có. Chỉ dùng khi cần cancellation.
- Inner `select` cần 2 case (`out <- v` + `ctx.Done()`) — tránh block trên send khi ctx cancel.
- Go 1.18+: dùng generics `[T any]`. Go cũ: dùng `interface{}`.

---

### Example 2: Tee Channel — Split 1 input thành 2 outputs

**Mục tiêu**: Tạo `tee` function — gửi mỗi value vào CẢ 2 channels. Use case: log stream + processing stream từ cùng 1 source.

**Cần gì**: Go standard library, `context` package.

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// tee: split 1 input channel → 2 output channels
//
// Mỗi value từ input được gửi vào CẢ 2 outputs.
// ⚠ CẢ 2 consumers phải đọc — nếu 1 consumer chậm
//    → block tee goroutine → block cả consumer kia.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func tee[T any](ctx context.Context, in <-chan T) (<-chan T, <-chan T) {
    out1 := make(chan T)
    out2 := make(chan T)

    go func() {
        defer close(out1)
        defer close(out2)
        for val := range orDone(ctx, in) {
            // ━━━ Gửi vào CẢ 2 channels ━━━
            // Dùng local vars vì select case chỉ cho 1 channel
            var o1, o2 = out1, out2
            for i := 0; i < 2; i++ {
                select {
                case <-ctx.Done():
                    return
                case o1 <- val:
                    o1 = nil // ← đã gửi o1, disable case này
                case o2 <- val:
                    o2 = nil // ← đã gửi o2, disable case này
                }
            }
        }
    }()

    return out1, out2
}

// orDone helper (same as Example 1)
func orDone[T any](ctx context.Context, ch <-chan T) <-chan T {
    out := make(chan T)
    go func() {
        defer close(out)
        for {
            select {
            case <-ctx.Done():
                return
            case v, ok := <-ch:
                if !ok {
                    return
                }
                select {
                case out <- v:
                case <-ctx.Done():
                    return
                }
            }
        }
    }()
    return out
}

func main() {
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    // ━━━ Source: generate 1..5 ━━━
    source := make(chan int)
    go func() {
        defer close(source)
        for i := 1; i <= 5; i++ {
            source <- i
            time.Sleep(50 * time.Millisecond)
        }
    }()

    // ━━━ Tee: split source → logger + processor ━━━
    logStream, processStream := tee(ctx, source)

    var wg sync.WaitGroup

    // Consumer A: Logger (log tất cả values)
    wg.Add(1)
    go func() {
        defer wg.Done()
        for v := range logStream {
            fmt.Printf("  [Logger]    value=%d\n", v)
        }
    }()

    // Consumer B: Processor (transform values)
    wg.Add(1)
    go func() {
        defer wg.Done()
        for v := range processStream {
            fmt.Printf("  [Processor] value=%d → %d²=%d\n", v, v, v*v)
        }
    }()

    wg.Wait()
    fmt.Println("\nBoth consumers received all values!")
}
```

**Kết quả đạt được**:
- 1 source → 2 consumers: Logger và Processor nhận CÙNG dữ liệu.
- Tee implementation dùng `nil channel trick`: set channel = nil sau khi gửi → select skip case đó.

**Lưu ý**:
- **CẢ 2 consumers PHẢI đọc** — nếu 1 consumer block → block cả 2.  
  Fix: dùng buffered channels hoặc async consumer wrappers.
- `nil channel trick`: `case ch <- v:` với `ch = nil` → select **bỏ qua** case đó (never ready). Đây là Go idiom.
- Tee tạo **copy** — cả 2 consumers nhận cùng value, không chia nhau (khác fan-out).

---

### Example 3: Or Channel — First one wins

**Mục tiêu**: Combine nhiều `done` channels thành 1 — đóng khi BẤT KỲ input nào đóng. Use case: race timeout vs result, hoặc multiple cancellation sources.

**Cần gì**: Go standard library.

```go
package main

import (
    "fmt"
    "time"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// or: combine N done channels → 1
// Đóng khi BẤT KỲ input channel nào đóng.
//
// Cách hoạt động:
// - Base case: 0 channels → nil, 1 channel → return nó
// - 2+ channels: select trên tất cả, ai đóng trước → return
// - Recursive: chia đôi nhóm, or mỗi nửa, rồi or kết quả
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func or(channels ...<-chan struct{}) <-chan struct{} {
    switch len(channels) {
    case 0:
        return nil
    case 1:
        return channels[0]
    }

    orDone := make(chan struct{})
    go func() {
        defer close(orDone)
        switch len(channels) {
        case 2:
            select {
            case <-channels[0]:
            case <-channels[1]:
            }
        default:
            // Split & recurse
            mid := len(channels) / 2
            select {
            case <-or(channels[:mid]...):
            case <-or(channels[mid:]...):
            }
        }
    }()
    return orDone
}

// after: tạo channel đóng sau duration d
func after(d time.Duration) <-chan struct{} {
    ch := make(chan struct{})
    go func() {
        defer close(ch)
        time.Sleep(d)
    }()
    return ch
}

func main() {
    start := time.Now()

    // ━━━ 5 signals với thời gian khác nhau ━━━
    // or() đóng khi signal ĐẦU TIÊN đóng (100ms)
    done := or(
        after(2*time.Second),
        after(500*time.Millisecond),
        after(100*time.Millisecond), // ← fastest!
        after(1*time.Second),
        after(3*time.Second),
    )

    <-done // ← block cho đến khi 1 signal đóng
    fmt.Printf("Signaled after %v\n", time.Since(start)) // ~100ms

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Use case: Race API call vs timeout
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    fmt.Println("\n=== Race: API call vs timeout ===")

    apiResult := make(chan struct{})
    timeout := after(300 * time.Millisecond)

    // Simulate API call
    go func() {
        time.Sleep(200 * time.Millisecond) // API responds in 200ms
        close(apiResult)
    }()

    select {
    case <-apiResult:
        fmt.Println("✅ API responded!")
    case <-timeout:
        fmt.Println("❌ Timeout!")
    }
}
```

**Kết quả đạt được**:
- `or()` đóng sau ~100ms — signal nhanh nhất thắng.
- Race pattern: API call vs timeout — ai xong trước thắng.

**Lưu ý**:
- Trong production, **`context.Context`** thay thế hầu hết use cases của `or()`.
- `or()` recursive tạo O(log N) goroutines — ok cho vài channels, cẩn thận với nhiều.
- `after()` helper tạo `<-chan struct{}` từ duration — reusable.

---

### Example 4: Kết hợp — Or-done + Tee trong Pipeline

**Mục tiêu**: Pipeline production: source → orDone (cancellation) → tee (split) → 2 consumers. Kết hợp tất cả patterns.

**Cần gì**: All patterns từ examples trước.

```go
package main

import (
    "context"
    "fmt"
    "sync"
    "time"
)

func orDonePipeline[T any](ctx context.Context, ch <-chan T) <-chan T {
    out := make(chan T)
    go func() {
        defer close(out)
        for {
            select {
            case <-ctx.Done():
                return
            case v, ok := <-ch:
                if !ok {
                    return
                }
                select {
                case out <- v:
                case <-ctx.Done():
                    return
                }
            }
        }
    }()
    return out
}

func teePipeline[T any](ctx context.Context, in <-chan T) (<-chan T, <-chan T) {
    out1 := make(chan T)
    out2 := make(chan T)
    go func() {
        defer close(out1)
        defer close(out2)
        for val := range orDonePipeline(ctx, in) {
            var o1, o2 = out1, out2
            for i := 0; i < 2; i++ {
                select {
                case <-ctx.Done():
                    return
                case o1 <- val:
                    o1 = nil
                case o2 <- val:
                    o2 = nil
                }
            }
        }
    }()
    return out1, out2
}

func main() {
    // ━━━ Context: auto cancel after 800ms ━━━
    ctx, cancel := context.WithTimeout(context.Background(), 800*time.Millisecond)
    defer cancel()

    // ━━━ Source: stream of events ━━━
    events := make(chan string)
    go func() {
        defer close(events)
        for i := 1; i <= 100; i++ {
            select {
            case <-ctx.Done():
                return
            case events <- fmt.Sprintf("event-%d", i):
                time.Sleep(100 * time.Millisecond)
            }
        }
    }()

    // ━━━ Pipeline: source → orDone → tee → 2 consumers ━━━
    safe := orDonePipeline(ctx, events)     // cancellation-safe stream
    logCh, processCh := teePipeline(ctx, safe) // split into 2

    var wg sync.WaitGroup

    // Consumer 1: Logger — ghi log tất cả events
    wg.Add(1)
    go func() {
        defer wg.Done()
        for e := range logCh {
            fmt.Printf("  📋 [LOG] %s\n", e)
        }
        fmt.Println("  📋 [LOG] Stream ended")
    }()

    // Consumer 2: Analytics — đếm events
    wg.Add(1)
    go func() {
        defer wg.Done()
        count := 0
        for range processCh {
            count++
        }
        fmt.Printf("  📊 [ANALYTICS] Total events: %d\n", count)
    }()

    wg.Wait()
    fmt.Printf("\n✅ Pipeline completed (ctx: %v)\n", ctx.Err())
}
```

**Kết quả đạt được**:
- Source → orDone (auto-cancel at 800ms) → tee → Logger + Analytics.
- ~7-8 events rồi auto-stop (800ms / 100ms = ~8 events).
- CẢ 2 consumers nhận CÙNG events, dừng cùng lúc.

**Lưu ý**:
- `orDone` + `tee` kết hợp tạo **composable pipeline primitives**.
- Trong production: có thể thêm filter, transform stages giữa orDone và tee.
- Pattern này phổ biến trong **event streaming**, **log processing**, **monitoring**.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Tee consumer chậm** | Block CẢ 2 consumers | Buffer channels hoặc timeout |
| 2 | **Or channel goroutine leak** | Recursive goroutines | Dùng context thay thế |
| 3 | **Quên close inner channels** | Goroutine leak | Luôn `defer close(out)` |
| 4 | **Or-done double select** | Cần 2 select (receive + send) | Template code ở Example 1 |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Concurrency in Go (O'Reilly) Ch.4 | ISBN: 978-1491941195 |
| Go Blog — Advanced Concurrency | https://go.dev/talks/2013/advconc.slide |
| Go Concurrency Patterns (Rob Pike) | https://go.dev/talks/2012/concurrency.slide |
