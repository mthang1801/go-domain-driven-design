# Query Builder Platform - Complete Documentation Index

## 📚 Overview

Complete documentation set for the **Query Builder Platform** - a high-performance Business Intelligence tool built with Go, including architecture design, skills for AI agents, and implementation guides.

---

## 📁 File Structure

```
outputs/
├── 00-PROJECT-SUMMARY.md              # Executive summary
├── query-builder-go-architecture.md   # Complete architecture design
├── query-builder-sequence-diagrams.md # Key flows & diagrams
├── database-erd.md                    # Database schema (original)
├── original-architecture.md           # Original design doc (reference)
│
└── skills/                            # AI Agent Skills & Rules
    ├── README.md                      # Skills package overview
    ├── RULES.md                       # Core development rules
    │
    ├── go-backend/
    │   └── SKILL.md                   # General Go backend patterns
    ├── query-builder/
    │   └── SKILL.md                   # Platform-specific patterns
    ├── ddd-go/
    │   └── SKILL.md                   # Domain-Driven Design
    ├── go-concurrency/
    │   └── SKILL.md                   # Concurrency patterns
    └── go-testing/
        └── SKILL.md                   # Testing strategies
```

---

## 📖 Document Guide

### 1. Start Here: PROJECT SUMMARY

**File:** `00-PROJECT-SUMMARY.md`

**Purpose:** High-level overview of the entire project

**Contents:**
- Project overview & business domains
- Tech stack comparison (NestJS vs Go)
- Performance benchmarks (5-10x improvements)
- Cost savings analysis (85% reduction)
- Core features & patterns
- Migration roadmap
- Benefits summary

**Read if:**
- New to the project
- Need executive summary
- Want to understand "why Go?"

---

### 2. Architecture Design

**File:** `query-builder-go-architecture.md`

**Purpose:** Complete technical architecture specification

**Contents:**
- 6 Bounded Contexts (detailed)
  - Connection Context
  - Card (Query) Context
  - Dashboard Context
  - Collection Context
  - Permission Context
  - Import/Export Context
- Tech stack with rationale
- Project structure (Go DDD style)
- Core patterns implementation
  - Multi-database query engine
  - Parallel execution
  - Streaming CSV/Excel
  - WebSocket real-time
  - Caching strategies
- Security features
- Performance optimizations
- Metrics & observability

**Read if:**
- Implementing any feature
- Need architectural decisions
- Want to understand system design

---

### 3. Sequence Diagrams

**File:** `query-builder-sequence-diagrams.md`

**Purpose:** Visual representation of key flows

**Contains 6 Diagrams:**
1. **Create Database Connection + Sync Schema**
   - Connection testing
   - Schema extraction
   - Background sync

2. **Execute Query with Caching**
   - Cache-first strategy
   - Query validation
   - Result caching
   - WebSocket notification

3. **Dashboard Execution (Parallel Queries)**
   - errgroup parallel execution
   - 3.5x performance gain
   - Cache integration

4. **CSV Import Job (Async)**
   - Streaming import
   - Background worker
   - Progress tracking
   - WebSocket updates

5. **Real-time Dashboard Update (WebSocket)**
   - Auto-refresh scheduler
   - Hub broadcast
   - Client subscriptions

6. **Export Query Result**
   - Async job queue
   - Streaming export
   - File storage

**Read if:**
- Implementing any of these flows
- Need to understand component interactions
- Debugging issues

---

### 4. Database Schema

**File:** `database-erd.md`

**Purpose:** PostgreSQL metadata database schema

**Contents:**
- Complete ERD diagrams
- Table details with constraints
- Relationships & cardinality
- Indexes & performance
- Migration scripts

**Read if:**
- Working with database
- Writing migrations
- Implementing repositories

---

### 5. Original Architecture (Reference)

**File:** `original-architecture.md`

**Purpose:** Original NestJS/TypeScript design

**Use for:**
- Understanding original requirements
- Comparing with Go implementation
- Migration reference

---

## 🎯 AI Agent Skills Package

### Overview

Complete skill set for AI agents to build the platform following best practices.

**Location:** `skills/`

**Structure:**
```
skills/
├── README.md          # Overview & quick start
├── RULES.md           # Core development rules (READ FIRST!)
└── [5 skill directories]
```

---

### Skills Quick Reference

| Skill | Use When | Key Patterns |
|-------|----------|--------------|
| **go-backend** | HTTP handlers, middleware, DI | Gin, Wire, Error handling |
| **query-builder** | Multi-DB, dashboards, import/export | Strategy, Parallel, Streaming |
| **ddd-go** | Domain models, aggregates, events | DDD building blocks, CQRS |
| **go-concurrency** | Parallel tasks, background jobs | Worker pool, errgroup, Pipeline |
| **go-testing** | Unit, integration, E2E tests | testcontainers, Benchmarks |

---

### Skill Details

#### 1. RULES.md (Mandatory Read)

