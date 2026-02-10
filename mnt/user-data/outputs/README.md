# Query Builder Platform - AI Agent Skills & Rules

> Complete skill set for AI agents developing the Query Builder Platform in Go

---

## 📚 Overview

This package contains **rules** and **skills** to guide AI agents when building the **Query Builder Platform** - a high-performance Business Intelligence tool (similar to Metabase/Superset) built with Go.

### What's Included

```
skills/
├── RULES.md                      # Core rules & principles (READ THIS FIRST!)
├── go-backend/                   # General Go backend development
│   └── SKILL.md
├── query-builder/                # Query Builder specific patterns
│   └── SKILL.md
├── ddd-go/                       # Domain-Driven Design in Go
│   └── SKILL.md
├── go-concurrency/               # Concurrency patterns
│   └── SKILL.md
├── go-testing/                   # Testing strategies
│   └── SKILL.md
└── README.md                     # This file
```

---

## 🎯 Quick Start

### For AI Agents

```
1. READ RULES.md first (mandatory)
2. Identify task domain:
   - HTTP API?          → go-backend skill
   - Multi-DB queries?  → query-builder skill
   - Domain models?     → ddd-go skill
   - Goroutines?        → go-concurrency skill
   - Testing?           → go-testing skill
3. Read relevant skill(s)
4. Write code following patterns
5. Self-check against rules
```

### Skill Selection Matrix

| Task | Primary Skill | Secondary Skills |
|------|--------------|------------------|
| Create REST endpoint | go-backend | ddd-go |
| Implement query engine | query-builder | go-concurrency |
| Build aggregate root | ddd-go | - |
| Add parallel execution | go-concurrency | query-builder |
| Write tests | go-testing | go-backend |
| Dashboard auto-refresh | go-concurrency | query-builder |
| CSV import/export | query-builder | go-concurrency |

---

## 📖 Skills Reference

### 1. RULES.md (Core Principles)

**Must read before ANY coding task**

Contains:
- Architecture decision rules
- Layer separation (strict)
- Performance rules
- Security rules
- Common mistakes
- Decision matrix

**Key Rules:**
```
✅ DO:
- Read skills first
- Business logic in domain
- Use errgroup for parallel queries
- Connection pooling
- Stream large files
- Validate SQL
- Test with testcontainers

❌ DON'T:
- Business logic in handlers
- Serial query execution
- New connection per query
- Load files to memory
- Ignore errors
- Skip tests
- Leak goroutines
```

---

### 2. go-backend (General Go Development)

**When to use:**
- Creating HTTP handlers
- Implementing middleware
- Setting up dependency injection
- Error handling
- Repository pattern

**Patterns covered:**
- Gin handler structure
- Middleware patterns
- Google Wire DI
- Domain errors
- Repository implementation
- Testing with mocks

**Example:**
```go
// ✅ GOOD: Thin handler
func (h *UserHandler) CreateUser(c *gin.Context) {
    var req CreateUserRequest
    c.ShouldBindJSON(&req)
    
    user, err := h.useCase.Execute(ctx, cmd)
    if err != nil {
        h.handleError(c, err)
        return
    }
    
    c.JSON(201, toResponse(user))
}
```

---

### 3. query-builder (Platform Specific)

**When to use:**
- Multi-database query engine
- Dashboard execution
- CSV/Excel import/export
- WebSocket real-time updates
- Query caching

**Patterns covered:**
- Strategy pattern (multi-DB)
- Parallel dashboard execution
- Streaming CSV import
- WebSocket hub
- Query result caching
- Row-Level Security (RLS)

**Example:**
```go
// ✅ Parallel dashboard execution
g, ctx := errgroup.WithContext(ctx)
g.SetLimit(10)

for _, card := range cards {
    card := card
    g.Go(func() error {
        return executeCard(ctx, card)
    })
}

g.Wait() // 3.5x faster than serial
```

---

### 4. ddd-go (Domain-Driven Design)

**When to use:**
- Creating aggregates
- Value objects
- Domain events
- Repository interfaces
- Domain services
- CQRS pattern

**Patterns covered:**
- BaseAggregate
- BaseEntity
- ValueObject
- DomainEvent
- Repository pattern
- Specification pattern

**Example:**
```go
// ✅ Rich domain model
type Order struct {
    *ddd.BaseAggregate
    status OrderStatus
}

func (o *Order) Confirm() error {
    if o.status != StatusPending {
        return ErrCannotConfirm
    }
    o.status = StatusConfirmed
    o.AddDomainEvent(OrderConfirmed{...})
    return nil
}
```

