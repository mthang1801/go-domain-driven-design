# Query Builder Platform - AI Agent Rules

## 📋 Overview

These rules guide AI agents when working on the **Query Builder Platform** - a Go-based Business Intelligence tool similar to Metabase/Superset.

---

## 🎯 Core Principles

### 1. Always Read Skills First

Before writing ANY code or making architectural decisions:

```
IF task involves:
  - HTTP handlers          → Read go-backend-development skill
  - Multi-DB queries       → Read query-builder-platform skill
  - Domain models          → Read ddd-go-patterns skill
  - Goroutines/channels    → Read go-concurrency-patterns skill
  - Testing                → Read go-testing-strategies skill
```

**Why?** Skills contain battle-tested patterns from production systems. Reading them first saves time and prevents common mistakes.

---

## 🏗️ Architecture Decision Rules

### Rule 1: Layer Separation (Strict)

```
✅ ALLOWED:
domain/          → No dependencies (only stdlib)
application/     → Can import domain/
infrastructure/  → Can import domain/ + application/
interfaces/      → Can import application/

❌ FORBIDDEN:
domain/          → NEVER import infrastructure/ or interfaces/
application/     → NEVER import infrastructure/ or interfaces/
```

**Rationale:** Dependency Inversion Principle. Domain is the core, infrastructure is replaceable.

**Example Violation:**
```go
// ❌ BAD: Domain importing infrastructure
package aggregate

import "project/infrastructure/persistence" // FORBIDDEN!

type Order struct {
    repo *persistence.OrderRepository // WRONG!
}
```

**Correct:**
```go
// ✅ GOOD: Domain defines interface
package repository

type OrderRepository interface {
    Save(ctx context.Context, order *Order) error
}

// Infrastructure implements it
package persistence

type OrderRepositoryImpl struct {}
func (r *OrderRepositoryImpl) Save(...) error { ... }
```

---

### Rule 2: No Business Logic Outside Domain

```
✅ Business logic goes in:
- Aggregate methods (Order.Confirm(), User.Activate())
- Domain services (PricingService, ValidationService)
- Specifications (OrderIsShippable, UserIsActive)

❌ Business logic NEVER in:
- HTTP handlers (only HTTP concerns)
- Repositories (only persistence)
- Use cases (only orchestration)
```

**Example Violation:**
```go
// ❌ BAD: Business logic in handler
func (h *OrderHandler) ConfirmOrder(c *gin.Context) {
    var req ConfirmOrderRequest
    c.ShouldBindJSON(&req)
    
    // ❌ WRONG: Status check in handler
    if order.Status != "PENDING" {
        c.JSON(400, gin.H{"error": "Can only confirm pending order"})
        return
    }
    
    // ❌ WRONG: Direct database update
    db.Exec("UPDATE orders SET status = 'CONFIRMED' WHERE id = ?", order.ID)
}
```

**Correct:**
```go
// ✅ GOOD: Business logic in aggregate
type Order struct {
    status OrderStatus
}

func (o *Order) Confirm() error {
    if o.status != StatusPending {
        return ErrCanOnlyConfirmPendingOrder
    }
    o.status = StatusConfirmed
    o.AddDomainEvent(OrderConfirmed{...})
    return nil
}

// Handler just delegates
func (h *OrderHandler) ConfirmOrder(c *gin.Context) {
    order, _ := h.repo.FindByID(...)
    if err := order.Confirm(); err != nil {
        h.handleError(c, err)
        return
    }
    h.repo.Save(ctx, order)
}
```

---

### Rule 3: Query Engine Pattern (Strategy)

For multi-database support, ALWAYS use Strategy pattern:

```go
// ✅ Interface
type QueryEngine interface {
    Execute(ctx context.Context, query SqlQuery) (*QueryResult, error)
}

// ✅ Concrete implementations
type PostgresEngine struct { ... }
type MySQLEngine struct { ... }
type MongoDBEngine struct { ... }

// ✅ Factory
func NewQueryEngine(dbType string) QueryEngine { ... }
```

**Never:**
```go
// ❌ BAD: If-else hell
func ExecuteQuery(query string, dbType string) {
    if dbType == "postgres" {
        // postgres code
    } else if dbType == "mysql" {
        // mysql code
    } else if dbType == "mongodb" {
        // mongodb code
    }
}
```

