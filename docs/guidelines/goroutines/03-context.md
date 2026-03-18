# 03 — Context

> **Nền tảng**: Quản lý lifecycle, cancellation, timeout cho goroutines.

---

## ① DEFINE

### Định nghĩa

**`context.Context`** là interface chuẩn trong Go để truyền **deadline, cancellation signal, và request-scoped values** xuyên suốt call chain của goroutines. Context giải quyết vấn đề: "Làm sao dừng tất cả goroutines khi request bị cancel?"

### 4 Constructor Functions

| Function | Tạo context | Cancel khi |
|----------|-------------|-----------|
| `context.Background()` | Root context, không cancel | Không bao giờ — dùng ở `main()`, `init()` |
| `context.WithCancel(parent)` | Manual cancel | Gọi `cancel()` |
| `context.WithTimeout(parent, d)` | Auto cancel sau duration | Hết `d` hoặc gọi `cancel()` |
| `context.WithDeadline(parent, t)` | Auto cancel tại thời điểm | Đến `t` hoặc gọi `cancel()` |
| `context.WithValue(parent, k, v)` | Attach key-value | Khi parent cancel |

### Invariants

- **LUÔN `defer cancel()`** ngay sau `WithCancel/WithTimeout/WithDeadline`
- Context là **immutable** — mỗi `With*` tạo **context con** mới
- Parent cancel → **tất cả child cancel** (cascade)
- Child cancel → parent **KHÔNG bị ảnh hưởng**
- `WithValue` chỉ cho **request-scoped** data (request ID, auth token) — KHÔNG cho business logic

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Goroutine leak** | Không check `ctx.Done()` | Luôn `select { case <-ctx.Done(): return }` |
| **Resource leak** | Quên `defer cancel()` | Luôn defer ngay sau create |
| **Wrong value** | Dùng `WithValue` cho business data | Chỉ dùng cho request metadata |

---

## ② GRAPH

### Context Tree — Cascade Cancellation

```
     context.Background()
              │
     ┌────────┴────────┐
     ▼                  ▼
  WithTimeout(5s)   WithCancel()
  (API handler)     (Background job)
     │                  │
  ┌──┴──┐           ┌──┴──┐
  ▼     ▼           ▼     ▼
 DB    Redis      Worker1 Worker2
Query  Call

  Khi API timeout (5s) → DB Query + Redis Call tự cancel
  Khi Background cancel() → Worker1 + Worker2 tự cancel
  ⚠ Worker1 cancel → Worker2 KHÔNG bị ảnh hưởng
```

### Context trong HTTP Request

```
HTTP Request ──▶ Handler ──▶ Service ──▶ Repository ──▶ Database
                   │            │            │             │
              ctx (timeout)  ctx (same)   ctx (same)   ctx.Done()
                   │                                      ↑
              Client disconnect                    Query cancelled
              → ctx cancel                         → resource freed
```

---

## ③ CODE

---

### Example 1: WithCancel — Manual Cancellation

**Mục tiêu**: Tạo goroutine chạy liên tục, dùng `context.WithCancel` để dừng nó từ bên ngoài.

**Cần gì**: `context` package.

```go
package main

import (
    "context"
    "fmt"
    "time"
)

func worker(ctx context.Context, id int) {
    for {
        select {
        case <-ctx.Done():
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ctx.Done() trả về closed channel khi:
            // - cancel() được gọi
            // - parent context bị cancel
            // ctx.Err() cho biết lý do:
            // - context.Canceled
            // - context.DeadlineExceeded
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            fmt.Printf("[Worker %d] Stopped: %v\n", id, ctx.Err())
            return
        default:
            fmt.Printf("[Worker %d] Working...\n", id)
            time.Sleep(200 * time.Millisecond)
        }
    }
}

func main() {
    // Tạo context với cancel function
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel() // ← LUÔN defer cancel để tránh resource leak

    // Start 3 workers
    for i := 1; i <= 3; i++ {
        go worker(ctx, i)
    }

    // Cho workers chạy 1 giây
    time.Sleep(1 * time.Second)

    // Cancel → tất cả workers nhận signal qua ctx.Done()
    fmt.Println("\n>>> Cancelling all workers...")
    cancel()

    time.Sleep(100 * time.Millisecond) // chờ cleanup
    fmt.Println("Done!")
}
```

**Kết quả đạt được**:
- 3 workers chạy song song trong 1 giây.
- `cancel()` dừng **tất cả** workers cùng lúc (cascade).

**Lưu ý**:
- `cancel()` gọi nhiều lần = safe (idempotent).
- `defer cancel()` phải ở ngay sau `WithCancel` — không để cuối function.

---

### Example 2: WithTimeout — Auto Cancellation

**Mục tiêu**: Tự động cancel sau thời gian chờ. Phù hợp cho API calls, database queries.

**Cần gì**: `context` package + `time` package.

