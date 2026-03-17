# 🔄 Go Concurrency — Tổng quan & Hướng dẫn

> **Mục đích**: Tổng hợp tất cả concurrency patterns trong Go, từ cơ bản đến nâng cao.  
> **Cấu trúc**: Mỗi concept có file detail riêng theo format ① DEFINE → ② GRAPH → ③ CODE → ④ PITFALLS → ⑤ REF.

---

## 📑 Mục lục

### Nền tảng (Fundamentals)

| # | Concept | Mô tả ngắn | Detail |
|---|---------|-------------|--------|
| 1 | **Goroutines & Channels** | Goroutine, buffered/unbuffered channels, select, directional channels | [→ 01-goroutines-and-channels.md](./01-goroutines-and-channels.md) |
| 2 | **Mutex & Race Condition** | sync.Mutex, sync.RWMutex, race detector, atomic operations | [→ 02-mutex-and-race-condition.md](./02-mutex-and-race-condition.md) |
| 3 | **Context** | context.Context, WithCancel, WithTimeout, WithDeadline, WithValue | [→ 03-context.md](./03-context.md) |
| 4 | **sync.Pool & Buffer Pool** | Object reuse, buffer pool, giảm GC pressure | [→ 04-sync-pool.md](./04-sync-pool.md) |
| 5 | **Errgroup** | Error handling cho nhóm goroutines, context propagation | [→ 05-errgroup.md](./05-errgroup.md) |

### Patterns (Concurrency Patterns)

| # | Concept | Mô tả ngắn | Detail |
|---|---------|-------------|--------|
| 6 | **Fan-out / Fan-in** | 1→N workers (fan-out) / N sources→1 output (fan-in) | [→ 06-fan-out-fan-in.md](./06-fan-out-fan-in.md) |
| 7 | **Pipeline** | Chain of stages kết nối bằng channels | [→ 07-pipeline.md](./07-pipeline.md) |
| 8 | **Worker Pool & Tunny** | Worker pool pattern, Tunny library, pool manager | [→ 08-worker-pool-tunny.md](./08-worker-pool-tunny.md) |
| 9 | **Or-done & Tee Channels** | Or-done pattern, tee channel, channel multiplexing nâng cao | [→ 09-or-done-tee-channels.md](./09-or-done-tee-channels.md) |

---

## 🗺️ Thứ tự học khuyến nghị

```
① Goroutines & Channels ──▶ ② Mutex & Race Condition ──▶ ③ Context
         │
         ▼
④ sync.Pool ──▶ ⑤ Errgroup ──▶ ⑥ Fan-out/Fan-in ──▶ ⑦ Pipeline
                                                          │
                                                          ▼
                                    ⑧ Worker Pool (Tunny) ──▶ ⑨ Or-done & Tee
```