---

### 5. go-concurrency (Concurrency Patterns)

**When to use:**
- Parallel task execution
- Background workers
- Streaming pipelines
- Rate limiting
- Context cancellation

**Patterns covered:**
- Worker pool
- errgroup (fan-out/fan-in)
- Pipeline
- Semaphore rate limiting
- Timeout & cancellation
- Select multiplexing

**Example:**
```go
// ✅ Worker pool
pool := NewWorkerPool(ctx, 10, 1000)
pool.Start()

for i := 0; i < 100; i++ {
    pool.Submit(func(ctx context.Context) error {
        return processItem(ctx, i)
    })
}

pool.Shutdown() // Graceful
```

---

### 6. go-testing (Testing Strategies)

**When to use:**
- Writing unit tests
- Integration tests
- API tests
- Benchmarks

**Patterns covered:**
- Testing pyramid
- testcontainers
- Mocking with testify
- Integration tests
- Benchmarking
- Race detection

**Example:**
```go
// ✅ Integration test with testcontainers
func TestUserRepository_Save(t *testing.T) {
    pgContainer, _ := postgres.RunContainer(ctx, ...)
    defer pgContainer.Terminate(ctx)
    
    db, _ := sql.Open("postgres", connString)
    repo := NewUserRepositoryImpl(db)
    
    // Test with real database
    err := repo.Save(ctx, user)
    assert.NoError(t, err)
}
```

---

## 🏗️ Architecture Context

### Project: Query Builder Platform

**Description:** Business Intelligence tool for multi-database querying, visualization, and analytics

**Tech Stack:**
- Go 1.23+
- Gin Gonic (HTTP)
- PostgreSQL (metadata)
- Redis (cache)
- Kafka/RabbitMQ (events)
- Asynq (background jobs)
- WebSocket (real-time)

**Bounded Contexts:**
1. Connection - Database connections, schema sync
2. Card (Query) - SQL queries, execution, caching
3. Dashboard - Layouts, auto-refresh, sharing
4. Collection - Folders, tags, organization
5. Permission - RBAC, user groups, RLS
6. Import/Export - CSV/Excel processing

**Performance Goals:**
- Query execution: <50ms P99
- Dashboard (5 cards): <250ms
- CSV import: 50k rows/sec
- Concurrent users: 5000+
- Memory: <200MB per instance

---

## 🚀 Common Workflows

### Workflow 1: Create New Aggregate

```
1. Read: ddd-go skill
2. Create aggregate in internal/domain/{context}/aggregate/
3. Define value objects
4. Add domain events
5. Implement business methods
6. Create repository interface
7. Write unit tests (go-testing skill)
8. Implement repository (go-backend skill)
9. Create use case (ddd-go skill)
10. Add HTTP handler (go-backend skill)
```

### Workflow 2: Add Parallel Query Execution

```
1. Read: go-concurrency skill
2. Read: query-builder skill
3. Identify queries to parallelize
4. Use errgroup pattern
5. Add mutex for shared state
6. Set concurrency limit
7. Benchmark (go-testing skill)
8. Add metrics
```

### Workflow 3: Implement CSV Import

```
1. Read: query-builder skill
2. Use streaming pattern
3. Batch inserts (1000 rows)
4. Add progress tracking
5. Background job with Asynq
6. WebSocket progress updates
7. Test with large files (go-testing skill)
```

---

## 📊 Performance Benchmarks

Based on skills implementation:

| Operation | Performance | Skill |
|-----------|-------------|-------|
| Simple query | 8ms | query-builder |
| Dashboard (5 cards) | 250ms (parallel) vs 880ms (serial) | go-concurrency |
| CSV import (1M rows) | 30s | query-builder |
| Memory (10GB CSV) | <50MB | go-concurrency |
| Concurrent users | 5000 | go-backend |

---

## ✅ Validation Checklist

Before committing code, verify:

### Domain Layer
- [ ] No infrastructure dependencies
- [ ] Business rules in aggregates
- [ ] Value objects immutable
- [ ] Domain events raised
- [ ] Unit tests >90% coverage

### Application Layer
- [ ] Use cases thin (orchestration only)
- [ ] Commands return IDs
- [ ] Queries return DTOs
- [ ] No business logic

### Infrastructure Layer
- [ ] Repository per aggregate
- [ ] Events published after commit
- [ ] Connection pooling
- [ ] Migrations added

### Concurrency
- [ ] errgroup for parallel tasks
- [ ] Context propagation
- [ ] Goroutine cleanup
- [ ] No race conditions (test with `-race`)

