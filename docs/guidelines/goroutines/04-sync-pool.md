# 04 — sync.Pool & Buffer Pool

> **Nền tảng**: Object reuse — giảm GC pressure cho high-throughput systems.

---

## ① DEFINE

### sync.Pool

**`sync.Pool`** là pool tái sử dụng object tạm thời (temporary). Thay vì allocate/free liên tục → GET object từ pool, dùng xong PUT lại. Go GC có thể **xóa objects trong pool** bất cứ lúc nào.

### Buffer Pool

**Buffer Pool** là trường hợp phổ biến nhất: pool of `[]byte` buffers. Tránh allocate buffer mới cho mỗi request — quan trọng cho I/O intensive apps (image processing, file upload, network).

### Phân biệt sync.Pool vs Object Pool

| Đặc điểm | sync.Pool | Custom Object Pool |
|-----------|-----------|-------------------|
| **Lifecycle** | GC có thể xóa bất cứ lúc nào | Developer quản lý |
| **Thread-safe** | ✅ Có | Phải tự implement |
| **Use case** | Temporary buffers, scratch objects | Connection pools, worker pools |
| **Guarantee** | KHÔNG đảm bảo object tồn tại | Đảm bảo |

### Invariants

- **Pool objects = temporary** — không dùng cho persistent state
- **LUÔN reset object trước khi Put** — tránh data leak
- **Get() có thể trả object mới** nếu pool rỗng (gọi `New`)
- Pool **per-P (processor)** — mỗi P có local pool riêng → ít contention

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Data leak** | Put object chứa sensitive data | Reset/clear trước khi Put |
| **Wrong type** | Get trả `interface{}`, cast sai | Kiểm tra type sau Get |
| **Performance tệ** | Pool size quá nhỏ, GC xóa liên tục | Benchmark, tune GC |

---

## ② GRAPH

### sync.Pool Lifecycle

```
        Get()                       Put(obj)
          │                            │
  ┌───────▼───────┐           ┌───────▼───────┐
  │   Pool rỗng?  │           │  Reset object │
  │               │           │  (clear data)  │
  └───┬───────┬───┘           └───────┬───────┘
      │       │                       │
     Yes      No                      │
      │       │                       ▼
      ▼       ▼               ┌──────────────┐
  ┌──────┐  ┌──────┐         │  Put vào Pool │
  │ New()│  │Return│         │  (tái sử dụng │
  │ tạo  │  │object│         │   lần sau)    │
  │ mới  │  │từ    │         └──────────────┘
  └──────┘  │pool  │
            └──────┘

  ⚠ GC có thể xóa tất cả objects trong pool giữa 2 GC cycles
```

### Buffer Pool — Request Flow

```
Request 1 ──▶ Get(buf) ──▶ [Process data] ──▶ Reset + Put(buf)
                                                      │
Request 2 ──▶ Get(buf) ◀──── reuse same buffer ◄─────┘
                          (no allocation!)

Without Pool: 1000 requests = 1000 allocations = heavy GC
With Pool:    1000 requests = ~4 allocations (1 per CPU) = light GC
```

---

## ③ CODE

---

### Example 1: Cơ bản — sync.Pool cho []byte buffer

**Mục tiêu**: Tạo pool of byte buffers. Mỗi goroutine GET buffer, dùng, rồi PUT lại — tránh allocate buffer mới mỗi lần.

**Cần gì**: `sync` package.

```go
package main

import (
    "fmt"
    "sync"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Buffer Pool: reuse []byte buffers
    // New: hàm tạo object MỚI khi pool rỗng
    // Get: lấy object từ pool (hoặc tạo mới nếu rỗng)
    // Put: trả object về pool để tái sử dụng
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    bufPool := sync.Pool{
        New: func() interface{} {
            fmt.Println("  [Pool] Creating new buffer (1KB)")
            buf := make([]byte, 1024)
            return buf
        },
    }

    // Lần 1: Pool rỗng → gọi New()
    buf1 := bufPool.Get().([]byte)
    fmt.Printf("Got buf1: len=%d, cap=%d\n", len(buf1), cap(buf1))

    // Sử dụng buffer
    copy(buf1, []byte("Hello, Pool!"))
    fmt.Printf("buf1 content: %s\n", buf1[:12])

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // QUAN TRỌNG: Reset buffer trước khi Put
    // Tránh data leak — buffer cũ có thể chứa sensitive data
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    for i := range buf1 {
        buf1[i] = 0 // clear sensitive data
    }
    bufPool.Put(buf1) // trả lại pool

    // Lần 2: Pool có buffer → tái sử dụng (KHÔNG gọi New)
    buf2 := bufPool.Get().([]byte)
    fmt.Printf("Got buf2: len=%d (reused, no allocation!)\n", len(buf2))
    bufPool.Put(buf2)
}
```

**Kết quả đạt được**:
- Lần Get thứ 1: gọi `New()` — tạo buffer mới.
- Lần Get thứ 2: tái sử dụng — KHÔNG allocate.

**Lưu ý**:
- **LUÔN reset/clear trước Put** — tránh data leak.
- `Get()` trả `interface{}` — cần type assert: `.([]byte)`.
- Go 1.18+: có thể dùng generics wrapper để type-safe.

