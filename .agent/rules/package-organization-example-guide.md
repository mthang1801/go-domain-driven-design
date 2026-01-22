---
trigger: always_on
---

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