---

## 🚀 Performance Rules

### Rule 4: Parallel Execution for Multiple Queries

When executing multiple queries (e.g., dashboard):

```go
✅ ALWAYS use errgroup for parallel execution:

g, ctx := errgroup.WithContext(ctx)
g.SetLimit(10) // Limit concurrency

for _, card := range cards {
    card := card
    g.Go(func() error {
        return executeCard(ctx, card)
    })
}

g.Wait()
```

**Metrics:**
- Serial: 880ms (5 queries × ~175ms)
- Parallel: 250ms (max of 5 queries)
- **3.5x faster**

---

### Rule 5: Connection Pooling (Always)

```
✅ DO: One connection pool per database
❌ DON'T: Create new connection for each query
```

**Implementation:**
```go
// ✅ GOOD: Global pool manager
type PoolManager struct {
    pools map[string]*pgxpool.Pool
}

func (m *PoolManager) GetOrCreate(dbID string) (*pgxpool.Pool, error) {
    if pool, exists := m.pools[dbID]; exists {
        return pool, nil
    }
    
    pool := createPool(config)
    m.pools[dbID] = pool
    return pool, nil
}
```

**Pool Configuration:**
```go
poolConfig.MaxConns = 20
poolConfig.MinConns = 2
poolConfig.MaxConnLifetime = 1 * time.Hour
poolConfig.MaxConnIdleTime = 30 * time.Minute
```

---

### Rule 6: Query Result Caching

```
Cache Strategy:
1. Check Redis cache first
2. If miss → Execute query → Cache result
3. TTL based on query type:
   - Aggregation queries: 5 minutes
   - Analytical queries: 15 minutes
   - Real-time queries: No cache
```

**Cache Key:**
```go
func GetCacheKey(query SqlQuery, dbID string) string {
    h := sha256.New()
    h.Write([]byte(query.Raw))
    h.Write([]byte(fmt.Sprintf("%v", query.Params)))
    h.Write([]byte(dbID))
    return hex.EncodeToString(h.Sum(nil))
}
```

---

### Rule 7: Streaming for Large Files

```
✅ CSV Import: Use streaming (encoding/csv)
✅ Excel Export: Use streaming (excelize)
❌ NEVER: Load entire file into memory
```

**Pattern:**
```go
reader := csv.NewReader(file)
reader.ReuseRecord = true // Reuse buffer

batch := make([][]interface{}, 0, 1000)

for {
    record, err := reader.Read()
    if err == io.EOF {
        break
    }
    
    batch = append(batch, record)
    
    if len(batch) >= 1000 {
        db.CopyFrom(...) // Batch insert
        batch = batch[:0]
    }
}
```

**Performance:**
- Memory: <50MB for 10GB file
- Speed: 50,000 rows/sec (PostgreSQL COPY)

---

## 🔐 Security Rules

### Rule 8: SQL Injection Prevention

```
✅ ALWAYS: Validate SQL before execution
✅ ALWAYS: Use parameterized queries
✅ ALWAYS: Block DDL statements
```

**Implementation:**
```go
// Parse and validate
stmt, err := sqlparser.Parse(query.Raw)

// Block DDL
if _, ok := stmt.(*sqlparser.DDL); ok {
    return ErrDDLNotAllowed
}

// Block dangerous functions
if containsDangerousFunc(stmt) {
    return ErrDangerousFunctionDetected
}
```

---

### Rule 9: Row-Level Security (RLS)

```
IF database.RLSEnabled == true:
    Auto-inject WHERE clause based on user context
```

**Example:**
```go
// Original: SELECT * FROM orders
// With RLS: SELECT * FROM orders WHERE tenant_id = 'user-tenant-id'

func ApplyRLS(query SqlQuery, user User) SqlQuery {
    whereClause := fmt.Sprintf("tenant_id = '%s'", user.TenantID)
    modifiedSQL := sqlparser.InjectWhere(query.Raw, whereClause)
    return SqlQuery{Raw: modifiedSQL, Params: query.Params}
}
```

---

## 🧪 Testing Rules

### Rule 10: Test Pyramid