```go
package main

import (
    "context"
    "fmt"
    "math/rand"
    "time"
)

// simulateDBQuery giả lập database query mất thời gian ngẫu nhiên
func simulateDBQuery(ctx context.Context) (string, error) {
    // Tạo channel cho kết quả
    resultCh := make(chan string, 1)

    go func() {
        // Giả lập query mất 100ms - 3000ms
        queryTime := time.Duration(100+rand.Intn(2900)) * time.Millisecond
        time.Sleep(queryTime)
        resultCh <- fmt.Sprintf("Query result (took %v)", queryTime)
    }()

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Select: lấy kết quả hoặc timeout — ai xong trước thắng
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    select {
    case result := <-resultCh:
        return result, nil
    case <-ctx.Done():
        return "", ctx.Err() // context.DeadlineExceeded
    }
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // WithTimeout: tự cancel sau 1 giây
    // Nếu query xong trước 1s → trả kết quả
    // Nếu query chưa xong sau 1s → cancel + return error
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
    defer cancel()

    result, err := simulateDBQuery(ctx)
    if err != nil {
        fmt.Println("❌ Error:", err) // context deadline exceeded
        return
    }
    fmt.Println("✅", result)
}
```

**Kết quả đạt được**:
- Query nhanh (< 1s) → trả kết quả.
- Query chậm (> 1s) → auto cancel, trả `context.DeadlineExceeded`.

**Lưu ý**:
- **HTTP handlers**: dùng `r.Context()` — tự cancel khi client disconnect.
- Timeout nên **ngắn hơn** parent timeout (nesting): parent 5s → child 3s → grandchild 1s.
- Goroutine trong `simulateDBQuery` vẫn chạy sau cancel — chỉ kết quả bị bỏ qua. Nếu cần dừng goroutine thật sự → truyền ctx vào goroutine.

---

### Example 3: Context Cascade — Parent cancel → Children cancel

**Mục tiêu**: Chứng minh cascade cancellation: khi parent cancel, tất cả child contexts tự đóng.

**Cần gì**: `context` package.

```go
package main

import (
    "context"
    "fmt"
    "time"
)

func childWorker(ctx context.Context, name string) {
    <-ctx.Done()
    fmt.Printf("  [%s] Cancelled: %v\n", name, ctx.Err())
}

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Context Tree:
    //   root (Background)
    //     └── parent (WithCancel)
    //           ├── child1 (WithTimeout 5s)
    //           └── child2 (WithCancel)
    //
    // Khi parent cancel → child1 và child2 ĐỀU cancel
    // (dù child1 còn 5s timeout)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    parent, parentCancel := context.WithCancel(context.Background())
    defer parentCancel()

    child1, child1Cancel := context.WithTimeout(parent, 5*time.Second)
    defer child1Cancel()

    child2, child2Cancel := context.WithCancel(parent)
    defer child2Cancel()

    go childWorker(child1, "Child1-Timeout5s")
    go childWorker(child2, "Child2-Manual")

    // Cancel parent sau 500ms
    time.Sleep(500 * time.Millisecond)
    fmt.Println(">>> Cancelling PARENT...")
    parentCancel() // → child1 + child2 đều cancel

    time.Sleep(100 * time.Millisecond)
    fmt.Println("Done!")
}
```

**Kết quả đạt được**:
- Parent cancel → cả child1 (dù còn 5s timeout) và child2 đều cancel ngay.
- `ctx.Err()` = `context.Canceled` (vì parent cancel, không phải timeout).

**Lưu ý**:
- **Child cancel KHÔNG ảnh hưởng parent** — chỉ cascade xuống.
- Trong HTTP middleware: parent = request context, children = DB query, Redis call, etc.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Quên `defer cancel()`** | Resource leak — goroutines không bao giờ freed |
| 2 | **Dùng `WithValue` cho business logic** | Chỉ cho request metadata (request ID, auth) |
| 3 | **Timeout dài hơn parent** | Child timeout 10s, parent 5s → vô nghĩa | Luôn child < parent |
| 4 | **Không check `ctx.Done()`** | Goroutine chạy mãi dù context đã cancel |
| 5 | **Truyền `nil` context** | Luôn dùng `context.Background()` hoặc `context.TODO()` |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Go Blog — Context | https://go.dev/blog/context |
| context package | https://pkg.go.dev/context |
| Go Concurrency Patterns: Context | https://go.dev/talks/2014/gotham-context.slide |

---

## ⑥ RECOMMEND

| Loại | Đề xuất | Ghi chú |
|------|---------|---------|
| **GORM + Context** | `db.WithContext(ctx)` | Mọi DB query nên truyền context — auto cancel khi timeout — xem [go-orm/06](../go-orm/06-migration-and-advanced.md) |
| **HTTP Middleware** | `r.Context()` | Request context tự cancel khi client disconnect |
| **gRPC Context** | `metadata.FromIncomingContext(ctx)` | gRPC truyền context + metadata qua network |
| **OpenTelemetry** | `otel.Tracer` + context | Trace propagation qua context — distributed tracing |
| **errgroup + Context** | `errgroup.WithContext(ctx)` | Cancel nhóm goroutines khi 1 goroutine fail — xem [05-errgroup.md](./05-errgroup.md) |
| **Redis + Context** | `rdb.Get(ctx, key)` | go-redis v9 hỗ trợ context cho mọi operation |
| **Gin/Echo middleware** | `c.Request.Context()` | Web framework context integration |