**Contains:**
- 16 core development rules
- Architecture decision rules
- Performance rules
- Security rules
- Common mistakes to avoid
- Decision matrix
- Pull request checklist

**Key Rules:**
```
Rule 1: Layer separation (strict)
Rule 2: No business logic outside domain
Rule 3: Query engine pattern (strategy)
Rule 4: Parallel execution for multiple queries
Rule 5: Connection pooling (always)
Rule 6: Query result caching
Rule 7: Streaming for large files
Rule 8: SQL injection prevention
Rule 9: Row-level security (RLS)
Rule 10: Test pyramid
```

---

#### 2. go-backend/SKILL.md

**Topics:**
- Go project structure
- Gin handler patterns
- Middleware patterns
- Dependency injection (Google Wire)
- Error handling
- Repository pattern
- Testing with mocks
- Common pitfalls

**Example Patterns:**
- Thin handlers (delegate to use cases)
- Domain errors with context
- Repository implementation
- Integration tests

---

#### 3. query-builder/SKILL.md

**Topics:**
- Multi-database query engine
- Strategy pattern for DB drivers
- Parallel dashboard execution
- Streaming CSV import/export
- WebSocket real-time updates
- Query caching strategies
- Security (SQL injection, RLS)

**Example Patterns:**
- PostgreSQL, MySQL, MongoDB, ClickHouse engines
- errgroup for parallel queries (3.5x faster)
- Streaming CSV with <50MB memory
- WebSocket hub & auto-refresh

---

#### 4. ddd-go/SKILL.md

**Topics:**
- Entity & BaseEntity
- Value objects (immutable)
- Aggregate roots
- Domain events
- Repository pattern (port & adapter)
- Domain services
- CQRS pattern
- Specification pattern

**Example Patterns:**
- Rich domain models (not anemic)
- Event-driven architecture
- Factory methods
- Invariants validation

---

#### 5. go-concurrency/SKILL.md

**Topics:**
- Goroutines basics
- Channels
- Worker pool
- errgroup (fan-out/fan-in)
- Pipeline
- Rate limiting (semaphore)
- Timeout & cancellation
- Select multiplexing

**Example Patterns:**
- Worker pool for background jobs
- Dashboard parallel execution
- CSV import with progress
- Auto-refresh scheduler

---

#### 6. go-testing/SKILL.md

**Topics:**
- Testing pyramid
- Unit testing (aggregates, VOs, use cases)
- Integration testing (repositories, APIs)
- testcontainers
- Mocking with testify
- Benchmarking
- Race detection
- Coverage targets

**Example Patterns:**
- Repository tests with real PostgreSQL
- Concurrent execution tests
- Performance benchmarks
- Test helpers & fixtures

---

## 🚀 Usage Workflows

### For Developers

**Workflow 1: Understand the Project**
```
1. Read: 00-PROJECT-SUMMARY.md (10 min)
2. Read: query-builder-go-architecture.md (30 min)
3. Review: query-builder-sequence-diagrams.md (20 min)
4. Check: database-erd.md (10 min)
Total: ~70 minutes to full context
```

**Workflow 2: Implement New Feature**
```
1. Check: RULES.md for principles
2. Identify: Bounded context
3. Read: Relevant architecture section
4. Review: Sequence diagram
5. Study: Relevant skills (go-backend, ddd-go, etc.)
6. Write: Code following patterns
7. Test: Following go-testing skill
8. Verify: Against pull request checklist
```

---

### For AI Agents

**Workflow 1: Code Generation**
```
1. ALWAYS read: skills/RULES.md first
2. Identify task domain
3. Read relevant skill(s):
   - HTTP API? → go-backend
   - Multi-DB? → query-builder
   - Domain? → ddd-go
   - Concurrent? → go-concurrency
4. Generate code following patterns
5. Self-check against rules
```

**Workflow 2: Code Review**
```
1. Check: Layer separation (Rule 1)
2. Verify: Business logic location (Rule 2)
3. Check: Performance patterns (Rules 4-7)
4. Verify: Security (Rules 8-9)
5. Check: Testing (Rule 10)
6. Use: Pull request checklist (RULES.md)
```

---

## 📊 Key Performance Targets

From architecture & skills:

| Metric | Target | Achieved via |
|--------|--------|-------------|
| Query execution | <50ms P99 | Connection pooling, caching |
| Dashboard (5 cards) | <250ms | Parallel execution (errgroup) |
| CSV import | 50k rows/sec | Streaming + batch COPY |
| Memory (10GB CSV) | <50MB | Streaming, no full load |
| Concurrent users | 5000+ | Worker pools, goroutines |
| Code coverage | >75% | Unit + integration tests |

---

## 🔍 Finding Information

### Quick Lookup

**Question:** How do I...

- **Create a new aggregate?**
  → Read: `skills/ddd-go/SKILL.md` → Section 3

- **Execute multiple queries in parallel?**
  → Read: `skills/go-concurrency/SKILL.md` → Pattern 2
  → Read: `query-builder-sequence-diagrams.md` → Diagram 3

