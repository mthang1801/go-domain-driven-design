# Query Builder Platform - Go Backend Architecture

## 📋 Project Overview

**Query Builder Platform** là hệ thống data visualization & analytics tương đồng với Metabase/Superset, cho phép người dùng:
- Kết nối đến multiple databases (PostgreSQL, MySQL, MongoDB, ClickHouse)
- Tạo và execute SQL queries với visual builder
- Build interactive dashboards
- Import/Export data (CSV, JSON, Excel)
- Manage permissions & sharing

### Đặc điểm chính
- **Ngôn ngữ**: Go 1.23+ (Golang)
- **Framework HTTP**: Gin Gonic v1.10+
- **Kiến trúc**: Clean Architecture + Domain-Driven Design (DDD)
- **Mục tiêu**: Multi-database query engine, real-time analytics, high-concurrency query execution

---

## 🏗️ Tech Stack Chi Tiết

| Layer | Công nghệ & Thư viện | Lý do chọn |
|-------|---------------------|-----------|
| **HTTP Framework** | Gin Gonic v1.10+ | Fast, middleware powerful, WebSocket support |
| **Validation** | go-playground/validator v10 | Comprehensive validation rules |
| **Metadata Database** | PostgreSQL 16+ | Store connections, cards, dashboards, users |
| **Analytics Database** | ClickHouse (optional) | OLAP queries, fast aggregations |
| **Time-Series DB** | TimescaleDB (optional) | Time-series data visualization |
| **Database Drivers** | | |
| - PostgreSQL | pgx/v5 | High-performance PostgreSQL driver |
| - MySQL | go-sql-driver/mysql | Official MySQL driver |
| - MongoDB | mongo-go-driver | Official MongoDB driver |
| - ClickHouse | clickhouse-go | Native ClickHouse driver |
| **Query Parser** | sqlparser-go | SQL parsing & validation |
| **Caching** | Redis 7+ (go-redis/v9) | Query results, schema metadata, session |
| **Job Queue** | Asynq (Redis-based) | Background jobs (import, export, scheduled queries) |
| **Message Queue** | RabbitMQ (amqp091-go) | Domain events, async processing |
| **File Storage** | MinIO (S3-compatible) | Import/export file storage |
| **WebSocket** | gorilla/websocket | Real-time query updates, dashboard refresh |
| **Auth & Security** | JWT (golang-jwt/jwt v5) | Token-based authentication |
| **Data Processing** | | |
| - CSV Parser | encoding/csv + gocsv | CSV import/export |
| - Excel Parser | excelize | Excel file processing |
| - JSON Streaming | jsoniter | High-performance JSON |
| **Observability** | OpenTelemetry + OTLP | Distributed tracing, metrics |
| **Config Management** | Viper + .env | Multi-environment config |
| **Testing** | testify + testcontainers | Unit + integration tests |
| **Dependency Injection** | Google Wire | Compile-time DI |
| **API Documentation** | swaggo/swag | Swagger/OpenAPI generation |
| **Container & Deploy** | Docker + Kubernetes + Helm | Cloud-native deployment |

---

## 📁 Cấu trúc Project (Go DDD Style)