```
Unit Tests (70%):
- Domain logic (aggregates, value objects, specifications)
- Use cases (command/query handlers)
- Domain services

Integration Tests (20%):
- Repository implementations (use testcontainers)
- Query engine implementations
- API endpoints

E2E Tests (10%):
- Critical user flows
- Dashboard execution
- Import/export jobs
```

---

### Rule 11: Use Testcontainers for Integration Tests

```go
✅ ALWAYS use real databases for integration tests
❌ NEVER use mocks for repository tests
```

**Example:**
```go
func TestUserRepository_Save(t *testing.T) {
    // Start real PostgreSQL container
    pgContainer, _ := postgres.RunContainer(ctx, ...)
    defer pgContainer.Terminate(ctx)
    
    db, _ := sql.Open("postgres", connString)
    repo := NewUserRepositoryImpl(db)
    
    // Test with real database
    user := aggregate.NewUser(...)
    err := repo.Save(ctx, user)
    
    assert.NoError(t, err)
}
```

---

## 📝 Code Quality Rules

### Rule 12: Error Handling

```
✅ ALWAYS: Wrap errors with context
✅ ALWAYS: Use domain errors
✅ ALWAYS: Map errors in handlers
❌ NEVER: Ignore errors
❌ NEVER: Return generic errors
```

**Pattern:**
```go
// Domain error
var ErrOrderNotFound = errors.New("order not found")

// Wrap with context
if order == nil {
    return fmt.Errorf("failed to load order %s: %w", orderID, ErrOrderNotFound)
}

// Map in handler
func (h *Handler) handleError(c *gin.Context, err error) {
    if errors.Is(err, ErrOrderNotFound) {
        c.JSON(404, gin.H{"error": "Order not found"})
        return
    }
    // ... other mappings
}
```

---

### Rule 13: Context Propagation

```
✅ ALWAYS: Pass context.Context as first parameter
✅ ALWAYS: Propagate cancellation
✅ ALWAYS: Set timeouts for external calls
```

**Pattern:**
```go
// Query with timeout
ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
defer cancel()

rows, err := pool.Query(ctx, sql, params...)

// Goroutine with context
go func() {
    select {
    case <-ctx.Done():
        return // Cancelled
    case <-time.After(delay):
        process()
    }
}()
```

---

### Rule 14: Logging & Tracing

```
✅ ALWAYS: Use structured logging (zap/zerolog)
✅ ALWAYS: Add OpenTelemetry spans
✅ ALWAYS: Log errors with context
```

**Pattern:**
```go
// Structured logging
logger.Info("Query executed",
    zap.String("query_id", queryID),
    zap.Duration("duration", elapsed),
    zap.Int("rows", rowCount),
)

// OpenTelemetry span
ctx, span := tracer.Start(ctx, "ExecuteQuery")
defer span.End()

span.SetAttributes(
    attribute.String("db_type", "postgres"),
    attribute.String("query", query.Raw),
)
```

---

## 🔄 Workflow Rules

### Rule 15: Development Workflow

```
1. Read relevant skills FIRST
2. Design domain model (aggregates, VOs, events)
3. Write failing tests
4. Implement domain logic
5. Implement infrastructure adapters
6. Wire dependencies with Google Wire
7. Add observability (logs, traces, metrics)
8. Document API (Swagger comments)
9. Integration test
10. Code review checklist
```

---

### Rule 16: Pull Request Checklist

Before submitting PR, verify:

```
Domain Layer:
- [ ] No infrastructure dependencies
- [ ] Business rules in aggregates/domain services
- [ ] Value objects are immutable
- [ ] Domain events raised on state changes

Application Layer:
- [ ] Use cases are thin (orchestration only)
- [ ] Commands return aggregate IDs
- [ ] Queries return DTOs
- [ ] No business logic

Infrastructure Layer:
- [ ] Repository per aggregate root only
- [ ] Events published after transaction commit
- [ ] Connection pooling configured
- [ ] Migrations added

Interface Layer:
- [ ] Handlers are thin
- [ ] Error mapping correct
- [ ] Swagger comments added
- [ ] Validation via struct tags

Testing:
- [ ] Unit tests for domain logic
- [ ] Integration tests for repositories
- [ ] E2E tests for critical flows

Performance:
- [ ] Parallel execution where applicable
- [ ] Query caching implemented
- [ ] Timeouts set
- [ ] No N+1 queries

Security:
- [ ] SQL injection prevention
- [ ] RLS applied if needed
- [ ] Permissions checked
- [ ] Sensitive data encrypted

Observability:
- [ ] Logs with context
- [ ] OpenTelemetry spans
- [ ] Metrics recorded
```