- **Import large CSV file?**
  → Read: `skills/query-builder/SKILL.md` → Section 3
  → Read: `query-builder-sequence-diagrams.md` → Diagram 4

- **Write integration tests?**
  → Read: `skills/go-testing/SKILL.md` → Section 2

- **Implement authentication?**
  → Read: `skills/go-backend/SKILL.md` → Section 2.2
  → Read: `query-builder-go-architecture.md` → Security section

- **Setup WebSocket?**
  → Read: `skills/query-builder/SKILL.md` → Section 4
  → Read: `query-builder-sequence-diagrams.md` → Diagram 5

---

### Index by Topic

**Architecture & Design:**
- Overview: `00-PROJECT-SUMMARY.md`
- Detailed: `query-builder-go-architecture.md`
- Flows: `query-builder-sequence-diagrams.md`
- Database: `database-erd.md`

**Development Rules:**
- Core rules: `skills/RULES.md`
- Best practices: All `skills/*/SKILL.md` files

**Patterns:**
- Backend: `skills/go-backend/SKILL.md`
- Domain: `skills/ddd-go/SKILL.md`
- Concurrency: `skills/go-concurrency/SKILL.md`
- Platform: `skills/query-builder/SKILL.md`

**Testing:**
- Strategies: `skills/go-testing/SKILL.md`
- Coverage targets: `skills/RULES.md` → Rule 10

---

## ✅ Document Validation

All documents have been validated for:
- [ ] Technical accuracy
- [ ] Go 1.23+ compatibility
- [ ] Production-ready patterns
- [ ] Performance best practices
- [ ] Security considerations
- [ ] Complete code examples
- [ ] Cross-references

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-02-10 | Initial release - Complete documentation set |

---

## 🤝 Contributing

**To update documentation:**

1. Identify document to update
2. Make changes following same format
3. Update version history
4. Cross-check related documents
5. Validate examples compile

**To add new skill:**

1. Create `skills/new-skill/SKILL.md`
2. Follow existing skill format:
   - Metadata
   - When to use
   - Patterns with examples
   - Common pitfalls
   - Quick reference
3. Update `skills/README.md`
4. Update this index

---

## 🎓 Learning Paths

### Path 1: Backend Developer (New to Go)
```
Week 1:
- Read: 00-PROJECT-SUMMARY.md
- Study: skills/go-backend/SKILL.md
- Practice: Create simple HTTP endpoints

Week 2:
- Study: skills/ddd-go/SKILL.md
- Practice: Implement User aggregate

Week 3:
- Study: skills/go-concurrency/SKILL.md
- Practice: Parallel query execution

Week 4:
- Study: skills/go-testing/SKILL.md
- Practice: Write comprehensive tests
```

### Path 2: Experienced Go Developer (New to DDD)
```
Week 1:
- Read: query-builder-go-architecture.md
- Study: skills/ddd-go/SKILL.md
- Practice: Implement Connection aggregate

Week 2:
- Study: skills/query-builder/SKILL.md
- Practice: Multi-DB query engine
```

### Path 3: AI Agent (Code Generation)
```
Before each task:
1. Read: skills/RULES.md
2. Read: Relevant skill(s)
3. Generate code
4. Self-validate
```

---

## 📚 External Resources

**Go Language:**
- [Effective Go](https://go.dev/doc/effective_go)
- [Uber Go Style Guide](https://github.com/uber-go/guide)

**DDD:**
- [Domain-Driven Design (Eric Evans)](https://www.domainlanguage.com/ddd/)
- [ThreeDotsLabs DDD Example](https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example)

**Concurrency:**
- [Go Concurrency Patterns (Rob Pike)](https://www.youtube.com/watch?v=f6kdp27TYZs)

**Testing:**
- [testcontainers-go](https://golang.testcontainers.org/)
- [testify](https://github.com/stretchr/testify)

---

## 🔗 Quick Links

| Topic | Document | Section |
|-------|----------|---------|
| **Project Overview** | 00-PROJECT-SUMMARY.md | All |
| **Architecture** | query-builder-go-architecture.md | All |
| **Multi-DB Engine** | query-builder-go-architecture.md | Section: Core Patterns #1 |
| **Parallel Execution** | query-builder-sequence-diagrams.md | Diagram #3 |
| **CSV Import** | query-builder-sequence-diagrams.md | Diagram #4 |
| **WebSocket** | query-builder-sequence-diagrams.md | Diagram #5 |
| **Development Rules** | skills/RULES.md | All 16 rules |
| **Testing Strategy** | skills/go-testing/SKILL.md | All |

---

**Total Documentation:**
- Main documents: 5
- Skills: 6 (1 rules + 5 skills)
- Total pages: ~150+ pages of content
- Code examples: 100+
- Diagrams: 6 sequence diagrams + ERD

**Last Updated:** 2026-02-10  
**Version:** 1.0.0  
**Maintained By:** MVT (Backend Developer & DevOps Engineer)