```
query-builder-platform/
├── cmd/
│   ├── api/                              # HTTP API server
│   │   ├── main.go
│   │   └── wire.go                       # Google Wire DI
│   ├── worker/                           # Background workers
│   │   └── main.go                       # Import, export, scheduled queries
│   └── migrator/
│       └── main.go
│
├── internal/
│   ├── domain/                           # 🔵 DOMAIN LAYER
│   │   ├── connection/                   # Connection Context
│   │   │   ├── aggregate/
│   │   │   │   └── database_connection.go
│   │   │   ├── entity/
│   │   │   │   ├── database_schema.go
│   │   │   │   ├── table_metadata.go
│   │   │   │   └── column_metadata.go
│   │   │   ├── valueobject/
│   │   │   │   ├── connection_config.go
│   │   │   │   ├── connection_type.go
│   │   │   │   └── sync_status.go
│   │   │   ├── event/
│   │   │   │   ├── connection_created.go
│   │   │   │   ├── connection_tested.go
│   │   │   │   └── schema_synced.go
│   │   │   ├── service/
│   │   │   │   ├── connection_test_service.go
│   │   │   │   └── schema_extractor_service.go
│   │   │   └── repository/
│   │   │       └── connection_repository.go
│   │   │
│   │   ├── card/                         # Query/Card Context
│   │   │   ├── aggregate/
│   │   │   │   └── card.go               # Card (saved query)
│   │   │   ├── entity/
│   │   │   │   ├── query_execution.go
│   │   │   │   └── query_result.go
│   │   │   ├── valueobject/
│   │   │   │   ├── sql_query.go
│   │   │   │   ├── query_type.go
│   │   │   │   └── execution_status.go
│   │   │   ├── event/
│   │   │   │   ├── card_created.go
│   │   │   │   ├── query_executed.go
│   │   │   │   └── query_failed.go
│   │   │   ├── service/
│   │   │   │   ├── query_validation_service.go
│   │   │   │   ├── query_execution_service.go  # Multi-DB query engine
│   │   │   │   └── query_optimization_service.go
│   │   │   └── repository/
│   │   │       └── card_repository.go
│   │   │
│   │   ├── dashboard/                    # Dashboard Context
│   │   │   ├── aggregate/
│   │   │   │   └── dashboard.go
│   │   │   ├── entity/
│   │   │   │   ├── dashboard_card.go
│   │   │   │   └── dashboard_layout.go
│   │   │   ├── valueobject/
│   │   │   │   ├── card_position.go
│   │   │   │   ├── refresh_interval.go
│   │   │   │   └── visibility.go
│   │   │   ├── event/
│   │   │   │   ├── dashboard_created.go
│   │   │   │   └── card_added_to_dashboard.go
│   │   │   ├── policy/
│   │   │   │   └── dashboard_access_policy.go
│   │   │   └── repository/
│   │   │       └── dashboard_repository.go
│   │   │
│   │   ├── collection/                   # Collection Context
│   │   │   ├── aggregate/
│   │   │   │   └── collection.go
│   │   │   ├── entity/
│   │   │   │   └── collection_item.go
│   │   │   ├── valueobject/
│   │   │   │   ├── collection_path.go
│   │   │   │   └── collection_type.go
│   │   │   └── repository/
│   │   │       └── collection_repository.go
│   │   │
│   │   ├── permission/                   # Permission Context
│   │   │   ├── aggregate/
│   │   │   │   ├── user.go
│   │   │   │   └── permission_group.go
│   │   │   ├── entity/
│   │   │   │   └── permission.go
│   │   │   ├── valueobject/
│   │   │   │   ├── user_role.go
│   │   │   │   ├── permission_level.go
│   │   │   │   └── resource_type.go
│   │   │   ├── policy/
│   │   │   │   ├── resource_access_policy.go
│   │   │   │   └── permission_inheritance_policy.go
│   │   │   └── repository/
│   │   │       ├── user_repository.go
│   │   │       └── permission_repository.go
│   │   │
│   │   ├── importexport/                 # Import/Export Context
│   │   │   ├── aggregate/
│   │   │   │   ├── import_job.go
│   │   │   │   └── export_job.go
│   │   │   ├── valueobject/
│   │   │   │   ├── import_format.go
│   │   │   │   ├── export_format.go
│   │   │   │   └── job_status.go
│   │   │   ├── service/
│   │   │   │   ├── csv_parser_service.go
│   │   │   │   ├── excel_parser_service.go
│   │   │   │   └── data_validation_service.go
│   │   │   └── repository/
│   │   │       └── job_repository.go
│   │   │
│   │   └── shared/
│   │       ├── error/
│   │       │   └── domain_error.go
│   │       └── specification/
│   │           └── specification.go
│   │
│   ├── application/                      # 🟢 APPLICATION LAYER
│   │   ├── connection/
│   │   │   ├── command/
│   │   │   │   ├── create_connection.go
│   │   │   │   ├── test_connection.go
│   │   │   │   ├── sync_schema.go
│   │   │   │   └── delete_connection.go
│   │   │   ├── query/
│   │   │   │   ├── list_connections.go
│   │   │   │   ├── get_connection.go
│   │   │   │   └── get_schema.go
│   │   │   ├── saga/
│   │   │   │   └── create_connection_saga.go
│   │   │   └── dto/
│   │   │       └── connection_dto.go
│   │   │
│   │   ├── card/
│   │   │   ├── command/
│   │   │   │   ├── create_card.go
│   │   │   │   ├── update_card.go
│   │   │   │   ├── execute_card.go          # Execute query
│   │   │   │   └── delete_card.go
│   │   │   ├── query/
│   │   │   │   ├── list_cards.go
│   │   │   │   ├── get_card.go
│   │   │   │   ├── get_query_history.go
│   │   │   │   └── search_cards.go
│   │   │   └── dto/
│   │   │       └── card_dto.go
│   │   │
│   │   ├── dashboard/
│   │   │   ├── command/
│   │   │   │   ├── create_dashboard.go
│   │   │   │   ├── add_card_to_dashboard.go
│   │   │   │   └── update_dashboard_layout.go
│   │   │   ├── query/
│   │   │   │   ├── list_dashboards.go
│   │   │   │   └── get_dashboard_with_data.go  # Load dashboard + execute all cards
│   │   │   └── dto/
│   │   │       └── dashboard_dto.go
│   │   │
│   │   ├── importexport/
│   │   │   ├── command/
│   │   │   │   ├── import_csv.go
│   │   │   │   └── export_query_result.go
│   │   │   ├── saga/
│   │   │   │   ├── import_csv_saga.go
│   │   │   │   └── export_job_saga.go
│   │   │   └── dto/
│   │   │       └── import_export_dto.go
│   │   │
│   │   └── shared/
│   │       ├── event/
│   │       │   ├── event_bus.go
│   │       │   └── event_handler.go
│   │       └── port/
│   │           ├── query_engine_port.go      # Interface cho multi-DB query
│   │           ├── cache_port.go
│   │           ├── file_storage_port.go
│   │           └── websocket_port.go
│   │
│   ├── infrastructure/                   # 🟡 INFRASTRUCTURE LAYER
│   │   ├── persistence/
│   │   │   ├── postgres/
│   │   │   │   ├── sqlc/                     # SQLC generated (metadata DB)
│   │   │   │   │   ├── db.go
│   │   │   │   │   ├── models.go
│   │   │   │   │   └── queries.sql.go
│   │   │   │   ├── repository/
│   │   │   │   │   ├── connection_repository_impl.go
│   │   │   │   │   ├── card_repository_impl.go
│   │   │   │   │   ├── dashboard_repository_impl.go
│   │   │   │   │   └── user_repository_impl.go
│   │   │   │   └── mapper/
│   │   │   │       └── connection_mapper.go
│   │   │   └── redis/
│   │   │       ├── query_cache.go            # Cache query results
│   │   │       ├── schema_cache.go           # Cache DB schema metadata
│   │   │       └── session_store.go
│   │   │
│   │   ├── queryengine/                      # Multi-database query engine
│   │   │   ├── engine/
│   │   │   │   ├── query_engine.go           # Main engine interface
│   │   │   │   ├── postgres_engine.go        # PostgreSQL-specific
│   │   │   │   ├── mysql_engine.go           # MySQL-specific
│   │   │   │   ├── mongodb_engine.go         # MongoDB-specific
│   │   │   │   └── clickhouse_engine.go      # ClickHouse-specific
│   │   │   ├── parser/
│   │   │   │   └── sql_parser.go             # SQL validation & parsing
│   │   │   ├── executor/
│   │   │   │   ├── query_executor.go         # Concurrent query execution
│   │   │   │   └── connection_pool.go        # Per-DB connection pooling
│   │   │   └── optimizer/
│   │   │       └── query_optimizer.go
│   │   │
│   │   ├── fileprocessing/                   # Import/Export processing
│   │   │   ├── csv/
│   │   │   │   ├── csv_reader.go             # Stream CSV parsing
│   │   │   │   └── csv_writer.go
│   │   │   ├── excel/
│   │   │   │   ├── excel_reader.go
│   │   │   │   └── excel_writer.go
│   │   │   └── storage/
│   │   │       └── minio_client.go           # S3-compatible storage
│   │   │
│   │   ├── messaging/
│   │   │   ├── rabbitmq/
│   │   │   │   ├── publisher.go
│   │   │   │   └── consumer.go
│   │   │   └── websocket/
│   │   │       ├── hub.go                    # WebSocket hub
│   │   │       ├── client.go                 # WebSocket client
│   │   │       └── broadcaster.go            # Broadcast query updates
│   │   │
│   │   ├── worker/
│   │   │   ├── asynq_server.go               # Asynq worker server
│   │   │   ├── import_worker.go              # CSV/Excel import handler
│   │   │   ├── export_worker.go              # Export job handler
│   │   │   └── scheduled_query_worker.go     # Cron-based query execution
│   │   │
│   │   └── observability/
│   │       ├── tracing/
│   │       │   └── otel_tracer.go
│   │       ├── metrics/
│   │       │   ├── prometheus.go
│   │       │   └── query_metrics.go          # Query-specific metrics
│   │       └── logging/
│   │           └── structured_logger.go
│   │
│   ├── interfaces/                       # 🔴 PRESENTATION LAYER
│   │   └── http/
│   │       └── rest/
│   │           ├── handler/
│   │           │   ├── connection_handler.go
│   │           │   ├── card_handler.go
│   │           │   ├── dashboard_handler.go
│   │           │   ├── query_handler.go      # Execute ad-hoc queries
│   │           │   ├── import_export_handler.go
│   │           │   └── websocket_handler.go  # Real-time updates
│   │           ├── middleware/
│   │           │   ├── auth.go
│   │           │   ├── permission.go         # RBAC middleware
│   │           │   ├── logging.go
│   │           │   └── rate_limit.go
│   │           ├── dto/
│   │           │   ├── request.go
│   │           │   └── response.go
│   │           └── router.go
│   │
│   └── config/
│       ├── config.go
│       ├── database.go
│       └── asynq.go
│
├── pkg/                                  # Reusable packages
│   ├── ddd/                              # DDD building blocks
│   │   ├── aggregate.go
│   │   ├── entity.go
│   │   ├── valueobject.go
│   │   ├── domain_event.go
│   │   └── event_dispatcher.go
│   ├── cqrs/
│   │   ├── command.go
│   │   └── query.go
│   ├── saga/
│   │   ├── coordinator.go
│   │   └── step.go
│   └── errors/
│       └── app_error.go
│
├── migrations/
│   ├── 000001_init_users.up.sql
│   ├── 000002_init_connections.up.sql
│   ├── 000003_init_cards.up.sql
│   └── 000004_init_dashboards.up.sql
│
├── scripts/
│   ├── sqlc.yaml
│   └── generate.sh
│
├── api/
│   └── swagger.yaml
│
├── tests/
│   ├── integration/
│   ├── e2e/
│   └── testdata/
│
├── deployments/
│   ├── docker/
│   │   ├── Dockerfile
│   │   └── docker-compose.yaml
│   └── k8s/
│       ├── deployment.yaml
│       └── service.yaml
│
├── docs/
│   ├── architecture.md
│   ├── erd.md
│   └── sequence-diagrams.md
│
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

---

## 🎯 6 Bounded Contexts (DDD)

### 1. Connection Context
**Trách nhiệm**: Quản lý database connections, test connection, sync schema

**Aggregates**:
- `DatabaseConnection` - Connection configuration & lifecycle

**Entities**:
- `DatabaseSchema` - Schema metadata
- `TableMetadata` - Table information
- `ColumnMetadata` - Column details

**Value Objects**:
- `ConnectionConfig` (host, port, credentials)
- `ConnectionType` (PostgreSQL, MySQL, MongoDB, ClickHouse)
- `SyncStatus` (PENDING, SYNCING, SYNCED, FAILED)

**Domain Services**:
- `ConnectionTestService` - Test connection validity
- `SchemaExtractorService` - Extract schema from database

**Key Operations**:
```go
// Test connection before saving
connection.TestConnection() -> ConnectionTestResult

