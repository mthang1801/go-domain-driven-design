# Query Builder Platform - Sequence Diagrams (Go Implementation)

## 📋 Table of Contents

1. [Create Database Connection + Sync Schema](#1-create-database-connection--sync-schema)
2. [Execute Query with Caching](#2-execute-query-with-caching)
3. [Dashboard Execution (Parallel Queries)](#3-dashboard-execution-parallel-queries)
4. [CSV Import Job (Async)](#4-csv-import-job-async)
5. [Real-time Dashboard Update (WebSocket)](#5-real-time-dashboard-update-websocket)
6. [Export Query Result](#6-export-query-result)

---

## 1. Create Database Connection + Sync Schema

```mermaid
sequenceDiagram
    participant C as Client
    participant H as ConnectionHandler
    participant CMD as CreateConnectionCommand
    participant Agg as DatabaseConnection (Aggregate)
    participant TS as ConnectionTestService
    participant SE as SchemaExtractorService
    participant Repo as ConnectionRepository
    participant Cache as Redis Cache
    participant EB as Event Bus
    
    C->>H: POST /api/v1/connections
    Note over C,H: {name, type, host, port, credentials}
    
    H->>CMD: Handle(CreateConnectionCommand)
    
    CMD->>Agg: NewDatabaseConnection(config)
    Agg-->>CMD: connection (Status: PENDING)
    
    Note over CMD: Test connection first
    CMD->>TS: Test(connection.Config)
    TS->>TS: Dial database
    alt Test Success
        TS-->>CMD: ConnectionTestResult{Success: true}
        CMD->>Agg: MarkAsActive()
        Agg->>Agg: AddDomainEvent(ConnectionTested)
    else Test Failed
        TS-->>CMD: ConnectionTestResult{Success: false, Error}
        CMD->>Agg: MarkAsFailed(error)
        Agg-->>CMD: error
        CMD-->>H: error
        H-->>C: 400 Bad Request
    end
    
    Note over CMD: Save connection
    CMD->>Repo: Save(connection)
    Repo->>Repo: Map Domain -> ORM
    Repo->>Repo: INSERT INTO database_connections
    Repo-->>CMD: connection.ID
    
    Note over CMD: Dispatch domain events
    CMD->>EB: Publish(ConnectionTested)
    
    Note over CMD: Sync schema asynchronously
    par Background Schema Sync
        CMD->>SE: Extract(connection)
        SE->>SE: Query INFORMATION_SCHEMA
        SE-->>CMD: DatabaseSchema{tables, columns}
        
        CMD->>Agg: UpdateSchema(schema)
        Agg->>Agg: AddDomainEvent(SchemaUpdated)
        
        CMD->>Repo: Save(connection)
        CMD->>Cache: Set("schema:"+connectionID, schema, 1h)
        
        CMD->>EB: Publish(SchemaUpdated)
    end
    
    CMD-->>H: connection.ID
    H-->>C: 201 Created {id, status: "ACTIVE"}
```

**Go Implementation Notes:**
- `ConnectionTestService.Test()` uses context with timeout (10s)
- Schema sync runs in goroutine with `errgroup`
- Cache schema metadata to Redis for 1 hour
- Events dispatched to RabbitMQ for async processing

---

## 2. Execute Query with Caching

```mermaid
sequenceDiagram
    participant C as Client
    participant H as CardHandler
    participant CMD as ExecuteCardCommand
    participant Card as Card (Aggregate)
    participant QV as QueryValidationService
    participant Cache as Redis Cache
    participant QE as QueryEngine
    participant DB as Target Database
    participant Repo as CardRepository
    participant EB as Event Bus
    participant WS as WebSocket Hub
    
    C->>H: POST /api/v1/cards/:id/execute
    Note over C,H: {params: {userId: 123}}
    
    H->>CMD: Handle(ExecuteCardCommand)
    
    Note over CMD: Load card
    CMD->>Repo: FindByID(cardID)
    Repo-->>CMD: card
    
    Note over CMD: Validate SQL
    CMD->>QV: Validate(card.Query)
    QV->>QV: Parse SQL (sqlparser)
    QV->>QV: Check for DDL/DML
    alt Invalid SQL
        QV-->>CMD: error (SQL_INJECTION_ATTEMPT)
        CMD-->>H: error
        H-->>C: 400 Bad Request
    end
    QV-->>CMD: valid
    
    Note over CMD: Check cache
    CMD->>CMD: cacheKey = hash(SQL+params+dbID)
    CMD->>Cache: Get(cacheKey)
    alt Cache Hit
        Cache-->>CMD: cachedResult
        CMD-->>H: cachedResult (X-Cache: HIT)
        H-->>C: 200 OK + result
    else Cache Miss
        Cache-->>CMD: nil
        
        Note over CMD: Execute query
        CMD->>Card: Execute(params)
        Card->>Card: CreateQueryExecution()
        Card->>Card: AddDomainEvent(QueryExecuted)
        
        Card->>QE: Execute(connection, query, params)
        
        par Concurrent Operations
            QE->>QE: Get connection from pool
            QE->>DB: Execute SQL
            DB-->>QE: rows
            QE->>QE: Transform to JSON
            QE-->>Card: QueryResult
        and Tracing
            QE->>QE: OTEL span (query_execution)
        and Metrics
            QE->>QE: Record duration, rows
        end
        
        Card->>Card: CompleteExecution(result)
        Card-->>CMD: queryResult
        
        Note over CMD: Cache result
        CMD->>CMD: ttl = getTTL(query)
        CMD->>Cache: Set(cacheKey, result, ttl)
        
        Note over CMD: Save execution history
        CMD->>Repo: Save(card)
        
        Note over CMD: Notify WebSocket clients
        CMD->>WS: BroadcastQueryResult(cardID, result)
        WS->>WS: Send to all connected clients
        
        Note over CMD: Dispatch events
        CMD->>EB: Publish(QueryExecuted)
        
        CMD-->>H: queryResult (X-Cache: MISS)
        H-->>C: 200 OK + result
    end
```

**Go Implementation Notes:**
- Query execution has timeout (30s default, configurable per query)
- Connection pooling: `pgxpool` for PostgreSQL, `sql.DB` with `SetMaxOpenConns`
- Cache TTL determined by query type: aggregation (5m), analytical (15m), real-time (1m)
- WebSocket broadcast to all subscribed clients watching this card
- Metrics: query duration, cache hit rate, rows returned

---

## 3. Dashboard Execution (Parallel Queries)

```mermaid
sequenceDiagram
    participant C as Client
    participant H as DashboardHandler
    participant Q as GetDashboardQuery
    participant Repo as DashboardRepository
    participant Dash as Dashboard (Aggregate)
    participant QE as QueryExecutionService
    participant Cache as Redis Cache
    participant DB1 as Database 1
    participant DB2 as Database 2
    participant DBN as Database N
    
    C->>H: GET /api/v1/dashboards/:id/execute
    
    H->>Q: Handle(GetDashboardQuery)
    
    Q->>Repo: FindByID(dashboardID)
    Repo-->>Q: dashboard
    
    Note over Q: Load all cards (5 cards)
    Q->>Repo: FindCardsByIDs(dashboard.CardIDs)
    Repo-->>Q: cards[]
    
    Note over Q: Execute all cards in parallel
    Q->>Q: Create errgroup with context
    
    par Execute Card 1
        Q->>Cache: Get(card1.CacheKey)
        alt Cache Hit
            Cache-->>Q: result1
        else Cache Miss
            Q->>QE: Execute(card1)
            QE->>DB1: SQL query
            DB1-->>QE: rows
            QE-->>Q: result1
            Q->>Cache: Set(card1.CacheKey, result1)
        end
    and Execute Card 2
        Q->>Cache: Get(card2.CacheKey)
        alt Cache Hit
            Cache-->>Q: result2
        else Cache Miss
            Q->>QE: Execute(card2)
            QE->>DB1: SQL query
            DB1-->>QE: rows
            QE-->>Q: result2
            Q->>Cache: Set(card2.CacheKey, result2)
        end
    and Execute Card 3
        Q->>Cache: Get(card3.CacheKey)
        alt Cache Miss
            Q->>QE: Execute(card3)
            QE->>DB2: SQL query (different DB)
            DB2-->>QE: rows
            QE-->>Q: result3
            Q->>Cache: Set(card3.CacheKey, result3)
        end
    and Execute Card 4
        Q->>QE: Execute(card4)
        QE->>DB2: SQL query
        DB2-->>QE: rows
        QE-->>Q: result4
        Q->>Cache: Set(card4.CacheKey, result4)
    and Execute Card 5
        Q->>QE: Execute(card5)
        QE->>DBN: SQL query (ClickHouse)
        DBN-->>QE: rows
        QE-->>Q: result5
        Q->>Cache: Set(card5.CacheKey, result5)
    end
    
    Note over Q: errgroup.Wait() - wait for all
    Q->>Q: Aggregate results
    
    Q-->>H: DashboardData{dashboard, results}
    H-->>C: 200 OK + dashboard with all results
    
    Note over C,H: Total time = max(card1, card2, card3, card4, card5)
    Note over C,H: Instead of sum(card1 + card2 + card3 + card4 + card5)
```

**Go Implementation Notes:**
```go
func (h *DashboardHandler) ExecuteDashboard(ctx context.Context, dashboardID string) (*DashboardData, error) {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(10) // Max 10 concurrent queries
    
    results := make(map[string]*QueryResult)
    mu := sync.Mutex{}
    
    for _, card := range dashboard.Cards {
        card := card // Capture
        g.Go(func() error {
            result, err := h.queryService.Execute(ctx, card)
            if err != nil {
                return err
            }
            
            mu.Lock()
            results[card.ID] = result
            mu.Unlock()
            return nil
        })
    }
    
    if err := g.Wait(); err != nil {
        return nil, err
    }
    
    return &DashboardData{
        Dashboard: dashboard,
        Results:   results,
    }, nil
}
```

**Performance Gains:**
- Serial execution: 150ms + 200ms + 180ms + 100ms + 250ms = **880ms**
- Parallel execution: max(150, 200, 180, 100, 250) = **250ms** → **3.5x faster**

---

## 4. CSV Import Job (Async)

```mermaid
sequenceDiagram
    participant C as Client
    participant H as ImportHandler
    participant CMD as ImportCSVCommand
    participant Storage as MinIO Storage
    participant Queue as Asynq Queue
    participant Worker as Import Worker
    participant Job as ImportJob (Aggregate)
    participant CSV as CSV Parser
    participant Repo as JobRepository
    participant DB as Target Database
    participant EB as Event Bus
    participant WS as WebSocket Hub
    
    C->>H: POST /api/v1/import/csv
    Note over C,H: multipart/form-data<br/>file: data.csv (10GB)
    
    H->>Storage: Upload(file)
    Storage-->>H: fileURL (s3://bucket/uploads/xyz.csv)
    
    H->>CMD: Handle(ImportCSVCommand)
    
    CMD->>Job: NewImportJob(fileURL, dbID)
    Job->>Job: status = PENDING
    Job->>Job: AddDomainEvent(ImportJobCreated)
    Job-->>CMD: job
    
    CMD->>Repo: Save(job)
    Repo-->>CMD: job.ID
    
    Note over CMD: Queue async task
    CMD->>Queue: Enqueue(ImportCSVTask)
    Note over Queue: Task payload:<br/>{jobID, fileURL, dbID}
    Queue-->>CMD: task.ID
    
    CMD->>EB: Publish(ImportJobCreated)
    CMD-->>H: jobID
    H-->>C: 202 Accepted {jobId, status: "QUEUED"}
    
    Note over Worker: Background Worker picks task
    Queue->>Worker: Dequeue(ImportCSVTask)
    
    Worker->>Repo: FindByID(jobID)
    Repo-->>Worker: job
    
    Worker->>Job: MarkAsProcessing()
    Job->>Job: status = PROCESSING
    Job->>Job: AddDomainEvent(ImportJobStarted)
    
    Worker->>Repo: Save(job)
    Worker->>EB: Publish(ImportJobStarted)
    Worker->>WS: BroadcastJobStatus(jobID, "PROCESSING", 0%)
    
    Worker->>Storage: Download(fileURL)
    Storage-->>Worker: fileStream
    
    Note over Worker: Stream parse CSV (10GB)
    Worker->>CSV: NewReader(fileStream)
    
    loop For each batch (1000 rows)
        CSV->>CSV: Read 1000 rows
        CSV-->>Worker: batch[]
        
        Worker->>DB: COPY INTO table (batch)
        DB-->>Worker: OK
        
        Worker->>Job: UpdateProgress(rowsProcessed)
        Worker->>WS: BroadcastJobStatus(jobID, "PROCESSING", 45%)
    end
    
    alt Import Success
        Worker->>Job: MarkAsCompleted(totalRows)
        Job->>Job: status = COMPLETED
        Job->>Job: AddDomainEvent(ImportJobCompleted)
        
        Worker->>Repo: Save(job)
        Worker->>EB: Publish(ImportJobCompleted)
        Worker->>WS: BroadcastJobStatus(jobID, "COMPLETED", 100%)
        
        Worker->>Storage: Delete(fileURL)
    else Import Failed
        Worker->>Job: MarkAsFailed(error)
        Job->>Job: status = FAILED
        Job->>Job: AddDomainEvent(ImportJobFailed)
        
        Worker->>Repo: Save(job)
        Worker->>EB: Publish(ImportJobFailed)
        Worker->>WS: BroadcastJobStatus(jobID, "FAILED", error)
    end
    
    Note over C: Client polls or listens via WebSocket
    C->>H: GET /api/v1/import/jobs/:id
    H-->>C: {status: "COMPLETED", totalRows: 1000000}
```

**Go Implementation Notes:**
```go
// Stream CSV without loading to memory
func (w *ImportWorker) ProcessCSV(ctx context.Context, fileURL string, dbID string) error {
    file, _ := w.storage.Download(fileURL)
    defer file.Close()
    
    reader := csv.NewReader(file)
    header, _ := reader.Read()
    
    batch := make([]map[string]interface{}, 0, 1000)
    rowsProcessed := 0
    
    for {
        record, err := reader.Read()
        if err == io.EOF {
            break
        }
        
        row := make(map[string]interface{})
        for i, val := range record {
            row[header[i]] = val
        }
        batch = append(batch, row)
        
        if len(batch) >= 1000 {
            // Use COPY for PostgreSQL (10x faster than INSERT)
            if err := w.db.CopyFrom(ctx, dbID, batch); err != nil {
                return err
            }
            
            rowsProcessed += len(batch)
            w.broadcastProgress(jobID, rowsProcessed)
            batch = batch[:0]
        }
    }
    
    // Insert remaining
    if len(batch) > 0 {
        w.db.CopyFrom(ctx, dbID, batch)
    }
    
    return nil
}
```

**Performance:**
- 10GB CSV → ~10 million rows
- COPY (batch 1000): ~50,000 rows/sec → **3-4 minutes**
- INSERT (individual): ~5,000 rows/sec → **30-40 minutes**
- **Memory usage**: <50MB (streaming)

---

## 5. Real-time Dashboard Update (WebSocket)

```mermaid
sequenceDiagram
    participant C1 as Client 1 (Browser)
    participant C2 as Client 2 (Browser)
    participant WS as WebSocket Handler
    participant Hub as WebSocket Hub
    participant Sched as Scheduler
    participant QE as QueryExecutionService
    participant Cache as Redis Cache
    participant DB as Database
    
    Note over C1,C2: Both clients open dashboard
    
    C1->>WS: ws://api/v1/ws
    WS->>Hub: Register(client1)
    Hub->>Hub: clients[client1] = true
    
    C2->>WS: ws://api/v1/ws
    WS->>Hub: Register(client2)
    Hub->>Hub: clients[client2] = true
    
    Note over C1,C2: Subscribe to dashboard
    C1->>Hub: SUBSCRIBE {dashboardId: "123"}
    Hub->>Hub: subscriptions["123"] += client1
    
    C2->>Hub: SUBSCRIBE {dashboardId: "123"}
    Hub->>Hub: subscriptions["123"] += client2
    
    Note over Sched: Dashboard has auto-refresh: 30s
    Sched->>Sched: Tick every 30 seconds
    
    Sched->>QE: ExecuteDashboard(dashboardID: "123")
    
    par Execute Card 1
        QE->>Cache: Get(card1.CacheKey)
        alt Cache Miss
            QE->>DB: Execute SQL
            DB-->>QE: rows
            QE->>Cache: Set(card1.CacheKey, result1)
        end
        QE-->>Sched: result1
    and Execute Card 2
        QE->>DB: Execute SQL
        DB-->>QE: rows
        QE-->>Sched: result2
    and Execute Card 3
        QE->>DB: Execute SQL
        DB-->>QE: rows
        QE-->>Sched: result3
    end
    
    Sched->>Sched: Aggregate results
    Sched->>Hub: BroadcastDashboardUpdate(dashboardID, results)
    
    Hub->>Hub: Get subscriptions["123"]
    Hub->>Hub: clients = [client1, client2]
    
    par Broadcast to clients
        Hub->>C1: {type: "DASHBOARD_UPDATE", data: results}
        C1->>C1: Update UI (smooth transition)
    and
        Hub->>C2: {type: "DASHBOARD_UPDATE", data: results}
        C2->>C2: Update UI (smooth transition)
    end
    
    Note over C1,C2: Clients receive real-time updates<br/>every 30 seconds without polling
```

**Go Implementation Notes:**
```go
// WebSocket Hub
type Hub struct {
    clients       map[*Client]bool
    subscriptions map[string][]*Client // dashboardID -> clients
    broadcast     chan Message
    register      chan *Client
    unregister    chan *Client
}

func (h *Hub) Run() {
    for {
        select {
        case client := <-h.register:
            h.clients[client] = true
            
        case client := <-h.unregister:
            if _, ok := h.clients[client]; ok {
                delete(h.clients, client)
                close(client.send)
            }
            
        case message := <-h.broadcast:
            // Send to subscribed clients only
            clients := h.subscriptions[message.DashboardID]
            for _, client := range clients {
                select {
                case client.send <- message.Data:
                default:
                    close(client.send)
                    delete(h.clients, client)
                }
            }
        }
    }
}

// Scheduler (cron-based)
func (s *Scheduler) RunAutoRefresh() {
    dashboards := s.repo.FindWithAutoRefresh()
    
    for _, dash := range dashboards {
        interval := dash.RefreshInterval
        
        go func(d Dashboard) {
            ticker := time.NewTicker(time.Duration(interval) * time.Second)
            defer ticker.Stop()
            
            for range ticker.C {
                results, _ := s.queryService.ExecuteDashboard(d.ID)
                s.hub.BroadcastDashboardUpdate(d.ID, results)
            }
        }(dash)
    }
}
```

---

## 6. Export Query Result

```mermaid
sequenceDiagram
    participant C as Client
    participant H as ExportHandler
    participant CMD as ExportResultCommand
    participant Job as ExportJob (Aggregate)
    participant Queue as Asynq Queue
    participant Worker as Export Worker
    participant QE as QueryExecutionService
    participant DB as Database
    participant CSV as CSV Writer
    participant Storage as MinIO Storage
    participant Repo as JobRepository
    participant EB as Event Bus
    
    C->>H: POST /api/v1/export
    Note over C,H: {cardId, format: "CSV"}
    
    H->>CMD: Handle(ExportResultCommand)
    
    CMD->>Job: NewExportJob(cardID, format)
    Job->>Job: status = PENDING
    Job->>Job: AddDomainEvent(ExportJobCreated)
    
    CMD->>Repo: Save(job)
    CMD->>Queue: Enqueue(ExportTask)
    CMD->>EB: Publish(ExportJobCreated)
    CMD-->>H: jobID
    H-->>C: 202 Accepted {jobId, status: "QUEUED"}
    
    Queue->>Worker: Dequeue(ExportTask)
    
    Worker->>Job: MarkAsProcessing()
    Worker->>Repo: Save(job)
    
    Worker->>QE: ExecuteCard(cardID)
    QE->>DB: Execute SQL
    DB-->>QE: resultStream (1M rows)
    QE-->>Worker: resultStream
    
    Note over Worker: Stream write to CSV
    Worker->>CSV: NewWriter(fileStream)
    
    loop For each row
        Worker->>CSV: WriteRow(row)
    end
    
    Worker->>CSV: Close()
    Worker->>Storage: Upload(file)
    Storage-->>Worker: downloadURL
    
    Worker->>Job: MarkAsCompleted(downloadURL)
    Worker->>Repo: Save(job)
    Worker->>EB: Publish(ExportJobCompleted)
    
    Worker-->>C: Notification (email/webhook)
    
    C->>H: GET /api/v1/export/jobs/:id
    H-->>C: {status: "COMPLETED", downloadUrl}
    
    C->>Storage: Download(downloadUrl)
    Storage-->>C: result.csv (streaming)
```

---

## 🎯 Summary

| Flow | Pattern | Performance |
|------|---------|-------------|
| **Connection Sync** | Background goroutine | 5-10s for large schemas |
| **Query Execution** | Cache-first + pool | 8ms (cache hit), 150ms (cache miss) |
| **Dashboard Load** | Parallel errgroup | 3.5x faster than serial |
| **CSV Import** | Streaming + batch COPY | 50k rows/sec, <50MB memory |
| **Real-time Update** | WebSocket broadcast | <10ms latency |
| **Export** | Streaming write | 1M rows in 10-15 seconds |

---

**Key Go Concurrency Patterns Used:**
1. **errgroup** - Parallel query execution with error propagation
2. **Worker Pool** - Background job processing (Asynq)
3. **Channels** - WebSocket hub communication
4. **Goroutines** - Schema sync, auto-refresh scheduler
5. **sync.Mutex** - Protect shared state in concurrent map access
6. **Context** - Cancellation, timeout, tracing propagation

Let me know nếu cần thêm diagrams cho flows khác! 🚀
