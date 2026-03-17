# 11 — Singleflight

> **Package**: `golang.org/x/sync/singleflight` — Loại bỏ duplicate concurrent calls.

---

## ① DEFINE

### Định nghĩa

**Singleflight** đảm bảo rằng cho 1 key, chỉ có **1 function execution** diễn ra tại 1 thời điểm. Nếu N goroutines cùng gọi với cùng key → chỉ 1 goroutine thực thi, N-1 goroutines còn lại **đợi và nhận cùng kết quả**.

### Use cases

| Use case | Vấn đề | Giải pháp |
|----------|--------|-----------|
| **Cache stampede** | Cache expire → 1000 requests cùng query DB | Singleflight: chỉ 1 query, 999 đợi |
| **API deduplication** | Client spam same API endpoint | 1 execution, rest share result |
| **Config reload** | Multiple goroutines trigger reload | 1 reload, rest wait |

### Phân biệt Singleflight vs Cache vs Mutex

| Cơ chế | Mục đích | Scope |
|--------|---------|-------|
| **Cache** | Lưu kết quả để tái sử dụng | Across requests (time-based) |
| **Singleflight** | Deduplicate concurrent calls | Only concurrent (in-flight) |
| **Mutex** | Exclusive access to resource | Block all except 1 |

### API

| Method | Mô tả |
|--------|-------|
| `Do(key, fn)` | Execute fn, deduplicate by key. Return `(val, err, shared)` |
| `DoChan(key, fn)` | Same as Do nhưng return channel (non-blocking caller) |
| `Forget(key)` | Xóa key khỏi in-flight → call tiếp theo sẽ execute mới |

### Failure Modes

| Failure | Nguyên nhân | Cách tránh |
|---------|-------------|------------|
| **Error propagation** | 1 goroutine error → TẤT CẢ nhận error | Retry logic ở caller |
| **Slow function** | Function chậm → TẤT CẢ đợi | Combine với timeout/context |
| **Stale result** | Kết quả cũ shared cho requests mới | `Forget(key)` hoặc short TTL |

---

## ② GRAPH

### Singleflight — Cache Stampede Prevention

```
  Trước (không có singleflight):

  Cache MISS!
  Request 1 ──▶ Query DB ──────────▶ Result
  Request 2 ──▶ Query DB ──────────▶ Result   ← 1000 queries!
  Request 3 ──▶ Query DB ──────────▶ Result
  ...
  Request 1000 ──▶ Query DB ───────▶ Result

  Sau (có singleflight):

  Cache MISS!
  Request 1 ──▶ Query DB ──────────▶ Result ──▶ Share
  Request 2 ──▶ WAIT ─────────────────────────▶ Same Result ← shared!
  Request 3 ──▶ WAIT ─────────────────────────▶ Same Result
  ...
  Request 1000 ──▶ WAIT ──────────────────────▶ Same Result

  1 DB query thay vì 1000!
```

---

## ③ CODE

---

### Example 1: Cơ bản — Cache Stampede Prevention

**Mục tiêu**: 100 concurrent requests cho cùng user data. Không có singleflight → 100 DB queries. Có singleflight → 1 DB query, 99 đợi và nhận cùng kết quả.

**Cần gì**: `golang.org/x/sync/singleflight`.