// Sync database schema metadata
connection.SyncSchema() -> DatabaseSchema

// Validate connection config
connectionConfig.Validate() -> error
```

---

### 2. Card (Query) Context
**Trách nhiệm**: Create queries, execute queries, cache results

**Aggregates**:
- `Card` - Saved query (question)

**Entities**:
- `QueryExecution` - Execution history
- `QueryResult` - Cached results

**Value Objects**:
- `SqlQuery` (raw SQL + parameters)
- `QueryType` (RAW_SQL, VISUAL_BUILDER, NATIVE)
- `ExecutionStatus` (PENDING, RUNNING, COMPLETED, FAILED)

**Domain Services**:
- `QueryValidationService` - Validate SQL syntax
- `QueryExecutionService` - Execute across multiple DB types
- `QueryOptimizationService` - Query performance optimization

**Key Operations**:
```go
// Create and validate card
card := NewCard(name, sqlQuery, connectionID)
card.Validate() -> error

// Execute query
execution := card.Execute(params) -> QueryExecution

// Cache result
result.Cache(ttl) -> error
```

---

### 3. Dashboard Context
**Trách nhiệm**: Create dashboards, manage layout, auto-refresh

**Aggregates**:
- `Dashboard` - Dashboard container

**Entities**:
- `DashboardCard` - Card placement
- `DashboardLayout` - Grid layout config

**Value Objects**:
- `CardPosition` (x, y, width, height)
- `RefreshInterval` (seconds)
- `DashboardVisibility` (PRIVATE, SHARED, PUBLIC)

**Policies**:
- `DashboardAccessPolicy` - Check user can access
- `CardPlacementPolicy` - Validate card position

**Key Operations**:
```go
// Add card to dashboard
dashboard.AddCard(cardID, position) -> error

