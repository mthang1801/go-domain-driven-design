# OOP trong Go — Hướng dẫn chuyên sâu cho dev từ TypeScript/Java

> **Mindset quan trọng:** Go không anti-OOP — Go triển khai OOP theo cách riêng.
> Go có đủ 3 trụ cột: **Encapsulation**, **Polymorphism**, **Composition**.
> Chỉ thiếu **Inheritance** — và đó là chủ ý thiết kế.

---

## Mục lục

1. [Bản đồ tổng quan: Java/TS → Go](#1-bản-đồ-tổng-quan)
2. [Encapsulation](#2-encapsulation)
3. [Interface & Polymorphism](#3-interface--polymorphism)
4. [Composition thay vì Inheritance](#4-composition-thay-vì-inheritance)
5. [Dependency Injection](#5-dependency-injection)
6. [Design Patterns trong Go](#6-design-patterns-trong-go)
7. [Error Handling OOP-style](#7-error-handling-oop-style)
8. [Thực chiến: Áp dụng lên code của bạn](#8-thực-chiến)

---

## 1. Bản đồ tổng quan

| Khái niệm OOP | Java / TypeScript | Go |
|---|---|---|
| Class | `class User {}` | `type User struct {}` |
| Constructor | `constructor()` / `new User()` | `func NewUser() *User` (convention) |
| Method | `user.getName()` | `func (u User) GetName() string` |
| Private field | `private name` | `name string` (chữ thường) |
| Public field | `public name` | `Name string` (chữ HOA) |
| Interface | `implements IRepo` | Implicit (không cần `implements`) |
| Abstract class | `abstract class Base` | Không có → dùng Interface + Composition |
| Inheritance | `extends Base` | Không có → dùng Embedding |
| Generics | `<T>` | `[T constraint]` |
| Decorator / Annotation | `@Injectable()` | Không có → dùng middleware pattern |
| Exception | `throw new Error()` | `return error` |
| `this` / `this` | `this.name` | `u.Name` (receiver) |

---

## 2. Encapsulation

### TypeScript (NestJS)

```typescript
// TypeScript — access modifiers rõ ràng
class User {
  private id: string;
  private email: string;
  public name: string;

  constructor(id: string, name: string, email: string) {
    this.id = id;
    this.name = name;
    this.email = this.validateEmail(email);
  }

  private validateEmail(email: string): string {
    if (!email.includes("@")) throw new Error("Invalid email");
    return email;
  }

  getId(): string {
    return this.id;
  }
}
```

### Go — Visibility bằng chữ hoa/thường

```go
package user

import "errors"

// User — chữ HOA = public (exported), chữ thường = private (unexported)
type User struct {
    ID    string  // Public — package khác truy cập được
    Name  string  // Public
    email string  // private — CHỈ package này truy cập
}

// NewUser — Constructor pattern chuẩn trong Go
func NewUser(id, name, email string) (*User, error) {
    if err := validateEmail(email); err != nil {
        return nil, err
    }
    return &User{
        ID:    id,
        Name:  name,
        email: email,
    }, nil
}

// validateEmail — private function (chữ thường)
func validateEmail(email string) error {
    if len(email) == 0 || !containsAt(email) {
        return errors.New("invalid email")
    }
    return nil
}

// GetEmail — Public getter cho private field
func (u *User) GetEmail() string {
    return u.email
}

// SetEmail — Public setter với validation
func (u *User) SetEmail(email string) error {
    if err := validateEmail(email); err != nil {
        return err
    }
    u.email = email
    return nil
}
```

> [!IMPORTANT]
> **Đơn vị encapsulation của Go là PACKAGE, không phải struct.**
> - Java/TS: `private` nghĩa là chỉ trong class đó.
> - Go: chữ thường = chỉ trong package đó (mọi file trong cùng package đều truy cập được).

---

## 3. Interface & Polymorphism

Đây là **điểm mạnh nhất** của Go so với Java/TS.

### TypeScript — Explicit interface

```typescript
// Phải khai báo "implements"
interface Notifier {
  send(to: string, message: string): Promise<void>;
}

class EmailNotifier implements Notifier {
  async send(to: string, message: string): Promise<void> {
    // gửi email
  }
}

class SlackNotifier implements Notifier {
  async send(to: string, message: string): Promise<void> {
    // gửi slack
  }
}

// Sử dụng
function notify(n: Notifier, to: string, msg: string) {
  return n.send(to, msg);
}
```

### Go — Implicit interface (Duck Typing)

```go
// Interface — chỉ định nghĩa CONTRACT
type Notifier interface {
    Send(to string, message string) error
}

// EmailNotifier — KHÔNG CẦN ghi "implements Notifier"
// Chỉ cần có method Send(string, string) error → tự động thoả mãn
type EmailNotifier struct {
    smtpHost string
    smtpPort int
}

func (e *EmailNotifier) Send(to string, message string) error {
    fmt.Printf("📧 Email to %s: %s\n", to, message)
    return nil
}

// SlackNotifier — cũng tự động implement Notifier
type SlackNotifier struct {
    webhookURL string
}

func (s *SlackNotifier) Send(to string, message string) error {
    fmt.Printf("💬 Slack to %s: %s\n", to, message)
    return nil
}

// Sử dụng — polymorphism hoạt động y hệt Java/TS
func NotifyUser(n Notifier, to string, msg string) error {
    return n.Send(to, msg)
}

func main() {
    email := &EmailNotifier{smtpHost: "smtp.gmail.com", smtpPort: 587}
    slack := &SlackNotifier{webhookURL: "https://hooks.slack.com/..."}

    NotifyUser(email, "alice@go.dev", "Hello")  // polymorphism
    NotifyUser(slack, "#general", "Hello")       // polymorphism
}
```

> [!TIP]
> **Lợi ích của implicit interface:**
> - Package A định nghĩa interface, Package B implement — **B không cần import A**.
> - Giảm coupling triệt để. Dễ mock test hơn Java/TS rất nhiều.
> - Standard library cực kỳ linh hoạt nhờ điều này (`io.Reader`, `io.Writer`, `fmt.Stringer`...).

### Compile-time check: đảm bảo implement đúng

```go
// Trick: kiểm tra tại compile time rằng EmailNotifier thực sự implement Notifier
var _ Notifier = (*EmailNotifier)(nil)  // ❌ Compile error nếu thiếu method
var _ Notifier = (*SlackNotifier)(nil)
```

---

## 4. Composition thay vì Inheritance

### Java — Inheritance chain

```java
// Java: dùng extends để tái sử dụng code
abstract class BaseEntity {
    private String id;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public String getId() { return id; }
    // ...
}

class User extends BaseEntity {
    private String name;
    private String email;
}

class Product extends BaseEntity {
    private String name;
    private double price;
}
```

### TypeScript (NestJS)

```typescript
abstract class BaseEntity {
  @PrimaryColumn()
  id: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

@Entity()
class User extends BaseEntity {
  @Column()
  name: string;

  @Column()
  email: string;
}
```

### Go — Struct Embedding (Composition)

```go
import "time"

// BaseEntity — KHÔNG phải class cha, mà là component có thể nhúng
type BaseEntity struct {
    ID        string    `json:"id"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

func (b BaseEntity) GetID() string {
    return b.ID
}

func (b *BaseEntity) Touch() {
    b.UpdatedAt = time.Now()
}

// User — nhúng BaseEntity vào (composition, KHÔNG phải inheritance)
type User struct {
    BaseEntity            // embedded — "promote" tất cả fields và methods
    Name  string `json:"name"`
    Email string `json:"email"`
}

// Product — cũng nhúng BaseEntity
type Product struct {
    BaseEntity
    Name  string  `json:"name"`
    Price float64 `json:"price"`
}

func main() {
    u := User{
        BaseEntity: BaseEntity{
            ID:        "u1",
            CreatedAt: time.Now(),
        },
        Name:  "Alice",
        Email: "alice@go.dev",
    }

    // Truy cập trực tiếp — fields và methods được "promote"
    fmt.Println(u.ID)       // → "u1"   (thực chất là u.BaseEntity.ID)
    fmt.Println(u.GetID())  // → "u1"   (thực chất là u.BaseEntity.GetID())
    u.Touch()               // cập nhật UpdatedAt
}
```

> [!WARNING]
> **Embedding ≠ Inheritance. Sự khác biệt quan trọng:**
> ```go
> // Go KHÔNG có "super" hay "override"
> // Nếu User định nghĩa GetID() riêng → nó SHADOW (che) BaseEntity.GetID()
> // KHÔNG phải override theo nghĩa polymorphism
> func (u User) GetID() string {
>     return "user-" + u.ID  // shadow, không phải override
> }
>
> var e BaseEntity = u  // ❌ COMPILE ERROR — User không phải BaseEntity
> ```
> - Java: `User IS-A BaseEntity` (is-a relationship)
> - Go: `User HAS-A BaseEntity` (has-a relationship)

### Multi-embedding (tương tự multiple inheritance nhưng an toàn hơn)

```go
type Timestamps struct {
    CreatedAt time.Time
    UpdatedAt time.Time
}

type SoftDelete struct {
    DeletedAt *time.Time
    IsActive  bool
}

type Auditable struct {
    CreatedBy string
    UpdatedBy string
}

// User nhúng NHIỀU component — mỗi cái có responsibility riêng
type User struct {
    ID string
    Timestamps              // created_at, updated_at
    SoftDelete              // deleted_at, is_active
    Auditable               // created_by, updated_by
    Name  string
    Email string
}
```

---

## 5. Dependency Injection

### TypeScript (NestJS) — Framework-driven DI

```typescript
// NestJS: DI tự động bằng decorator + IoC container
@Injectable()
class UserService {
  constructor(
    @Inject('USER_REPO')
    private readonly userRepo: UserRepository,
    private readonly notifier: NotifierService,
    private readonly logger: LoggerService,
  ) {}

  async createUser(dto: CreateUserDto): Promise<User> {
    const user = new User(dto);
    await this.userRepo.save(user);
    await this.notifier.send(user.email, 'Welcome!');
    this.logger.log(`User ${user.id} created`);
    return user;
  }
}

// Module wiring
@Module({
  providers: [
    UserService,
    { provide: 'USER_REPO', useClass: PostgresUserRepo },
    NotifierService,
    LoggerService,
  ],
})
export class UserModule {}
```

### Go — Manual DI (Constructor Injection)

```go
// Go: DI thủ công — KHÔNG cần framework, KHÔNG cần decorator

// ═══ Interfaces (contracts) ═══
type UserRepository interface {
    Save(ctx context.Context, user *User) error
    FindByID(ctx context.Context, id string) (*User, error)
}

type Notifier interface {
    Send(to string, message string) error
}

type Logger interface {
    Info(msg string, args ...any)
    Error(msg string, args ...any)
}

// ═══ Service — nhận dependencies qua constructor ═══
type UserService struct {
    repo     UserRepository   // interface, không phải concrete type
    notifier Notifier
    logger   Logger
}

// Constructor injection — tương đương @Inject() trong NestJS
func NewUserService(repo UserRepository, notifier Notifier, logger Logger) *UserService {
    return &UserService{
        repo:     repo,
        notifier: notifier,
        logger:   logger,
    }
}

func (s *UserService) CreateUser(ctx context.Context, name, email string) (*User, error) {
    user := &User{ID: generateID(), Name: name, Email: email}

    if err := s.repo.Save(ctx, user); err != nil {
        return nil, fmt.Errorf("save user: %w", err)
    }

    if err := s.notifier.Send(email, "Welcome!"); err != nil {
        s.logger.Error("failed to notify", "user_id", user.ID, "err", err)
        // không return error — notification failure không nên block user creation
    }

    s.logger.Info("user created", "user_id", user.ID)
    return user, nil
}

// ═══ Wiring — tương đương NestJS Module, nhưng code thuần ═══
func main() {
    // Production wiring
    db := connectDB()
    repo := postgres.NewUserRepo(db)
    notifier := email.NewSMTPNotifier("smtp.gmail.com", 587)
    logger := slog.Default()

    userSvc := NewUserService(repo, notifier, logger)
    // Xong. Không cần IoC container.
}
```

### So sánh trực tiếp

```
NestJS:                              Go:
@Injectable()                        (không cần)
@Inject('USER_REPO')                 field repo UserRepository
constructor(private repo: ...)       func NewUserService(repo ...) *UserService
@Module({ providers: [...] })        func main() { svc := NewUserService(...) }
```

> [!TIP]
> **Tại sao Go không cần DI framework?**
> - Implicit interface → mock dễ dàng mà không cần `@Injectable()`
> - Constructor injection = function thường → IDE hỗ trợ đầy đủ, type-safe
> - Wiring code nằm trong `main()` → dễ trace, dễ debug hơn magic container
> - Nếu project quá lớn, có thể dùng [Wire](https://github.com/google/wire) (code generation, không phải reflection)

---

## 6. Design Patterns trong Go

### 6.1 Strategy Pattern

```typescript
// ═══ TypeScript ═══
interface PricingStrategy {
  calculate(basePrice: number): number;
}

class RegularPricing implements PricingStrategy {
  calculate(basePrice: number): number { return basePrice; }
}

class PremiumPricing implements PricingStrategy {
  calculate(basePrice: number): number { return basePrice * 0.8; }
}

class Order {
  constructor(private strategy: PricingStrategy) {}
  getTotal(price: number): number {
    return this.strategy.calculate(price);
  }
}
```

```go
// ═══ Go ═══

// Strategy interface
type PricingStrategy interface {
    Calculate(basePrice float64) float64
}

// Concrete strategies
type RegularPricing struct{}
func (r RegularPricing) Calculate(basePrice float64) float64 { return basePrice }

type PremiumPricing struct{ Discount float64 }
func (p PremiumPricing) Calculate(basePrice float64) float64 {
    return basePrice * (1 - p.Discount)
}

// Context
type Order struct {
    strategy PricingStrategy
    Items    []OrderItem
}

func NewOrder(strategy PricingStrategy) *Order {
    return &Order{strategy: strategy}
}

func (o *Order) Total() float64 {
    var sum float64
    for _, item := range o.Items {
        sum += o.strategy.Calculate(item.Price) * float64(item.Qty)
    }
    return sum
}

// ═══ Shortcut Go: dùng function type thay vì full interface ═══
// Khi strategy chỉ có 1 method → dùng function type cho gọn
type PricingFunc func(basePrice float64) float64

func NewOrderWithFunc(fn PricingFunc) *Order {
    // ...
}

// Sử dụng — không cần tạo struct
order := NewOrderWithFunc(func(price float64) float64 {
    return price * 0.9 // giảm 10%
})
```

### 6.2 Decorator / Middleware Pattern

```typescript
// ═══ TypeScript (NestJS) ═══
// Dùng decorator
@UseGuards(AuthGuard)
@UseInterceptors(LoggingInterceptor)
@Controller('users')
class UserController {
  @Get(':id')
  findOne(@Param('id') id: string) { ... }
}
```

```go
// ═══ Go — Decorator bằng wrapping ═══

// Base interface
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

// Concrete implementation
type PostgresUserRepo struct { db *sql.DB }
func (r *PostgresUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    // query database
}

// Decorator 1: Logging
type LoggingRepo struct {
    next   UserRepository  // wrapped repo
    logger Logger
}

func NewLoggingRepo(next UserRepository, logger Logger) *LoggingRepo {
    return &LoggingRepo{next: next, logger: logger}
}

func (r *LoggingRepo) FindByID(ctx context.Context, id string) (*User, error) {
    r.logger.Info("FindByID called", "id", id)
    user, err := r.next.FindByID(ctx, id)  // delegate
    if err != nil {
        r.logger.Error("FindByID failed", "id", id, "err", err)
    }
    return user, err
}

// Decorator 2: Caching
type CachingRepo struct {
    next  UserRepository
    cache map[string]*User
    mu    sync.RWMutex
}

func NewCachingRepo(next UserRepository) *CachingRepo {
    return &CachingRepo{next: next, cache: make(map[string]*User)}
}

func (r *CachingRepo) FindByID(ctx context.Context, id string) (*User, error) {
    r.mu.RLock()
    if user, ok := r.cache[id]; ok {
        r.mu.RUnlock()
        return user, nil  // cache hit
    }
    r.mu.RUnlock()

    user, err := r.next.FindByID(ctx, id)  // cache miss → delegate
    if err == nil {
        r.mu.Lock()
        r.cache[id] = user
        r.mu.Unlock()
    }
    return user, err
}

// ═══ Wiring — xếp chồng decorators ═══
func main() {
    base := &PostgresUserRepo{db: db}
    withCache := NewCachingRepo(base)             // thêm cache
    withLog := NewLoggingRepo(withCache, logger)   // thêm logging

    // withLog → CachingRepo → PostgresUserRepo
    svc := NewUserService(withLog)
}
```

### 6.3 Factory Pattern

```typescript
// ═══ TypeScript ═══
interface Database { query(sql: string): Promise<any>; }

class DatabaseFactory {
  static create(type: 'postgres' | 'mysql'): Database {
    switch (type) {
      case 'postgres': return new PostgresDB();
      case 'mysql': return new MySQLDB();
    }
  }
}
```

```go
// ═══ Go — Factory bằng function map hoặc switch ═══

type Database interface {
    Query(ctx context.Context, sql string, args ...any) (*sql.Rows, error)
    Close() error
}

// Factory function
func NewDatabase(driver string, dsn string) (Database, error) {
    switch driver {
    case "postgres":
        return NewPostgresDB(dsn)
    case "mysql":
        return NewMySQLDB(dsn)
    case "sqlite":
        return NewSQLiteDB(dsn)
    default:
        return nil, fmt.Errorf("unsupported driver: %s", driver)
    }
}

// Hoặc dùng Registry pattern cho extensible factory
type DatabaseConstructor func(dsn string) (Database, error)

var registry = map[string]DatabaseConstructor{}

func Register(driver string, ctor DatabaseConstructor) {
    registry[driver] = ctor
}

func NewDatabaseFromRegistry(driver, dsn string) (Database, error) {
    ctor, ok := registry[driver]
    if !ok {
        return nil, fmt.Errorf("unknown driver: %s", driver)
    }
    return ctor(dsn)
}

// Mỗi driver tự đăng ký trong init()
func init() {
    Register("postgres", NewPostgresDB)
}
```

### 6.4 Observer Pattern

```typescript
// ═══ TypeScript ═══
import { EventEmitter2 } from '@nestjs/event-emitter';

@Injectable()
class UserService {
  constructor(private eventEmitter: EventEmitter2) {}

  async createUser(dto: CreateUserDto) {
    const user = await this.repo.save(dto);
    this.eventEmitter.emit('user.created', user);
  }
}

@OnEvent('user.created')
handleUserCreated(user: User) {
  // send welcome email
}
```

```go
// ═══ Go — Channel-based Observer ═══

// Event type
type Event struct {
    Type    string
    Payload any
}

// EventBus — simple pub/sub
type EventBus struct {
    mu          sync.RWMutex
    subscribers map[string][]chan Event
}

func NewEventBus() *EventBus {
    return &EventBus{subscribers: make(map[string][]chan Event)}
}

func (bus *EventBus) Subscribe(eventType string) <-chan Event {
    bus.mu.Lock()
    defer bus.mu.Unlock()

    ch := make(chan Event, 16) // buffered channel
    bus.subscribers[eventType] = append(bus.subscribers[eventType], ch)
    return ch
}

func (bus *EventBus) Publish(evt Event) {
    bus.mu.RLock()
    defer bus.mu.RUnlock()

    for _, ch := range bus.subscribers[evt.Type] {
        // non-blocking send
        select {
        case ch <- evt:
        default:
            // channel full, log warning
        }
    }
}

// Sử dụng
func main() {
    bus := NewEventBus()

    // Subscriber — chạy trong goroutine riêng
    userEvents := bus.Subscribe("user.created")
    go func() {
        for evt := range userEvents {
            user := evt.Payload.(*User)
            fmt.Printf("🎉 Welcome email sent to %s\n", user.Email)
        }
    }()

    // Publisher
    bus.Publish(Event{
        Type:    "user.created",
        Payload: &User{ID: "u1", Name: "Alice", Email: "alice@go.dev"},
    })
}
```

---

## 7. Error Handling OOP-style

### TypeScript/Java — Exception hierarchy

```typescript
// TypeScript
class AppError extends Error {
  constructor(public code: string, message: string, public statusCode: number) {
    super(message);
  }
}

class NotFoundError extends AppError {
  constructor(entity: string, id: string) {
    super('NOT_FOUND', `${entity} ${id} not found`, 404);
  }
}

// Sử dụng
throw new NotFoundError('User', 'u1');
```

### Go — Error types + sentinel errors

```go
// ═══ Sentinel errors (cho so sánh đơn giản) ═══
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrConflict     = errors.New("conflict")
)

// ═══ Custom error type (cho error giàu information) ═══
type AppError struct {
    Code    string
    Message string
    Status  int
    Err     error  // wrapped original error
}

func (e *AppError) Error() string {
    return fmt.Sprintf("[%s] %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error {
    return e.Err
}

// "Constructor" cho các loại error
func NewNotFoundError(entity, id string) *AppError {
    return &AppError{
        Code:    "NOT_FOUND",
        Message: fmt.Sprintf("%s %s not found", entity, id),
        Status:  404,
        Err:     ErrNotFound,
    }
}

func NewConflictError(entity, id string) *AppError {
    return &AppError{
        Code:    "CONFLICT",
        Message: fmt.Sprintf("%s %s already exists", entity, id),
        Status:  409,
        Err:     ErrConflict,
    }
}

// ═══ Sử dụng ═══
func (s *UserService) FindByID(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, NewNotFoundError("User", id)
    }
    return user, nil
}

// Caller — kiểm tra loại error
func handleRequest(id string) {
    user, err := svc.FindByID(ctx, id)
    if err != nil {
        var appErr *AppError
        if errors.As(err, &appErr) {
            // dùng appErr.Status, appErr.Code
            fmt.Printf("HTTP %d: %s\n", appErr.Status, appErr.Message)
            return
        }
        // unknown error
        fmt.Println("Internal error:", err)
    }
}
```

---

## 8. Thực chiến: Áp dụng lên code của bạn

Code hiện tại trong [main.go](file:///home/mvt/Repositories/Go/go-domain-driven-design/cmd/api/main.go) đã áp dụng tốt nhiều pattern OOP:

### ✅ Những gì bạn đang làm đúng

| Pattern | Code của bạn |
|---|---|
| Interface contract | `Repository[T Entity]` — generic interface chuẩn |
| Constructor injection | `NewCRUDService(repo)` — DI thủ công |
| Encapsulation | `mu sync.Mutex` ẩn trong struct |
| Generic Repository | `InMemoryRepo[T Entity]` — reusable cho mọi entity |

### 🔧 Có thể cải thiện — Theo hướng production DDD

```
Cấu trúc thư mục recommended:
go-domain-driven-design/
├── cmd/api/
│   └── main.go                    ← wiring, DI tại đây
├── internal/
│   ├── domain/                    ← Entity, Value Object, Interface
│   │   ├── user/
│   │   │   ├── entity.go          ← User struct + business methods
│   │   │   ├── repository.go      ← UserRepository interface
│   │   │   └── service.go         ← Domain service (nếu cần)
│   │   └── product/
│   │       ├── entity.go
│   │       └── repository.go
│   ├── application/               ← Use cases / Application services
│   │   └── user_service.go        ← Orchestrate domain + infra
│   └── infrastructure/            ← Concrete implementations
│       ├── persistence/
│       │   ├── memory/
│       │   │   └── user_repo.go   ← InMemoryRepo
│       │   └── postgres/
│       │       └── user_repo.go   ← PostgresRepo
│       └── notification/
│           └── email.go
└── pkg/                           ← Shared utilities
    └── generic/
        └── repository.go          ← Generic base repository
```

> [!NOTE]
> **Nguyên tắc vàng khi apply OOP trong Go:**
> 1. **Interface nhỏ** — 1-3 methods là lý tưởng (`io.Reader` chỉ có 1 method)
> 2. **Define interface tại consumer** — không phải tại provider
> 3. **Accept interfaces, return structs** — function nhận interface, trả concrete type
> 4. **Composition over inheritance** — luôn luôn, không có ngoại lệ
> 5. **Explicit over magic** — không decorator, không annotation, code rõ ràng