```go
package main

import (
    "fmt"
    "sync"
    "sync/atomic"
    "time"

    "golang.org/x/sync/singleflight"
)

var (
    dbQueryCount atomic.Int64 // đếm số lần query DB thật sự
    group        singleflight.Group
)

// getUserFromDB: simulate DB query (expensive)
func getUserFromDB(userID string) (string, error) {
    dbQueryCount.Add(1)
    fmt.Printf("  📊 [DB] Querying user %s (query #%d)\n", userID, dbQueryCount.Load())
    time.Sleep(200 * time.Millisecond) // simulate DB latency
    return fmt.Sprintf("User{id: %s, name: 'Alice'}", userID), nil
}

// getUser: wrapper với singleflight
func getUser(userID string) (string, error) {
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Do(key, fn):
    // - Key: "user:123" — deduplicate theo key này
    // - Nếu đã có goroutine đang chạy fn cho key này → đợi + share result
    // - Nếu chưa → chạy fn, result shared cho tất cả waiters
    //
    // Return:
    // - val: kết quả từ fn
    // - err: error từ fn
    // - shared: true nếu kết quả được share (không phải executor)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    val, err, shared := group.Do("user:"+userID, func() (interface{}, error) {
        return getUserFromDB(userID)
    })
    if err != nil {
        return "", err
    }

    if shared {
        fmt.Printf("  ♻️  [Cache] Result shared (not from DB)\n")
    }

    return val.(string), nil
}

func main() {
    fmt.Println("=== 100 concurrent requests for same user ===\n")

    var wg sync.WaitGroup
    for i := 0; i < 100; i++ {
        wg.Add(1)
        go func(requestID int) {
            defer wg.Done()
            user, err := getUser("123")
            if err != nil {
                fmt.Printf("Request %d: ❌ %v\n", requestID, err)
                return
            }
            _ = user // use result
        }(i)
    }

    wg.Wait()
    fmt.Printf("\n📊 Total DB queries: %d (saved %d queries!)\n",
        dbQueryCount.Load(), 100-dbQueryCount.Load())
}
```

**Kết quả đạt được**:
- 100 concurrent requests → chỉ 1-2 DB queries (thay vì 100).
- 98-99 requests nhận **shared result** — zero DB load.
- `shared=true` cho biết result là shared từ goroutine khác.

**Lưu ý**:
- Singleflight **chỉ deduplicate concurrent calls** — KHÔNG cache kết quả.
- Sau khi goroutine đầu tiên xong → key được xóa → request tiếp theo sẽ execute mới.
- Combine với cache: `check cache → miss → singleflight → set cache → return`.

---

### Example 2: Singleflight + Cache — Production Pattern

**Mục tiêu**: Pattern phổ biến nhất: L1 cache → singleflight → DB. Tránh cả cache stampede và duplicate queries.

**Cần gì**: `singleflight` + simple in-memory cache.

```go
package main

import (
    "fmt"
    "sync"
    "sync/atomic"
    "time"

    "golang.org/x/sync/singleflight"
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SimpleCache: in-memory cache với TTL
// Production: dùng Redis, Memcached, hoặc go-cache
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type CacheEntry struct {
    Value     string
    ExpiresAt time.Time
}

type Cache struct {
    mu      sync.RWMutex
    entries map[string]CacheEntry
}

func NewCache() *Cache {
    return &Cache{entries: make(map[string]CacheEntry)}
}

func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    entry, ok := c.entries[key]
    if !ok || time.Now().After(entry.ExpiresAt) {
        return "", false // miss hoặc expired
    }
    return entry.Value, true
}

func (c *Cache) Set(key, value string, ttl time.Duration) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.entries[key] = CacheEntry{Value: value, ExpiresAt: time.Now().Add(ttl)}
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UserService: cache → singleflight → DB
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
type UserService struct {
    cache *Cache
    group singleflight.Group
    dbHit atomic.Int64
}

func NewUserService() *UserService {
    return &UserService{cache: NewCache()}
}

func (s *UserService) GetUser(userID string) (string, error) {
    cacheKey := "user:" + userID

    // ━━━ Layer 1: Check cache ━━━
    if val, ok := s.cache.Get(cacheKey); ok {
        return val, nil // cache HIT — nhanh nhất
    }

    // ━━━ Layer 2: Singleflight — deduplicate DB queries ━━━
    val, err, _ := s.group.Do(cacheKey, func() (interface{}, error) {
        // Double-check cache (another goroutine có thể đã set)
        if val, ok := s.cache.Get(cacheKey); ok {
            return val, nil
        }

        // ━━━ Layer 3: Query DB ━━━
        s.dbHit.Add(1)
        time.Sleep(100 * time.Millisecond) // simulate DB
        result := fmt.Sprintf("User{id:%s, name:'Alice'}", userID)

        // Set cache cho requests sau
        s.cache.Set(cacheKey, result, 5*time.Second)

        return result, nil
    })
    if err != nil {
        return "", err
    }

    return val.(string), nil
}

func main() {
    svc := NewUserService()

    fmt.Println("=== Wave 1: 50 concurrent requests (cold cache) ===")
    var wg sync.WaitGroup
    for i := 0; i < 50; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            svc.GetUser("123")
        }()
    }
    wg.Wait()
    fmt.Printf("DB hits: %d (singleflight saved %d queries)\n\n", svc.dbHit.Load(), 50-svc.dbHit.Load())

    fmt.Println("=== Wave 2: 50 more requests (warm cache) ===")
    for i := 0; i < 50; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            svc.GetUser("123")
        }()
    }
    wg.Wait()
    fmt.Printf("DB hits: %d (cache hit for wave 2)\n", svc.dbHit.Load())
}
```

