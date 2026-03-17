# 15 — Asynq

> **Library**: `github.com/hibiken/asynq` — Distributed task queue (Redis-backed).

---

## ① DEFINE

### Định nghĩa

**Asynq** là distributed task queue cho Go, sử dụng **Redis** làm message broker. Khác với in-process worker pools (Tunny, Ants), Asynq cho phép **queue tasks across multiple processes/servers** — phù hợp cho background jobs, scheduled tasks, email sending, etc.

### Phân biệt In-process Pool vs Distributed Queue

| Đặc điểm | In-process (Tunny/Ants) | Distributed (Asynq) |
|-----------|------------------------|---------------------|
| **Scope** | 1 process | Multi-process, multi-server |
| **State** | Memory | Redis (persistent) |
| **Retry** | DIY | Built-in (exponential backoff) |
| **Scheduling** | ❌ | ✅ Cron, delayed tasks |
| **Dashboard** | ❌ | ✅ Asynqmon Web UI |
| **Use case** | CPU/IO tasks in-process | Background jobs, emails, webhooks |

### Core Components

| Component | Vai trò |
|-----------|---------|
| `asynq.Client` | Enqueue tasks → Redis |
| `asynq.Server` | Dequeue + execute tasks từ Redis |
| `asynq.ServeMux` | Route tasks đến handlers (giống http.ServeMux) |
| `asynq.Task` | Task = type name + payload (JSON) |
| `asynq.Scheduler` | Cron-based scheduled tasks |

### Invariants

- Tasks persist trong Redis — server restart → tasks vẫn có
- Mỗi task xử lý **at-least-once** — cần idempotent handlers
- Retry automatic với exponential backoff
- Dead-letter queue cho tasks fail quá N lần

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Duplicate processing** | At-least-once delivery | Idempotent handlers |
| **Redis down** | Single point of failure | Redis Sentinel/Cluster |
| **Payload too large** | Redis memory | Lưu data ở DB, chỉ queue references |

---

## ② GRAPH

### Asynq Architecture

```
  ┌─────────────┐        ┌──────────┐        ┌─────────────────┐
  │  API Server │──Task──▶│  Redis   │◀──Poll──│  Worker Server  │
  │  (Client)   │        │  Queue   │        │  (asynq.Server) │
  └─────────────┘        └──────────┘        └────────┬────────┘
                                                      │
                              ┌────────────────────────┴──────┐
                              │         ServeMux              │
                              │  "email:welcome" → Handler    │
                              │  "order:process" → Handler    │
                              │  "report:daily"  → Handler    │
                              └───────────────────────────────┘
```

### Task Lifecycle

```
  Client.Enqueue(task) → Redis → Worker picks up → Handler executes
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                  ▼
                  OK ✅          Error (retry)      Error (dead)
               (completed)    (back to queue)     (exceeded max)
                                 retry 1,2,3...     → dead queue
                               (exponential delay)
```

---

## ③ CODE

---

### Example 1: Cơ bản — Task definition, enqueue, handler

**Mục tiêu**: Tạo task type, enqueue từ API server, xử lý ở worker server. Complete flow.

**Cần gì**: `go get github.com/hibiken/asynq`, Redis running.

```go
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// tasks/email.go — Task definition (shared giữa client + worker)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
package tasks

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "time"

    "github.com/hibiken/asynq"
)

// Task type name — convention: "module:action"
const TypeEmailWelcome = "email:welcome"

// Payload: data cần cho task (serialize sang JSON)
type EmailWelcomePayload struct {
    UserID int    `json:"user_id"`
    Email  string `json:"email"`
    Name   string `json:"name"`
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NewEmailWelcomeTask: tạo task để enqueue
// Payload serialize thành JSON → lưu vào Redis
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func NewEmailWelcomeTask(userID int, email, name string) (*asynq.Task, error) {
    payload, err := json.Marshal(EmailWelcomePayload{
        UserID: userID,
        Email:  email,
        Name:   name,
    })
    if err != nil {
        return nil, err
    }

    return asynq.NewTask(
        TypeEmailWelcome,
        payload,
        asynq.MaxRetry(3),              // Retry tối đa 3 lần
        asynq.Timeout(30*time.Second),   // Timeout mỗi lần thực thi
        asynq.Queue("emails"),           // Queue name (priority routing)
    ), nil
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// HandleEmailWelcome: handler xử lý task
// ⚠ Phải IDEMPOTENT — có thể được gọi > 1 lần (retry)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
func HandleEmailWelcome(ctx context.Context, t *asynq.Task) error {
    var payload EmailWelcomePayload
    if err := json.Unmarshal(t.Payload(), &payload); err != nil {
        return fmt.Errorf("unmarshal payload: %w", err) // non-retryable
    }

    log.Printf("📧 Sending welcome email to %s (%s)...", payload.Name, payload.Email)

    // Simulate sending email
    time.Sleep(500 * time.Millisecond)

    log.Printf("✅ Welcome email sent to %s", payload.Email)
    return nil // ← success: task completed
    // return error → auto retry (up to MaxRetry)
}
```