// Auto-refresh dashboard
dashboard.Refresh() -> []QueryResult

// Share dashboard
dashboard.Share(userIDs, permissionLevel) -> error
```

---

### 4. Collection Context
**Trách nhiệm**: Organize cards/dashboards, hierarchical folders

**Aggregates**:
- `Collection` - Folder/tag container

**Entities**:
- `CollectionItem` - Card or Dashboard reference

**Value Objects**:
- `CollectionPath` - Hierarchical path
- `CollectionType` (FOLDER, TAG)

---

### 5. Permission Context
**Trách nhiệm**: RBAC, user management, permission inheritance

**Aggregates**:
- `User` - User account
- `PermissionGroup` - Group of users

**Entities**:
- `Permission` - Resource permission

**Value Objects**:
- `UserRole` (ADMIN, EDITOR, VIEWER)
- `PermissionLevel` (READ, WRITE, DELETE, EXECUTE)
- `ResourceType` (DATABASE, COLLECTION, DASHBOARD, CARD)

**Policies**:
- `ResourceAccessPolicy` - Check access
- `PermissionInheritancePolicy` - Calculate inherited permissions

---

### 6. Import/Export Context
**Trách nhiệm**: Data import (CSV, Excel), export (JSON, CSV, ZIP)

**Aggregates**:
- `ImportJob` - Async import job
- `ExportJob` - Async export job

**Value Objects**:
- `ImportFormat` (CSV, TXT, JSON, EXCEL)
- `ExportFormat` (JSON, CSV, ZIP, EXCEL)
- `JobStatus` (PENDING, PROCESSING, COMPLETED, FAILED)

**Domain Services**:
- `CsvParserService` - Parse CSV with streaming
- `ExcelParserService` - Parse Excel files
- `DataValidationService` - Validate imported data

---

## 🔥 Core Go Patterns

### 1. Multi-Database Query Engine (Strategy Pattern)

```go
// pkg/queryengine/engine.go
type QueryEngine interface {
    Connect(config ConnectionConfig) error
    Execute(query SqlQuery) (*QueryResult, error)
    GetSchema() (*DatabaseSchema, error)
    Close() error
}

