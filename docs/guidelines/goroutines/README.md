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

### Libraries (Chi tiết thư viện)

| # | Library | Mô tả ngắn | Detail |
|---|---------|-------------|--------|
| 10 | **Semaphore** | Weighted semaphore — giới hạn concurrent access | [→ 10-semaphore.md](./10-semaphore.md) |
| 11 | **Singleflight** | Deduplicate concurrent calls, cache stampede prevention | [→ 11-singleflight.md](./11-singleflight.md) |
| 12 | **Ants** | High-performance goroutine pool — auto-scale, pre-allocate | [→ 12-ants.md](./12-ants.md) |
| 13 | **Conc** | Structured concurrency — type-safe, panic-safe, iter.Map | [→ 13-conc.md](./13-conc.md) |
| 14 | **Workerpool** | Bounded worker pool — simplest API | [→ 14-workerpool.md](./14-workerpool.md) |
| 15 | **Asynq** | Distributed task queue (Redis-backed), cron scheduling | [→ 15-asynq.md](./15-asynq.md) |

---

## 📦 Thư viện phổ biến hỗ trợ Concurrency

### Standard Library

| Package | Mô tả | Import |
|---------|-------|--------|
| **sync** | Mutex, RWMutex, WaitGroup, Once, Map, Pool | `sync` |
| **sync/atomic** | Atomic operations (lock-free) | `sync/atomic` |
| **context** | Cancellation, timeout, request-scoped values | `context` |

### Golang.org/x (Official Extended)

| Package | Mô tả | Install |
|---------|-------|---------|
| **errgroup** | Goroutine group + error propagation + SetLimit | `go get golang.org/x/sync/errgroup` |
| **semaphore** | Weighted semaphore — giới hạn concurrent access | `go get golang.org/x/sync/semaphore` |
| **singleflight** | Deduplicate concurrent calls (cache stampede) | `go get golang.org/x/sync/singleflight` |

### Third-party Libraries

| Library | Mô tả | Stars | Install |
|---------|-------|-------|---------|
| **[Tunny](https://github.com/Jeffail/tunny)** | Worker pool — fixed size, blocking Process, timeout | ~4k | `go get github.com/Jeffail/tunny` |
| **[Ants](https://github.com/panjf2000/ants)** | High-performance goroutine pool — auto-scale, pre-allocate | ~12k | `go get github.com/panjf2000/ants/v2` |
| **[Conc](https://github.com/sourcegraph/conc)** | Structured concurrency — type-safe, panic-safe pool | ~8k | `go get github.com/sourcegraph/conc` |
| **[Go-workerpool](https://github.com/gammazero/workerpool)** | Bounded worker pool — submit tasks, wait all | ~1k | `go get github.com/gammazero/workerpool` |
| **[Machinery](https://github.com/RichardKnop/machinery)** | Distributed task queue (Redis/AMQP backend) | ~7k | `go get github.com/RichardKnop/machinery/v2` |
| **[Asynq](https://github.com/hibiken/asynq)** | Simple distributed task queue (Redis) | ~9k | `go get github.com/hibiken/asynq` |

### So sánh Worker Pool Libraries

| | Tunny | Ants | Conc | errgroup.SetLimit |
|--|-------|------|------|-------------------|
| **Pool size** | Fixed | Dynamic (auto-scale) | Fixed | Fixed |
| **Goroutine reuse** | ✅ | ✅ | ❌ | ❌ |
| **Blocking submit** | ✅ Process() | ✅ Submit() | ✅ Go() | ✅ Go() |
| **Return result** | ✅ | ❌ | ✅ (generic) | ❌ |
| **Timeout** | ✅ ProcessTimed | ❌ | ❌ | ❌ (dùng ctx) |
| **Context** | ✅ ProcessCtx | ❌ | ✅ | ✅ |
| **Panic recovery** | ❌ | ✅ | ✅ | ❌ |
| **Dependency** | External | External | External | stdlib (x/) |

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
                                                                      │
                                                                      ▼
                          ⑩ Semaphore ──▶ ⑪ Singleflight ──▶ ⑫ Ants ──▶ ⑬ Conc
                                                                              │
                                                                              ▼
                                                            ⑭ Workerpool ──▶ ⑮ Asynq
```
