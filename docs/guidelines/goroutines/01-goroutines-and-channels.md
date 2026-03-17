# 01 — Goroutines & Channels

> **Nền tảng**: Building block cơ bản nhất — mọi concurrency pattern đều xây trên đây.

---

## ① DEFINE

### Goroutine

**Goroutine** là hàm thực thi đồng thời, quản lý bởi **Go runtime** (không phải OS thread). Nhẹ (~2KB stack, tự grow), cho phép tạo hàng triệu goroutines.

```go
go myFunction()        // tạo goroutine
go func() { ... }()   // anonymous goroutine
```

### Channel

**Channel** là cơ chế giao tiếp giữa goroutines — triết lý Go:

> *"Don't communicate by sharing memory; share memory by communicating."*

### Phân biệt Unbuffered vs Buffered

| Đặc điểm | Unbuffered `make(chan T)` | Buffered `make(chan T, N)` |
|-----------|--------------------------|---------------------------|
| **Sync** | Sender & Receiver đồng bộ hoàn toàn | Sender chỉ block khi buffer đầy |
| **Use case** | Handoff, signaling | Decouple tốc độ producer/consumer |
| **Throughput** | Thấp hơn (đợi nhau) | Cao hơn (có buffer đệm) |
| **Deadlock risk** | Cao nếu quên receiver | Thấp hơn nhưng vẫn có |

### Directional Channels

| Kiểu | Syntax | Ý nghĩa |
|------|--------|---------|
| Bidirectional | `chan T` | Gửi và nhận |
| Send-only | `chan<- T` | Chỉ gửi — compiler enforce |
| Receive-only | `<-chan T` | Chỉ nhận — compiler enforce |

### Select

**`select`** là multiplexer — chờ nhiều channel operations cùng lúc. Khi nhiều case ready → Go chọn **ngẫu nhiên** (fairness).

### Actors

| Actor | Vai trò |
|-------|---------|
| **Goroutine** | Đơn vị thực thi concurrent |
| **Channel** | Ống dẫn dữ liệu giữa goroutines |
| **Go Scheduler** | M:N scheduler — map M goroutines lên N OS threads |
| **`select`** | Multiplexer — chờ nhiều channel cùng lúc |

### Invariants

- **Channel closed only by sender** — receiver KHÔNG BAO GIỜ close
- **Close chỉ 1 lần** — close channel đã close → `panic`
- **Send to closed channel → `panic`**
- **Receive from closed channel → zero value** — dùng `v, ok := <-ch`

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Goroutine leak** | G block mãi trên channel | Luôn dùng `context.Context` |
| **Deadlock** | Tất cả G đều block | Sender/receiver phải paired |
| **Race condition** | Shared memory không sync | Dùng channel thay shared memory |
| **Panic on closed** | Send to closed channel | Chỉ sender close |

---

## ② GRAPH

### Goroutine vs OS Thread (M:N Scheduling)

```
OS Threads (N=3)           Goroutines (M=6)
┌──────────┐              ┌───┐ ┌───┐ ┌───┐
│ Thread 1 │◄─────────────┤G1 │ │G2 │ │G3 │    Go Scheduler tự động
└──────────┘              └───┘ └───┘ └───┘    phân phối G lên Thread.
┌──────────┐              ┌───┐ ┌───┐
│ Thread 2 │◄─────────────┤G4 │ │G5 │          Khi G1 bị block (I/O),
└──────────┘              └───┘ └───┘          scheduler chuyển G khác
┌──────────┐              ┌───┐                lên Thread 1.
│ Thread 3 │◄─────────────┤G6 │
└──────────┘              └───┘
```

### Unbuffered Channel — Synchronous Handoff

```
  Goroutine A                Channel (cap=0)           Goroutine B
  ───────────               ─────────────              ───────────
       │                         │                          │
   ch <- 42  ─── BLOCK ────────▶│                          │
       │                        │◀── BLOCK ──────── v := <-ch
       │                        │                          │
       │◀── UNBLOCK (handoff) ──│── UNBLOCK ──────────────▶│
       │                        │                     v = 42│
```