// Concrete implementations
type PostgresEngine struct { ... }
type MySQLEngine struct { ... }
type MongoDBEngine struct { ... }
type ClickHouseEngine struct { ... }

// Factory
func NewQueryEngine(dbType ConnectionType, config ConnectionConfig) QueryEngine {
    switch dbType {
    case PostgreSQL:
        return NewPostgresEngine(config)
    case MySQL:
        return NewMySQLEngine(config)
    case MongoDB:
        return NewMongoDBEngine(config)
    case ClickHouse:
        return NewClickHouseEngine(config)
    }
}
```

### 2. Concurrent Query Execution

```go
// Execute multiple cards in parallel (dashboard refresh)
func (s *DashboardService) ExecuteDashboard(ctx context.Context, dashboardID string) (*DashboardData, error) {
    dashboard, _ := s.repo.FindByID(ctx, dashboardID)
    
    g, ctx := errgroup.WithContext(ctx)
    results := make(map[string]*QueryResult)
    mu := sync.Mutex{}
    
    for _, card := range dashboard.Cards {
        cardID := card.ID
        g.Go(func() error {
            result, err := s.queryEngine.Execute(ctx, card.Query)
            if err != nil {
                return err
            }
            
            mu.Lock()
            results[cardID] = result
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

### 3. Query Result Caching

```go
// Cache với TTL dựa vào query type
func (c *QueryCache) Get(key string) (*QueryResult, error) {
    val, err := c.redis.Get(ctx, key).Result()
    if err == redis.Nil {
        return nil, ErrCacheMiss
    }
    
    var result QueryResult
    json.Unmarshal([]byte(val), &result)
    return &result, nil
}

func (c *QueryCache) Set(key string, result *QueryResult, ttl time.Duration) error {
    data, _ := json.Marshal(result)
    return c.redis.Set(ctx, key, data, ttl).Err()
}

// Auto-detect TTL based on query
func (c *QueryCache) GetTTL(query SqlQuery) time.Duration {
    if query.IsAggregation() {
        return 5 * time.Minute
    }
    if query.IsAnalytical() {
        return 15 * time.Minute
    }
    return 1 * time.Minute // Real-time query
}
```

### 4. CSV Streaming Import (Memory-efficient)

```go
// Stream large CSV files without loading to memory
func (s *ImportService) ImportCSV(ctx context.Context, file io.Reader, dbID string) error {
    reader := csv.NewReader(file)
    
    // Read header
    header, err := reader.Read()
    if err != nil {
        return err
    }
    
    // Batch insert
    batch := make([]map[string]interface{}, 0, 1000)
    
    for {
        record, err := reader.Read()
        if err == io.EOF {
            break
        }
        
        row := make(map[string]interface{})
        for i, value := range record {
            row[header[i]] = value
        }
        
        batch = append(batch, row)
        
        // Insert batch when full
        if len(batch) >= 1000 {
            if err := s.insertBatch(ctx, dbID, batch); err != nil {
                return err
            }
            batch = batch[:0]
        }
    }
    
    // Insert remaining
    if len(batch) > 0 {
        return s.insertBatch(ctx, dbID, batch)
    }
    
    return nil
}
```

### 5. WebSocket Real-time Updates

```go
// Hub manages WebSocket connections
type Hub struct {
    clients    map[*Client]bool
    broadcast  chan []byte
    register   chan *Client
    unregister chan *Client
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
            for client := range h.clients {
                select {
                case client.send <- message:
                default:
                    close(client.send)
                    delete(h.clients, client)
                }
            }
        }
    }
}

// Broadcast query result update to connected clients
func (h *Hub) BroadcastQueryResult(cardID string, result *QueryResult) {
    data := map[string]interface{}{
        "type":   "QUERY_UPDATE",
        "cardId": cardID,
        "result": result,
    }
    
    jsonData, _ := json.Marshal(data)
    h.broadcast <- jsonData
}
```

### 6. Background Jobs với Asynq

```go
// Queue import job
func (h *ImportHandler) ImportCSV(c *gin.Context) {
    file, _ := c.FormFile("file")
    
    // Upload to MinIO
    fileURL := s.storage.Upload(file)
    
    // Queue async job
    task := asynq.NewTask(
        "import:csv",
        map[string]interface{}{
            "file_url": fileURL,
            "db_id":    dbID,
            "user_id":  userID,
        },
    )
    
    info, err := s.asynqClient.Enqueue(task)
    if err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(202, gin.H{
        "job_id": info.ID,
        "status": "queued",
    })
}

// Worker processes import job
func (w *ImportWorker) ProcessTask(ctx context.Context, task *asynq.Task) error {
    var payload map[string]interface{}
    json.Unmarshal(task.Payload(), &payload)
    
    fileURL := payload["file_url"].(string)
    dbID := payload["db_id"].(string)
    
    // Download file
    file := w.storage.Download(fileURL)
    
    // Process CSV
    return w.importService.ImportCSV(ctx, file, dbID)
}
```

---

## 🚀 Performance Optimizations

### Connection Pooling per Database

```go
type ConnectionPool struct {
    pools map[string]*pgxpool.Pool // Per database ID
    mu    sync.RWMutex
}

func (p *ConnectionPool) GetOrCreate(dbID string, config ConnectionConfig) (*pgxpool.Pool, error) {
    p.mu.RLock()
    if pool, ok := p.pools[dbID]; ok {
        p.mu.RUnlock()
        return pool, nil
    }
    p.mu.RUnlock()
    
    // Create new pool
    poolConfig, _ := pgxpool.ParseConfig(config.DSN())
    poolConfig.MaxConns = 20
    poolConfig.MinConns = 2
    poolConfig.MaxConnLifetime = 1 * time.Hour
    
    pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
    if err != nil {
        return nil, err
    }
    
    p.mu.Lock()
    p.pools[dbID] = pool
    p.mu.Unlock()
    
    return pool, nil
}
```

### Query Result Compression

```go
// Compress large query results before caching
func (c *QueryCache) SetCompressed(key string, result *QueryResult) error {
    data, _ := json.Marshal(result)
    
    // Compress with gzip
    var buf bytes.Buffer
    gzWriter := gzip.NewWriter(&buf)
    gzWriter.Write(data)
    gzWriter.Close()
    
    return c.redis.Set(ctx, key, buf.Bytes(), 10*time.Minute).Err()
}
```

---

## 📊 Key Metrics

```go
// Query execution metrics
var (
    queryDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "query_execution_duration_seconds",
            Help:    "Query execution duration",
            Buckets: prometheus.ExponentialBuckets(0.01, 2, 10),
        },
        []string{"database_type", "query_type"},
    )
    
    queryCacheHitRate = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "query_cache_hit_rate",
            Help: "Query cache hit rate",
        },
        []string{"database_id"},
    )
    
    connectionPoolActive = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "connection_pool_active",
            Help: "Active connections in pool",
        },
        []string{"database_id"},
    )
)
```

---

## 🔐 Security Features

### SQL Injection Prevention

```go
// Validate and sanitize SQL
func (v *QueryValidator) Validate(query SqlQuery) error {
    // Parse SQL
    stmt, err := sqlparser.Parse(query.Raw)
    if err != nil {
        return ErrInvalidSQL
    }
    
    // Block dangerous operations
    switch stmt.(type) {
    case *sqlparser.DDL:
        return ErrDDLNotAllowed
    case *sqlparser.Update, *sqlparser.Delete:
        if !query.HasWritePermission() {
            return ErrWriteNotAllowed
        }
    }
    
    return nil
}
```

### Row-Level Security (RLS)

```go
// Auto-inject WHERE clause based on user context
func (e *PostgresEngine) ApplyRLS(query SqlQuery, user User) SqlQuery {
    if !e.connection.RLSEnabled {
        return query
    }
    
    policy := e.connection.RLSPolicy
    whereClause := policy.GetWhereClause(user)
    
    // Example: SELECT * FROM orders
    // Becomes: SELECT * FROM orders WHERE tenant_id = 'user-tenant-id'
    modifiedSQL := sqlparser.InjectWhere(query.Raw, whereClause)
    
    return SqlQuery{Raw: modifiedSQL, Params: query.Params}
}
```

---

## 📚 Summary

| Aspect | Details |
|--------|---------|
| **Bounded Contexts** | 6 (Connection, Card, Dashboard, Collection, Permission, Import/Export) |
| **Aggregates** | 10+ (DatabaseConnection, Card, Dashboard, User, ImportJob, etc.) |
| **Query Engine** | Multi-DB support (PostgreSQL, MySQL, MongoDB, ClickHouse) |
| **Concurrency** | errgroup for parallel query execution, connection pooling |
| **Caching** | Redis for query results, schema metadata |
| **Real-time** | WebSocket for live dashboard updates |
| **Background Jobs** | Asynq for import/export, scheduled queries |
| **File Processing** | Streaming CSV/Excel import, memory-efficient |
| **Security** | JWT auth, RBAC, RLS, SQL injection prevention |
| **Observability** | OpenTelemetry tracing, Prometheus metrics |

---

**Next Steps**:
1. Detailed API specification (Swagger/OpenAPI)
2. ERD finalization
3. Sequence diagrams for key flows
4. Implementation roadmap

Let me know nếu bạn muốn tôi deep dive vào bất kỳ phần nào! 🚀