---

### Example 2: Buffer Pool trong concurrent processing

**Mục tiêu**: Sử dụng buffer pool cho nhiều goroutines đồng thời xử lý data — giảm GC pressure đáng kể.

**Cần gì**: `sync` package, `crypto/sha256` cho simulate work.

```go
package main

import (
    "crypto/sha256"
    "fmt"
    "sync"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Pool of 4KB buffers cho concurrent data processing
    // 100 goroutines xử lý cùng lúc, nhưng chỉ cần ~GOMAXPROCS buffers
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    bufPool := &sync.Pool{
        New: func() interface{} {
            return make([]byte, 4096) // 4KB buffer
        },
    }

    var wg sync.WaitGroup
    results := make(chan string, 100)

    for i := 0; i < 100; i++ {
        wg.Add(1)
        go func(taskID int) {
            defer wg.Done()

            // GET buffer từ pool (tái sử dụng, không allocate)
            buf := bufPool.Get().([]byte)

            // Sử dụng buffer cho processing
            data := fmt.Sprintf("Task-%d-data-payload", taskID)
            copy(buf, []byte(data))

            // Simulate CPU work: hash data
            hash := sha256.Sum256(buf[:len(data)])

            results <- fmt.Sprintf("Task %3d: hash=%x", taskID, hash[:4])

            // ━━━ Reset & PUT buffer lại pool ━━━
            for j := 0; j < len(data); j++ {
                buf[j] = 0
            }
            bufPool.Put(buf)
        }(i)
    }

    // Đóng results khi tất cả goroutines hoàn thành
    go func() {
        wg.Wait()
        close(results)
    }()

    // In kết quả
    count := 0
    for r := range results {
        count++
        if count <= 5 || count == 100 {
            fmt.Println(r)
        }
    }
    fmt.Printf("Total: %d tasks processed\n", count)
}
```

**Kết quả đạt được**:
- 100 goroutines nhưng chỉ tạo ~4-8 buffers (= GOMAXPROCS).
- GC pressure giảm 90%+ so với allocate mới mỗi goroutine.

**Lưu ý**:
- sync.Pool **thread-safe** — không cần thêm mutex.
- Pool **per-P** (processor) → ít lock contention → high performance.
- Sau mỗi GC cycle, Go **có thể xóa toàn bộ** pool items → đừng dựa vào pool cho persistent data.

---

### Example 3: Kết hợp sync.Pool + Tunny Worker Pool (tham chiếu project hiện tại)

**Mục tiêu**: Mô phỏng pattern trong `main.go` của project: Tunny worker pool dùng sync.Pool cho buffer reuse.

**Cần gì**: `sync` package, `github.com/Jeffail/tunny`.

```go
package main

import (
    "fmt"
    "sync"
    "time"
    "math/rand"

    "github.com/Jeffail/tunny"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // sync.Pool: tái sử dụng buffers
    // Tunny Pool: giới hạn concurrency (4 workers)
    // Kết hợp: mỗi worker GET buffer, process, PUT lại
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    bufferPool := sync.Pool{
        New: func() interface{} {
            return make([]byte, 1024)
        },
    }

    pool := tunny.NewFunc(4, func(payload interface{}) interface{} {
        num := payload.(int)

        // GET buffer từ pool — tái sử dụng
        buf := bufferPool.Get().([]byte)
        defer bufferPool.Put(buf) // PUT lại khi worker xong

        // Simulate work bằng buffer
        copy(buf, []byte(fmt.Sprintf("processing-%d", num)))
        time.Sleep(time.Duration(rand.Intn(200)) * time.Millisecond)

        return num * num
    })
    defer pool.Close()

    // Process 20 items qua worker pool
    var wg sync.WaitGroup
    for i := 0; i < 20; i++ {
        wg.Add(1)
        go func(n int) {
            defer wg.Done()
            result := pool.Process(n) // ← block cho đến khi có worker rảnh
            fmt.Printf("%d² = %d\n", n, result.(int))
        }(i)
    }

    wg.Wait()
}
```

**Kết quả đạt được**:
- Chỉ 4 goroutines chạy cùng lúc (Tunny limit).
- Buffers được tái sử dụng giữa các workers (sync.Pool).
- Memory-efficient + CPU-efficient.

**Lưu ý**:
- Đây là pattern dùng trong `cmd/api/main.go` của project.
- Tunny `Process()` là **blocking** — caller goroutine phải đợi worker rảnh.
- `defer bufferPool.Put(buf)` đảm bảo buffer luôn trả lại dù có panic.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên reset trước Put** | Clear sensitive data: `buf[i] = 0` |
| 2 | **Dùng Pool cho persistent data** | GC xóa bất cứ lúc nào → chỉ cho temporary |
| 3 | **Pool object quá lớn** | 1MB buffer × 8 CPUs = 8MB idle | Benchmark buffer size |
| 4 | **Quên type assert** | `Get()` trả `interface{}` | Luôn: `.([]byte)` + check |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| sync.Pool docs | https://pkg.go.dev/sync#Pool |
| Go Blog — sync.Pool | https://go.dev/src/sync/pool.go |
| Effective Go — Allocation | https://go.dev/doc/effective_go#allocation_new |