### Buffered Channel — Async Queue

```
  Goroutine A             Channel (cap=3)           Goroutine B
  ───────────            ┌───┬───┬───┐              ───────────
   ch <- 1  ────────────▶│ 1 │   │   │  (no block)
   ch <- 2  ────────────▶│ 1 │ 2 │   │  (no block)
   ch <- 3  ────────────▶│ 1 │ 2 │ 3 │  (no block)
   ch <- 4  ── BLOCK ───▶│ 1 │ 2 │ 3 │  (buffer full!)
                         │   │   │   │◀────── v := <-ch
                         │ 2 │ 3 │ 4 │  (A unblocked)   v=1
```

### Select — Multiplexing

```
              ┌── ch1 ──▶ case <-ch1: ...
              │
  select ◄────┼── ch2 ──▶ case msg := <-ch2: ...
              │
              ├── ch3 ──▶ case ch3 <- val: ...
              │
              └── ────── ▶ default: ... (non-blocking)
```

---

## ③ CODE

---

### Example 1: Unbuffered Channel — Synchronous Handoff

**Mục tiêu**: Hiểu cách unbuffered channel đồng bộ hóa 2 goroutines. Sender block cho đến khi receiver ready, tạo ra một "handoff" (chuyển giao) hoàn chỉnh.

**Cần gì**: Chỉ cần Go standard library.

```go
package main

import "fmt"

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Unbuffered channel: capacity = 0
    // Sender BLOCK cho đến khi có receiver ready.
    // Receiver BLOCK cho đến khi có sender ready.
    // → Hai bên "bắt tay" — synchronous handoff.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ch := make(chan string) // unbuffered — capacity = 0

    // Goroutine: gửi message
    go func() {
        fmt.Println("[Sender] Preparing message...")
        ch <- "Hello from goroutine!" // ← BLOCK ở đây cho đến main nhận
        fmt.Println("[Sender] Message sent!")
    }()

    // Main goroutine: nhận message
    msg := <-ch // ← BLOCK ở đây cho đến goroutine gửi
    fmt.Println("[Main] Received:", msg)
}
```

**Kết quả đạt được**:
- Hiểu cách unbuffered channel tạo synchronization point giữa 2 goroutines.
- Thứ tự in: `[Sender] Preparing...` → `[Main] Received...` → `[Sender] Message sent!`

**Lưu ý**:
- Nếu không có goroutine nhận: **deadlock** — `fatal error: all goroutines are asleep`
- Unbuffered channel phù hợp cho **signaling** và **handoff**, KHÔNG phải cho high-throughput data.

---

### Example 2: Buffered Channel — Producer/Consumer

**Mục tiêu**: Decouple tốc độ giữa producer (nhanh) và consumer (chậm) bằng buffered channel. Producer có thể gửi tối đa N items mà không bị block.

**Cần gì**: Go standard library + `time` package.

```go
package main

import (
    "fmt"
    "time"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Buffered channel: capacity = 5
    // Producer gửi tối đa 5 items mà không block.
    // Chỉ block khi buffer đầy (5/5).
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    jobs := make(chan int, 5) // buffered — capacity = 5

    // Producer: tạo 10 jobs (nhanh)
    go func() {
        defer close(jobs) // ← QUAN TRỌNG: chỉ sender close channel
        for i := 1; i <= 10; i++ {
            fmt.Printf("→ Producing job %d\n", i)
            jobs <- i // block khi buffer đầy (5/5)
        }
        fmt.Println("→ Producer done!")
    }()

    // Consumer: xử lý jobs (chậm — 200ms mỗi job)
    for job := range jobs { // ← range tự dừng khi channel đóng
        fmt.Printf("  ← Processing job %d\n", job)
        time.Sleep(200 * time.Millisecond)
    }

    fmt.Println("All jobs done!")
}
```

