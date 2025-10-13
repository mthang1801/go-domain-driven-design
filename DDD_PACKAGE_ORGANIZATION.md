# Package Organization với Domain-Driven Design (DDD) và Event Bus

## Mục Lục

1. [Tổng Quan Cấu Trúc](#tổng-quan-cấu-trúc)
2. [Chi Tiết Từng Package](#chi-tiết-từng-package)
3. [Event Bus Architecture](#event-bus-architecture)
4. [Ví Dụ Implementation](#ví-dụ-implementation)
5. [Best Practices](#best-practices)
6. [Dependency Flow](#dependency-flow)

## Tổng Quan Cấu Trúc

```
project/
├── cmd/                    # Main applications
│   ├── api/               # REST API server
│   ├── worker/            # Background worker
│   └── cli/               # Command line tools
├── internal/              # Private application code
│   ├── domain/            # Domain layer (Core business logic)
│   │   ├── entities/      # Domain entities
│   │   ├── valueobjects/  # Value objects
│   │   ├── events/        # Domain events
│   │   ├── repositories/  # Repository interfaces
│   │   └── services/      # Domain services
│   ├── application/       # Application layer (Use cases)
│   │   ├── commands/      # Command handlers
│   │   ├── queries/       # Query handlers
│   │   ├── events/        # Event handlers
│   │   └── services/      # Application services
│   ├── infrastructures/   # Infrastructure layer
│   │   ├── persistence/   # Database implementations
│   │   ├── messaging/     # Event bus implementation
│   │   ├── external/      # External API clients
│   │   └── config/        # Configuration
│   └── presentation/      # Presentation layer
│       ├── http/          # HTTP handlers
│       ├── grpc/          # gRPC handlers
│       └── graphql/       # GraphQL resolvers
├── pkg/                   # Library code (reusable)
│   ├── events/            # Event bus library
│   ├── logger/            # Logging utilities
│   ├── validator/         # Validation utilities
│   └── middleware/        # HTTP middleware
├── api/                   # API definitions
│   ├── openapi/           # OpenAPI specs
│   └── proto/             # Protocol buffer definitions
├── web/                   # Web application
│   ├── static/            # Static files
│   └── templates/         # HTML templates
├── configs/               # Configuration files
│   ├── dev.yaml
│   ├── prod.yaml
│   └── test.yaml
├── scripts/               # Build and deployment scripts
│   ├── build.sh
│   ├── deploy.sh
│   └── migrate.sh
├── test/                  # Additional external test apps
│   ├── integration/       # Integration tests
│   └── e2e/              # End-to-end tests
└── vendor/                # Application dependencies
```

## Chi Tiết Từng Package

### 1. `cmd/` - Main Applications

**Mục đích**: Entry points cho các ứng dụng khác nhau

```go
// cmd/api/main.go
package main

import (
    "context"
    "log"
    "go-domain-driven-design/internal/infrastructures/config"
    "go-domain-driven-design/internal/infrastructures/persistence"
    "go-domain-driven-design/internal/infrastructures/messaging"
    "go-domain-driven-design/internal/presentation/http"
    "go-domain-driven-design/pkg/logger"
)

func main() {
    // Load configuration
    cfg := config.Load()
    
    // Initialize logger
    logger := logger.New(cfg.LogLevel)
    
    // Initialize database
    db := persistence.NewDatabase(cfg.Database)
    defer db.Close()
    
    // Initialize event bus
    eventBus := messaging.NewEventBus(cfg.Messaging)
    
    // Initialize HTTP server
    server := http.NewServer(cfg.Server, db, eventBus, logger)
    
    // Start server
    if err := server.Start(context.Background()); err != nil {
        log.Fatal("Failed to start server:", err)
    }
}
```

### 2. `internal/domain/` - Domain Layer

**Mục đích**: Chứa business logic cốt lõi, không phụ thuộc vào framework

#### `entities/` - Domain Entities

```go
// internal/domain/entities/user.go
package entities

import (
    "time"
    "go-domain-driven-design/internal/domain/events"
    "go-domain-driven-design/internal/domain/valueobjects"
)

type User struct {
    id          valueobjects.UserID
    email       valueobjects.Email
    name        string
    createdAt   time.Time
    updatedAt   time.Time
    events      []events.DomainEvent
}

func NewUser(id valueobjects.UserID, email valueobjects.Email, name string) *User {
    user := &User{
        id:        id,
        email:     email,
        name:      name,
        createdAt: time.Now(),
        updatedAt: time.Now(),
        events:    make([]events.DomainEvent, 0),
    }
    
    // Publish domain event
    user.AddEvent(events.NewUserCreatedEvent(id, email, name))
    return user
}

func (u *User) UpdateName(name string) {
    u.name = name
    u.updatedAt = time.Now()
    u.AddEvent(events.NewUserNameUpdatedEvent(u.id, name))
}

func (u *User) GetID() valueobjects.UserID {
    return u.id
}

func (u *User) GetEmail() valueobjects.Email {
    return u.email
}

func (u *User) GetName() string {
    return u.name
}

func (u *User) AddEvent(event events.DomainEvent) {
    u.events = append(u.events, event)
}

func (u *User) GetEvents() []events.DomainEvent {
    return u.events
}

func (u *User) ClearEvents() {
    u.events = make([]events.DomainEvent, 0)
}
```

#### `valueobjects/` - Value Objects

```go
// internal/domain/valueobjects/user_id.go
package valueobjects

import (
    "errors"
    "github.com/google/uuid"
)

type UserID struct {
    value string
}

func NewUserID() UserID {
    return UserID{value: uuid.New().String()}
}

func NewUserIDFromString(id string) (UserID, error) {
    if id == "" {
        return UserID{}, errors.New("user ID cannot be empty")
    }
    
    if _, err := uuid.Parse(id); err != nil {
        return UserID{}, errors.New("invalid user ID format")
    }
    
    return UserID{value: id}, nil
}

func (u UserID) String() string {
    return u.value
}

func (u UserID) Equals(other UserID) bool {
    return u.value == other.value
}

// internal/domain/valueobjects/email.go
package valueobjects

import (
    "errors"
    "regexp"
)

type Email struct {
    value string
}

func NewEmail(email string) (Email, error) {
    if email == "" {
        return Email{}, errors.New("email cannot be empty")
    }
    
    emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
    if !emailRegex.MatchString(email) {
        return Email{}, errors.New("invalid email format")
    }
    
    return Email{value: email}, nil
}

func (e Email) String() string {
    return e.value
}

func (e Email) Equals(other Email) bool {
    return e.value == other.value
}
```

#### `events/` - Domain Events

```go
// internal/domain/events/domain_event.go
package events

import (
    "time"
    "github.com/google/uuid"
)

type DomainEvent interface {
    GetID() string
    GetType() string
    GetOccurredAt() time.Time
    GetAggregateID() string
}

type BaseDomainEvent struct {
    id          string
    eventType   string
    occurredAt  time.Time
    aggregateID string
}

func NewBaseDomainEvent(eventType, aggregateID string) BaseDomainEvent {
    return BaseDomainEvent{
        id:          uuid.New().String(),
        eventType:   eventType,
        occurredAt:  time.Now(),
        aggregateID: aggregateID,
    }
}

func (e BaseDomainEvent) GetID() string {
    return e.id
}

func (e BaseDomainEvent) GetType() string {
    return e.eventType
}

func (e BaseDomainEvent) GetOccurredAt() time.Time {
    return e.occurredAt
}

func (e BaseDomainEvent) GetAggregateID() string {
    return e.aggregateID
}

// internal/domain/events/user_events.go
package events

import "go-domain-driven-design/internal/domain/valueobjects"

type UserCreatedEvent struct {
    BaseDomainEvent
    UserID  valueobjects.UserID
    Email   valueobjects.Email
    Name    string
}

func NewUserCreatedEvent(userID valueobjects.UserID, email valueobjects.Email, name string) UserCreatedEvent {
    return UserCreatedEvent{
        BaseDomainEvent: NewBaseDomainEvent("user.created", userID.String()),
        UserID:          userID,
        Email:           email,
        Name:            name,
    }
}

type UserNameUpdatedEvent struct {
    BaseDomainEvent
    UserID valueobjects.UserID
    Name   string
}

func NewUserNameUpdatedEvent(userID valueobjects.UserID, name string) UserNameUpdatedEvent {
    return UserNameUpdatedEvent{
        BaseDomainEvent: NewBaseDomainEvent("user.name_updated", userID.String()),
        UserID:          userID,
        Name:            name,
    }
}
```

#### `repositories/` - Repository Interfaces

```go
// internal/domain/repositories/user_repository.go
package repositories

import (
    "context"
    "go-domain-driven-design/internal/domain/entities"
    "go-domain-driven-design/internal/domain/valueobjects"
)

type UserRepository interface {
    Save(ctx context.Context, user *entities.User) error
    FindByID(ctx context.Context, id valueobjects.UserID) (*entities.User, error)
    FindByEmail(ctx context.Context, email valueobjects.Email) (*entities.User, error)
    Delete(ctx context.Context, id valueobjects.UserID) error
}
```

### 3. `internal/application/` - Application Layer

**Mục đích**: Orchestrate domain objects để thực hiện use cases

#### `commands/` - Command Handlers

```go
// internal/application/commands/create_user_command.go
package commands

import (
    "context"
    "go-domain-driven-design/internal/domain/entities"
    "go-domain-driven-design/internal/domain/repositories"
    "go-domain-driven-design/internal/domain/valueobjects"
    "go-domain-driven-design/pkg/events"
)

type CreateUserCommand struct {
    Email string
    Name  string
}

type CreateUserHandler struct {
    userRepo  repositories.UserRepository
    eventBus  events.EventBus
}

func NewCreateUserHandler(userRepo repositories.UserRepository, eventBus events.EventBus) *CreateUserHandler {
    return &CreateUserHandler{
        userRepo: userRepo,
        eventBus: eventBus,
    }
}

func (h *CreateUserHandler) Handle(ctx context.Context, cmd CreateUserCommand) error {
    // Create value objects
    email, err := valueobjects.NewEmail(cmd.Email)
    if err != nil {
        return err
    }
    
    // Check if user already exists
    existingUser, err := h.userRepo.FindByEmail(ctx, email)
    if err == nil && existingUser != nil {
        return errors.New("user with this email already exists")
    }
    
    // Create new user
    userID := valueobjects.NewUserID()
    user := entities.NewUser(userID, email, cmd.Name)
    
    // Save user
    if err := h.userRepo.Save(ctx, user); err != nil {
        return err
    }
    
    // Publish domain events
    for _, event := range user.GetEvents() {
        h.eventBus.Publish(ctx, event)
    }
    user.ClearEvents()
    
    return nil
}
```

#### `queries/` - Query Handlers

```go
// internal/application/queries/get_user_query.go
package queries

import (
    "context"
    "go-domain-driven-design/internal/domain/repositories"
    "go-domain-driven-design/internal/domain/valueobjects"
)

type GetUserQuery struct {
    ID string
}

type UserDTO struct {
    ID        string `json:"id"`
    Email     string `json:"email"`
    Name      string `json:"name"`
    CreatedAt string `json:"created_at"`
}

type GetUserHandler struct {
    userRepo repositories.UserRepository
}

func NewGetUserHandler(userRepo repositories.UserRepository) *GetUserHandler {
    return &GetUserHandler{
        userRepo: userRepo,
    }
}

func (h *GetUserHandler) Handle(ctx context.Context, query GetUserQuery) (*UserDTO, error) {
    userID, err := valueobjects.NewUserIDFromString(query.ID)
    if err != nil {
        return nil, err
    }
    
    user, err := h.userRepo.FindByID(ctx, userID)
    if err != nil {
        return nil, err
    }
    
    return &UserDTO{
        ID:        user.GetID().String(),
        Email:     user.GetEmail().String(),
        Name:      user.GetName(),
        CreatedAt: user.GetCreatedAt().Format(time.RFC3339),
    }, nil
}
```

#### `events/` - Event Handlers

```go
// internal/application/events/user_created_handler.go
package events

import (
    "context"
    "log"
    "go-domain-driven-design/internal/domain/events"
    "go-domain-driven-design/pkg/events"
)

type UserCreatedHandler struct {
    // Dependencies for side effects
    emailService EmailService
    logger       Logger
}

func NewUserCreatedHandler(emailService EmailService, logger Logger) *UserCreatedHandler {
    return &UserCreatedHandler{
        emailService: emailService,
        logger:       logger,
    }
}

func (h *UserCreatedHandler) Handle(ctx context.Context, event events.DomainEvent) error {
    userCreatedEvent, ok := event.(events.UserCreatedEvent)
    if !ok {
        return errors.New("invalid event type")
    }
    
    // Send welcome email
    if err := h.emailService.SendWelcomeEmail(ctx, userCreatedEvent.Email.String(), userCreatedEvent.Name); err != nil {
        h.logger.Error("Failed to send welcome email", err)
        return err
    }
    
    h.logger.Info("Welcome email sent to user", "user_id", userCreatedEvent.UserID.String())
    return nil
}
```

### 4. `internal/infrastructures/` - Infrastructure Layer

**Mục đích**: Implement các interface từ domain và application layer

#### `persistence/` - Database Implementation

```go
// internal/infrastructures/persistence/user_repository.go
package persistence

import (
    "context"
    "database/sql"
    "go-domain-driven-design/internal/domain/entities"
    "go-domain-driven-design/internal/domain/repositories"
    "go-domain-driven-design/internal/domain/valueobjects"
)

type userRepository struct {
    db *sql.DB
}

func NewUserRepository(db *sql.DB) repositories.UserRepository {
    return &userRepository{db: db}
}

func (r *userRepository) Save(ctx context.Context, user *entities.User) error {
    query := `
        INSERT INTO users (id, email, name, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5)
        ON CONFLICT (id) DO UPDATE SET
            email = $2,
            name = $3,
            updated_at = $5
    `
    
    _, err := r.db.ExecContext(ctx, query,
        user.GetID().String(),
        user.GetEmail().String(),
        user.GetName(),
        user.GetCreatedAt(),
        user.GetUpdatedAt(),
    )
    
    return err
}

func (r *userRepository) FindByID(ctx context.Context, id valueobjects.UserID) (*entities.User, error) {
    query := `SELECT id, email, name, created_at, updated_at FROM users WHERE id = $1`
    
    var user entities.User
    var idStr, emailStr string
    
    err := r.db.QueryRowContext(ctx, query, id.String()).Scan(
        &idStr, &emailStr, &user.Name, &user.CreatedAt, &user.UpdatedAt,
    )
    
    if err != nil {
        if err == sql.ErrNoRows {
            return nil, nil
        }
        return nil, err
    }
    
    userID, err := valueobjects.NewUserIDFromString(idStr)
    if err != nil {
        return nil, err
    }
    
    email, err := valueobjects.NewEmail(emailStr)
    if err != nil {
        return nil, err
    }
    
    user.ID = userID
    user.Email = email
    
    return &user, nil
}

func (r *userRepository) FindByEmail(ctx context.Context, email valueobjects.Email) (*entities.User, error) {
    query := `SELECT id, email, name, created_at, updated_at FROM users WHERE email = $1`
    
    var user entities.User
    var idStr, emailStr string
    
    err := r.db.QueryRowContext(ctx, query, email.String()).Scan(
        &idStr, &emailStr, &user.Name, &user.CreatedAt, &user.UpdatedAt,
    )
    
    if err != nil {
        if err == sql.ErrNoRows {
            return nil, nil
        }
        return nil, err
    }
    
    userID, err := valueobjects.NewUserIDFromString(idStr)
    if err != nil {
        return nil, err
    }
    
    userEmail, err := valueobjects.NewEmail(emailStr)
    if err != nil {
        return nil, err
    }
    
    user.ID = userID
    user.Email = userEmail
    
    return &user, nil
}

func (r *userRepository) Delete(ctx context.Context, id valueobjects.UserID) error {
    query := `DELETE FROM users WHERE id = $1`
    _, err := r.db.ExecContext(ctx, query, id.String())
    return err
}
```

#### `messaging/` - Event Bus Implementation

```go
// internal/infrastructures/messaging/event_bus.go
package messaging

import (
    "context"
    "sync"
    "go-domain-driven-design/pkg/events"
)

type eventBus struct {
    handlers map[string][]events.EventHandler
    mutex    sync.RWMutex
}

func NewEventBus() events.EventBus {
    return &eventBus{
        handlers: make(map[string][]events.EventHandler),
    }
}

func (b *eventBus) Subscribe(eventType string, handler events.EventHandler) {
    b.mutex.Lock()
    defer b.mutex.Unlock()
    
    b.handlers[eventType] = append(b.handlers[eventType], handler)
}

func (b *eventBus) Publish(ctx context.Context, event events.DomainEvent) error {
    b.mutex.RLock()
    handlers := b.handlers[event.GetType()]
    b.mutex.RUnlock()
    
    for _, handler := range handlers {
        if err := handler.Handle(ctx, event); err != nil {
            // Log error but continue processing other handlers
            // In production, you might want to use a dead letter queue
            continue
        }
    }
    
    return nil
}
```

### 5. `internal/presentation/` - Presentation Layer

**Mục đích**: Handle HTTP requests và responses

```go
// internal/presentation/http/user_handler.go
package http

import (
    "encoding/json"
    "net/http"
    "go-domain-driven-design/internal/application/commands"
    "go-domain-driven-design/internal/application/queries"
    "go-domain-driven-design/pkg/logger"
)

type UserHandler struct {
    createUserHandler *commands.CreateUserHandler
    getUserHandler    *queries.GetUserHandler
    logger            logger.Logger
}

func NewUserHandler(
    createUserHandler *commands.CreateUserHandler,
    getUserHandler *queries.GetUserHandler,
    logger logger.Logger,
) *UserHandler {
    return &UserHandler{
        createUserHandler: createUserHandler,
        getUserHandler:    getUserHandler,
        logger:            logger,
    }
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req struct {
        Email string `json:"email"`
        Name  string `json:"name"`
    }
    
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "Invalid request body", http.StatusBadRequest)
        return
    }
    
    cmd := commands.CreateUserCommand{
        Email: req.Email,
        Name:  req.Name,
    }
    
    if err := h.createUserHandler.Handle(r.Context(), cmd); err != nil {
        h.logger.Error("Failed to create user", err)
        http.Error(w, "Failed to create user", http.StatusInternalServerError)
        return
    }
    
    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(map[string]string{"status": "created"})
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    userID := r.URL.Query().Get("id")
    if userID == "" {
        http.Error(w, "User ID is required", http.StatusBadRequest)
        return
    }
    
    query := queries.GetUserQuery{ID: userID}
    
    user, err := h.getUserHandler.Handle(r.Context(), query)
    if err != nil {
        h.logger.Error("Failed to get user", err)
        http.Error(w, "User not found", http.StatusNotFound)
        return
    }
    
    json.NewEncoder(w).Encode(user)
}
```

### 6. `pkg/` - Reusable Library Code

#### `events/` - Event Bus Library

```go
// pkg/events/event_bus.go
package events

import (
    "context"
    "go-domain-driven-design/internal/domain/events"
)

type EventHandler interface {
    Handle(ctx context.Context, event events.DomainEvent) error
}

type EventBus interface {
    Subscribe(eventType string, handler EventHandler)
    Publish(ctx context.Context, event events.DomainEvent) error
}
```

## Event Bus Architecture

### Event Flow

```
1. Domain Entity → Domain Event
2. Application Command Handler → Publish Event
3. Event Bus → Route to Handlers
4. Event Handlers → Side Effects
```

### Event Types

1. **Domain Events**: Phát sinh từ domain entities
2. **Integration Events**: Giao tiếp giữa các bounded contexts
3. **Application Events**: Orchestrate application workflows

### Event Bus Benefits

- **Decoupling**: Loose coupling giữa các components
- **Scalability**: Dễ dàng thêm event handlers mới
- **Testability**: Dễ test từng component riêng biệt
- **Auditability**: Track tất cả events trong system

## Best Practices

### 1. Dependency Direction

```
Presentation → Application → Domain
Infrastructure → Domain (implementing interfaces)
```

### 2. Event Naming Convention

```go
// Domain events: past tense
"user.created"
"user.name_updated"
"order.shipped"

// Integration events: present tense
"user.creation_requested"
"payment.processed"
```

### 3. Error Handling in Events

```go
func (h *EventHandler) Handle(ctx context.Context, event events.DomainEvent) error {
    // Always return error for critical failures
    // Log and continue for non-critical failures
    if err := h.processEvent(event); err != nil {
        h.logger.Error("Failed to process event", err)
        // Decide whether to return error or continue
        return err
    }
    return nil
}
```

### 4. Event Versioning

```go
type UserCreatedEventV1 struct {
    BaseDomainEvent
    UserID string
    Email  string
    Name   string
}

type UserCreatedEventV2 struct {
    BaseDomainEvent
    UserID    string
    Email     string
    Name      string
    CreatedBy string // New field
}
```

## Dependency Flow

```
┌─────────────────┐
│   Presentation  │
│   (HTTP/gRPC)   │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│   Application   │
│  (Use Cases)    │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│     Domain      │
│ (Business Logic)│
└─────────────────┘
          ▲
          │
┌─────────┴───────┐
│ Infrastructure  │
│ (DB/External)   │
└─────────────────┘
```

## Kết Luận

Cấu trúc package này cung cấp:

- **Clean Architecture**: Tách biệt rõ ràng các layers
- **Domain-Driven Design**: Business logic ở trung tâm
- **Event-Driven Architecture**: Loose coupling thông qua events
- **Testability**: Dễ test từng layer riêng biệt
- **Scalability**: Dễ mở rộng và maintain

Event bus giúp tạo ra một hệ thống linh hoạt, có thể mở rộng và dễ bảo trì, phù hợp cho các ứng dụng enterprise phức tạp.