**Kết quả đạt được**:
- Wave 1 (cold cache): 50 requests → 1 DB query → set cache.
- Wave 2 (warm cache): 50 requests → 0 DB queries (cache hit).
- 100 requests tổng cộng → chỉ 1 DB query.

**Lưu ý**:
- **Double-check cache** bên trong singleflight fn — tránh query DB nếu goroutine khác đã set cache.
- Pattern: `cache.Get → singleflight.Do → cache.Get (double-check) → DB → cache.Set`.
- TTL nên **ngắn** (5-30s) cho data hay thay đổi.

---

### Example 3: DoChan — Non-blocking với timeout

**Mục tiêu**: `DoChan` trả channel thay vì block — combine với `select` cho timeout control.

```go
package main

import (
    "fmt"
    "time"

    "golang.org/x/sync/singleflight"
)

func main() {
    var group singleflight.Group

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // DoChan: trả <-chan Result thay vì block
    // Combine với select cho timeout
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ch := group.DoChan("slow-query", func() (interface{}, error) {
        time.Sleep(2 * time.Second) // simulate slow query
        return "result from DB", nil
    })

    // ━━━ Select: result vs timeout ━━━
    select {
    case result := <-ch:
        if result.Err != nil {
            fmt.Println("❌ Error:", result.Err)
        } else {
            fmt.Printf("✅ Got: %v (shared: %v)\n", result.Val, result.Shared)
        }
    case <-time.After(1 * time.Second):
        fmt.Println("⏱️ Timeout! Falling back to default value")
        // Forget key để request tiếp theo có thể execute mới
        group.Forget("slow-query")
    }
}
```

**Kết quả đạt được**:
- Query chậm (2s) nhưng timeout 1s → fallback.
- `Forget("slow-query")` xóa key → request tiếp có thể thử lại.

**Lưu ý**:
- `DoChan` + `select` = timeout control cho singleflight.
- `Forget(key)` quan trọng: nếu không forget, requests tiếp vẫn đợi goroutine cũ.
- Goroutine cũ **vẫn chạy** sau timeout — chỉ result bị bỏ qua (giống context cancel).

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | **Error shared** | 1 goroutine error → all get error | Retry ở caller |
| 2 | **Không cache result** | Singleflight chỉ deduplicate, KHÔNG cache | Combine với cache |
| 3 | **Slow fn blocks all** | Function chậm → N goroutines đợi | DoChan + timeout |
| 4 | **Stale after Forget** | Forget rồi vẫn có goroutine chờ | Dùng DoChan + select |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| singleflight package | https://pkg.go.dev/golang.org/x/sync/singleflight |
| Blog — Preventing thundering herds | https://www.calhoun.io/using-singleflight-to-deduplicate-requests/ |