**Kết quả đạt được**:
- Producer gửi nhanh 5 jobs đầu tiên (không block).
- Từ job thứ 6, producer block cho đến khi consumer xử lý xong 1 job → buffer có chỗ.
- `range` tự động dừng khi `close(jobs)` được gọi.

**Lưu ý**:
- **Buffer size = throughput tuning**: quá nhỏ → producer block nhiều, quá lớn → tốn memory.
- **Rule of thumb**: buffer size = số items mà consumer xử lý trong 1 burst.
- **LUÔN `defer close(ch)`** ở phía sender — quên close → consumer block forever (goroutine leak).

---

### Example 3: Directional Channels — Type Safety

**Mục tiêu**: Dùng directional channels (`chan<-` và `<-chan`) để compiler enforce ai được gửi, ai được nhận — tránh bugs ở compile time.

**Cần gì**: Go standard library.

```go
package main

import "fmt"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Directional channels giúp compiler kiểm tra:
// - producer chỉ SEND (chan<- T)
// - consumer chỉ RECEIVE (<-chan T)
// Nếu viết sai → compile error, không phải runtime bug.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// producer chỉ có thể GỬI vào channel
func producer(out chan<- int, count int) {
    defer close(out)
    for i := 0; i < count; i++ {
        out <- i * i
    }
    // out = <-out  // ← COMPILE ERROR: cannot receive from send-only channel
}

// consumer chỉ có thể NHẬN từ channel
func consumer(in <-chan int) {
    for v := range in {
        fmt.Printf("Received: %d\n", v)
    }
    // in <- 42  // ← COMPILE ERROR: cannot send to receive-only channel
}

func main() {
    ch := make(chan int, 5) // bidirectional

    go producer(ch, 5) // ch tự cast → chan<- int
    consumer(ch)       // ch tự cast → <-chan int
}
```

**Kết quả đạt được**:
- Compiler enforce: producer không thể nhận, consumer không thể gửi.
- Bugs phát hiện tại **compile time** thay vì runtime.

**Lưu ý**:
- Go tự động cast `chan T` → `chan<- T` hoặc `<-chan T` khi truyền vào function.
- Luôn dùng directional channels trong function signatures — đây là **Go convention**.

---

### Example 4: Select — Timeout, Multiple Channels, Non-blocking

**Mục tiêu**: Sử dụng `select` để xử lý nhiều channel đồng thời với timeout, tạo non-blocking operations, và xử lý cancellation.

**Cần gì**: Go standard library + `time` package.

```go
package main

import (
    "fmt"
    "math/rand"
    "time"
)

func main() {
    ch1 := make(chan string)
    ch2 := make(chan string)

    // Goroutine 1: response chậm (500-1500ms)
    go func() {
        time.Sleep(time.Duration(500+rand.Intn(1000)) * time.Millisecond)
        ch1 <- "Response from Service A"
    }()

    // Goroutine 2: response nhanh hơn (100-500ms)
    go func() {
        time.Sleep(time.Duration(100+rand.Intn(400)) * time.Millisecond)
        ch2 <- "Response from Service B"
    }()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Select: chờ response từ cả 2 services
    // Ai respond trước → xử lý trước (non-deterministic)
    // Timeout sau 1 giây nếu cả 2 chưa respond.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    for i := 0; i < 2; i++ {
        select {
        case msg := <-ch1:
            fmt.Println("✅", msg)
        case msg := <-ch2:
            fmt.Println("✅", msg)
        case <-time.After(1 * time.Second):
            fmt.Println("⏰ Timeout!")
            return
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Non-blocking select: dùng default
    // Nếu không case nào ready → chạy default ngay
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ch3 := make(chan int, 1)
    select {
    case v := <-ch3:
        fmt.Println("Got:", v)
    default:
        fmt.Println("Channel empty — not blocking!")
    }
}
```

**Kết quả đạt được**:
- Xử lý multi-channel I/O đồng thời.
- Timeout mechanism bằng `time.After`.
- Non-blocking check bằng `default`.