### Testing
- [ ] Unit tests for domain
- [ ] Integration tests for repos
- [ ] testcontainers for DB tests
- [ ] Coverage >75%

---

## 🎓 Learning Path

### Week 1-2: Foundations
- [ ] Read RULES.md
- [ ] Study go-backend skill
- [ ] Study ddd-go skill
- [ ] Implement Connection Context

### Week 3-4: Core Features
- [ ] Study query-builder skill
- [ ] Implement Card Context
- [ ] Add query caching
- [ ] Implement multi-DB support

### Week 5-6: Advanced
- [ ] Study go-concurrency skill
- [ ] Parallel dashboard execution
- [ ] WebSocket real-time updates
- [ ] CSV streaming import

### Week 7-8: Production Ready
- [ ] Study go-testing skill
- [ ] Write comprehensive tests
- [ ] Add observability
- [ ] Performance tuning

---

## 📚 External Resources

### Go Fundamentals
- [Effective Go](https://go.dev/doc/effective_go)
- [Uber Go Style Guide](https://github.com/uber-go/guide)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)

### Concurrency
- [Go Concurrency Patterns (Rob Pike)](https://www.youtube.com/watch?v=f6kdp27TYZs)
- [Concurrency in Go (book)](https://www.oreilly.com/library/view/concurrency-in-go/9781491941294/)

### DDD
- [Domain-Driven Design by Eric Evans](https://www.domainlanguage.com/ddd/)
- [Implementing DDD by Vaughn Vernon](https://vaughnvernon.com/)
- [ThreeDotsLabs DDD Example (Go)](https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example)

### Libraries
- [Gin Framework](https://gin-gonic.com/docs/)
- [pgx (PostgreSQL)](https://pkg.go.dev/github.com/jackc/pgx/v5)
- [testify](https://github.com/stretchr/testify)
- [testcontainers-go](https://golang.testcontainers.org/)
- [Google Wire](https://github.com/google/wire)

---

## 🔧 Tools & Commands

### Code Generation
```bash
# Generate Wire dependencies
wire gen ./...

# Generate SQLC queries
sqlc generate

# Generate mocks
mockgen -source=repo.go -destination=mocks/repo.go
```

### Testing
```bash
# Run all tests
go test ./...

# With race detector
go test -race ./...

# With coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Benchmarks
go test -bench=. -benchmem
```

### Linting
```bash
# golangci-lint
golangci-lint run

# go vet
go vet ./...

# gofmt
gofmt -s -w .
```

---

## 📝 Contributing to Skills

Found a better pattern? Suggest improvements:

1. Document the pattern
2. Provide code examples
3. Show performance benefits
4. Add to relevant skill file
5. Update RULES.md if needed

---

## ⚡ Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│              QUERY BUILDER PLATFORM - QUICK REF              │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│ BEFORE CODING:                                                │
│   1. Read RULES.md                                            │
│   2. Read relevant skills                                     │
│   3. Check decision matrix                                    │
│                                                               │
│ DOMAIN LAYER (internal/domain/):                              │
│   ✅ Pure business logic                                      │
│   ✅ Value objects (immutable)                                │
│   ✅ Aggregates (rich models)                                 │
│   ✅ Domain events                                            │
│   ❌ No infrastructure deps                                   │
│                                                               │
│ APPLICATION LAYER (internal/application/):                    │
│   ✅ Use cases (orchestration)                                │
│   ✅ Commands/Queries (CQRS)                                  │
│   ✅ DTOs                                                      │
│   ❌ No business logic                                        │
│                                                               │
│ INFRASTRUCTURE (internal/infrastructure/):                    │
│   ✅ Repository implementations                               │
│   ✅ Query engines (multi-DB)                                 │
│   ✅ HTTP clients                                             │
│   ✅ Message queues                                           │
│                                                               │
│ PERFORMANCE:                                                  │
│   ✅ errgroup for parallel queries                            │
│   ✅ Connection pooling (one per DB)                          │
│   ✅ Query caching (Redis)                                    │
│   ✅ Streaming for large files                                │
│   ❌ No serial query execution                                │
│   ❌ No new connection per query                              │
│                                                               │
│ TESTING:                                                      │
│   ✅ testcontainers for integration                           │
│   ✅ Coverage >75%                                            │
│   ✅ Benchmark critical code                                  │
│   ✅ Run with -race flag                                      │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

**Version:** 1.0.0  
**Last Updated:** 2026-02-10  
**Maintained By:** MVT (Backend Developer & DevOps Engineer)  
**License:** Internal Use