---

## 🚨 Common Mistakes to Avoid

### Mistake 1: Goroutine Leaks
```go
// ❌ BAD
go func() {
    time.Sleep(10 * time.Minute)
    process()
}()

// ✅ GOOD
go func() {
    select {
    case <-ctx.Done():
        return
    case <-time.After(10 * time.Minute):
        process()
    }
}()
```

### Mistake 2: Missing Error Checks
```go
// ❌ BAD
user, _ := repo.FindByID(id)
return user

// ✅ GOOD
user, err := repo.FindByID(id)
if err != nil {
    return nil, fmt.Errorf("failed to get user: %w", err)
}
return user, nil
```

### Mistake 3: Anemic Domain Model
```go
// ❌ BAD
type Order struct {
    Status string
}
func (o *Order) SetStatus(s string) { o.Status = s }

// ✅ GOOD
type Order struct {
    status OrderStatus
}
func (o *Order) Confirm() error {
    if o.status != StatusPending {
        return ErrCannotConfirm
    }
    o.status = StatusConfirmed
    o.AddDomainEvent(...)
    return nil
}
```

### Mistake 4: Database Connection per Query
```go
// ❌ BAD
func ExecuteQuery(sql string) {
    db, _ := sql.Open("postgres", dsn)
    defer db.Close()
    db.Query(sql)
}

// ✅ GOOD
var globalPool *pgxpool.Pool // Injected

func ExecuteQuery(ctx context.Context, sql string) {
    globalPool.Query(ctx, sql)
}
```

### Mistake 5: Loading Large Files to Memory
```go
// ❌ BAD
func ImportCSV(file []byte) {
    rows := csv.ReadAll(file) // OOM!
    for _, row := range rows {
        db.Insert(row)
    }
}

// ✅ GOOD
func ImportCSV(file io.Reader) {
    reader := csv.NewReader(file)
    for {
        record, _ := reader.Read()
        if err == io.EOF {
            break
        }
        batch = append(batch, record)
        if len(batch) >= 1000 {
            db.CopyFrom(...)
        }
    }
}
```

---

## 📚 Decision Matrix

### When to Use What?

| Scenario | Pattern | Rationale |
|----------|---------|-----------|
| Multiple DB types | Strategy Pattern | Polymorphism |
| Multiple queries | errgroup | Parallel execution |
| Large file import | Streaming | Memory efficiency |
| User permission check | Specification | Complex rules |
| Multi-step transaction | Saga | Distributed consistency |
| Real-time updates | WebSocket | Low latency |
| Background jobs | Asynq | Retry + scheduling |
| Query caching | Redis | Performance |

---

## 🎓 Learning Path for New Agents

```
Day 1-2: Read all skills
Day 3-4: Implement Connection Context (DB connections)
Day 5-6: Implement Card Context (query execution)
Day 7-8: Implement Dashboard Context (parallel queries)
Day 9-10: Add WebSocket + Caching
Day 11-12: Import/Export with streaming
Day 13-14: Testing + Observability
Day 15: Code review + optimization
```

---

## 🔗 Quick Links

- **Skills**: See `/skills` directory for detailed patterns
- **ERD**: See `database-erd.md` for schema
- **API**: See `query-builder-go-architecture.md` for endpoints
- **Diagrams**: See `query-builder-sequence-diagrams.md` for flows

---

## ⚡ TL;DR (Quick Reference)

```
✅ DO:
- Read skills before coding
- Business logic in domain layer
- Use errgroup for parallel queries
- Connection pooling (one per DB)
- Stream large files
- Validate SQL (prevent injection)
- Test with testcontainers
- Propagate context
- Structured logging + tracing

❌ DON'T:
- Business logic in handlers/repos
- Serial query execution
- New connection per query
- Load files to memory
- Ignore errors
- Skip tests
- Leak goroutines
- Anemic domain models
```

---

**Last Updated**: 2026-02-10  
**Version**: 1.0.0  
**Maintained By**: MVT (Backend Developer & DevOps Engineer)