**Lưu ý**:
- `time.After` tạo goroutine mỗi lần gọi — trong vòng lặp nên dùng `time.NewTimer` + `timer.Reset`.
- Khi nhiều case ready cùng lúc → Go chọn **ngẫu nhiên** (fair scheduling).
- `default` biến select thành non-blocking — cẩn thận busy loop nếu dùng trong `for`.

---

### Example 5: Channel Patterns — Done Signal & For-Select Loop

**Mục tiêu**: Pattern phổ biến nhất — dùng `done` channel để signal goroutine dừng, kết hợp for-select loop cho long-running goroutine.

**Cần gì**: Go standard library.

```go
package main

import (
    "fmt"
    "time"
)

// worker chạy liên tục cho đến khi nhận signal dừng từ done channel
func worker(id int, done <-chan struct{}, results chan<- string) {
    defer fmt.Printf("[Worker %d] Cleaned up and exiting\n", id)

    counter := 0
    for {
        select {
        case <-done:
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // done channel được close → tất cả
            // goroutines đang listen sẽ nhận được signal
            // (close broadcast cho tất cả receivers)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            return
        default:
            counter++
            results <- fmt.Sprintf("Worker %d: item %d", id, counter)
            time.Sleep(100 * time.Millisecond)
        }
    }
}

func main() {
    done := make(chan struct{}) // signal channel — dùng struct{} vì zero memory
    results := make(chan string, 10)

    // Start 3 workers
    for i := 1; i <= 3; i++ {
        go worker(i, done, results)
    }

    // Thu thập kết quả trong 500ms
    timeout := time.After(500 * time.Millisecond)
    count := 0
loop:
    for {
        select {
        case msg := <-results:
            fmt.Println(msg)
            count++
        case <-timeout:
            fmt.Printf("\n⏰ Timeout! Collected %d results\n", count)
            break loop
        }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // close(done) → broadcast signal đến TẤT CẢ workers
    // Mọi goroutine đang select <-done sẽ nhận được.
    // Đây là cancel pattern CƠ BẢN trước khi có context.
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    close(done)
    time.Sleep(100 * time.Millisecond) // chờ workers cleanup
}
```

**Kết quả đạt được**:
- `close(done)` broadcast signal → tất cả goroutines dừng cùng lúc.
- `struct{}` channel dùng 0 bytes — convention cho signal channels.
- For-select loop là pattern phổ biến nhất cho long-running goroutines.

**Lưu ý**:
- `done` channel pattern là tiền thân của `context.Context` — trong production nên dùng context.
- `break` trong select chỉ break select, **KHÔNG break for** — cần label (`break loop`).
- Dùng `struct{}` cho done channel vì chỉ cần signal, không cần data.

---

## ④ PITFALLS

| # | Lỗi | Code SAI | Code ĐÚNG |
|---|------|----------|-----------|
| 1 | **Goroutine leak** | `go func() { <-ch }()` — không ai close `ch` | Dùng `context.WithCancel` hoặc `close(ch)` |
| 2 | **Close từ receiver** | Receiver gọi `close(ch)` | Chỉ **sender** close channel |
| 3 | **Send to closed** | `close(ch); ch <- 1` → panic | Dùng `sync.Once` hoặc check state |
| 4 | **Quên range/ok** | `for { v := <-ch }` — loop vô tận | `for v := range ch` hoặc `v, ok := <-ch` |
| 5 | **Unbuffered deadlock** | `ch := make(chan int); ch <- 1` cùng goroutine | Dùng buffered hoặc goroutine riêng |
| 6 | **time.After trong loop** | `for { select { case <-time.After(1s) } }` — leak timer | Dùng `time.NewTimer` + `timer.Reset()` |
| 7 | **break trong select** | `break` chỉ thoát select, không thoát for | Dùng label: `break outerLoop` |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Go Tour — Concurrency | https://go.dev/tour/concurrency |
| Effective Go — Concurrency | https://go.dev/doc/effective_go#concurrency |
| Go Blog — Share Memory By Communicating | https://go.dev/blog/codelab-share |
| Go Blog — Pipelines and Cancellation | https://go.dev/blog/pipelines |