```go
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// cmd/client/main.go — Enqueue tasks (API server side)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
package main

import (
    "log"

    "github.com/hibiken/asynq"
    "myapp/tasks"
)

func main() {
    // Kết nối Redis
    client := asynq.NewClient(asynq.RedisClientOpt{
        Addr: "localhost:6379",
    })
    defer client.Close()

    // ━━━ Enqueue: đẩy task vào Redis queue ━━━
    task, err := tasks.NewEmailWelcomeTask(1, "alice@example.com", "Alice")
    if err != nil {
        log.Fatal(err)
    }

    info, err := client.Enqueue(task)
    if err != nil {
        log.Fatal(err)
    }

    log.Printf("Enqueued: id=%s queue=%s", info.ID, info.Queue)

    // ━━━ Delayed task: thực thi sau 1 giờ ━━━
    task2, _ := tasks.NewEmailWelcomeTask(2, "bob@example.com", "Bob")
    info, err = client.Enqueue(task2, asynq.ProcessIn(1*time.Hour))
    // Task sẽ được process sau 1 giờ
}
```

```go
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// cmd/worker/main.go — Worker server (xử lý tasks)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
package main

import (
    "log"

    "github.com/hibiken/asynq"
    "myapp/tasks"
)

func main() {
    // ━━━ Server config ━━━
    srv := asynq.NewServer(
        asynq.RedisClientOpt{Addr: "localhost:6379"},
        asynq.Config{
            Concurrency: 10,  // 10 concurrent workers
            Queues: map[string]int{
                "critical": 6,  // priority queue weights
                "emails":   3,
                "default":  1,
            },
            // Retry delay: exponential backoff
            // Retry 1: 10s, Retry 2: 20s, Retry 3: 40s,...
        },
    )

    // ━━━ Route tasks đến handlers ━━━
    mux := asynq.NewServeMux()
    mux.HandleFunc(tasks.TypeEmailWelcome, tasks.HandleEmailWelcome)
    // Thêm handlers cho task types khác...

    // ━━━ Start server (blocking) ━━━
    if err := srv.Run(mux); err != nil {
        log.Fatal(err)
    }
}
```

**Kết quả đạt được**:
- Complete flow: define task → enqueue (client) → process (worker).
- Tasks persist trong Redis — server restart → tasks vẫn có.
- Retry automatic: error → retry (max 3 lần, exponential backoff).

**Lưu ý**:
- **Handler phải IDEMPOTENT** — retry gọi lại handler → không nên tạo duplicate.
- **Separate binaries**: client (API server) ≠ worker (background server).
- Queue priorities: `"critical": 6` → 6 lần ưu tiên hơn `"default": 1`.
- `ProcessIn(1*time.Hour)` cho delayed tasks (scheduled emails, reminders).

---

### Example 2: Scheduled Tasks (Cron)

**Mục tiêu**: Tạo recurring tasks chạy theo schedule (cron) — daily reports, cleanup jobs.

```go
package main

import (
    "log"

    "github.com/hibiken/asynq"
)

func main() {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Scheduler: cron-based recurring tasks
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    scheduler := asynq.NewScheduler(
        asynq.RedisClientOpt{Addr: "localhost:6379"},
        nil, // default config
    )

    // Daily report — 8:00 AM mỗi ngày
    task1 := asynq.NewTask("report:daily", nil)
    _, err := scheduler.Register("0 8 * * *", task1,
        asynq.Queue("critical"),
    )
    if err != nil {
        log.Fatal(err)
    }

    // Cleanup — mỗi giờ
    task2 := asynq.NewTask("cleanup:expired", nil)
    scheduler.Register("@every 1h", task2)

    // Weekly digest — Chủ nhật 9 PM
    task3 := asynq.NewTask("email:weekly_digest", nil)
    scheduler.Register("0 21 * * 0", task3,
        asynq.Queue("emails"),
    )

    // ━━━ Start scheduler (blocking) ━━━
    if err := scheduler.Run(); err != nil {
        log.Fatal(err)
    }
}
```

**Kết quả đạt được**:
- Cron-based scheduling: daily, hourly, weekly tasks.
- Tasks enqueue vào Redis → workers xử lý.

**Lưu ý**:
- Scheduler **nên chạy 1 instance** — chạy N instances = N duplicate tasks.
- Cron syntax: `minute hour day month weekday` hoặc `@every 1h`.
- Scheduler chỉ enqueue — xử lý vẫn do Worker server.

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Handler không idempotent** | Duplicate processing khi retry | Check before create |
| 2 | **Payload quá lớn** | Redis memory issue | Lưu data ở DB, queue reference ID |
| 3 | **Redis SPOF** | Downtime = lost tasks | Redis Sentinel/Cluster |
| 4 | **Multiple schedulers** | Duplicate cron tasks | Run 1 scheduler instance |
| 5 | **No monitoring** | Tasks fail silently | Deploy Asynqmon dashboard |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Asynq GitHub | https://github.com/hibiken/asynq |
| Asynq Wiki | https://github.com/hibiken/asynq/wiki |
| Asynqmon (Web UI) | https://github.com/hibiken/asynqmon |
| Asynq GoDoc | https://pkg.go.dev/github.com/hibiken/asynq |
