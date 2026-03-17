# Hướng Dẫn Import/Export trong Go (Tương tự NestJS)

## Mục Lục

1. [Khái Niệm Cơ Bản](#khái-niệm-cơ-bản)
2. [Package và Module](#package-và-module)
3. [Import Syntax](#import-syntax)
4. [Export (Public/Private)](#export-publicprivate)
5. [Ví Dụ Thực Tế](#ví-dụ-thực-tế)
6. [So Sánh với NestJS](#so-sánh-với-nestjs)
7. [Best Practices](#best-practices)

## Khái Niệm Cơ Bản

### Go vs NestJS

| Khái niệm      | Go                       | NestJS                      |
| -------------- | ------------------------ | --------------------------- |
| Module         | Package                  | Module                      |
| Export         | Tên bắt đầu bằng chữ hoa | `export` keyword            |
| Import         | `import "path"`          | `import { ... } from '...'` |
| Default Export | Không có                 | `export default`            |

## Package và Module

### 1. Package Declaration

```go
// utils/function.util.go
package utils  // Tên package

// Các function được export (public)
func ToUpperCase(s string) string {
    return strings.ToUpper(s)
}

// Function private (không export)
func internalHelper() {
    // Chỉ sử dụng trong package này
}
```

### 2. Module Definition (go.mod)

```go
// go.mod
module go-domain-driven-design

go 1.26

require (
    // Dependencies
)
```

## Import Syntax

### 1. Import Cơ Bản

```go
// main.go
package main

import (
    "fmt"                           // Standard library
    "go-domain-driven-design/utils" // Local package
    "strings"                       // Standard library
)

func main() {
    result := utils.ToUpperCase("hello")
    fmt.Println(result)
}
```

### 2. Import với Alias

```go
import (
    "fmt"
    utils "go-domain-driven-design/utils"  // Alias
    str "strings"                          // Alias
)

func main() {
    result := utils.ToUpperCase("hello")
    fmt.Println(str.ToUpper("world"))
}
```

### 3. Import với Dot Notation

```go
import (
    "fmt"
    . "go-domain-driven-design/utils"  // Import tất cả vào namespace hiện tại
)

func main() {
    result := ToUpperCase("hello")  // Không cần prefix utils.
    fmt.Println(result)
}
```

### 4. Import với Blank Identifier

```go
import (
    "fmt"
    _ "go-domain-driven-design/utils"  // Chỉ chạy init() function
)

func main() {
    // Không thể sử dụng utils functions
    fmt.Println("Hello")
}
```

## Export (Public/Private)

### 1. Public (Exported)

```go
// Tên bắt đầu bằng chữ hoa = Public
func PublicFunction() string {
    return "This is public"
}

var PublicVariable = "Public"

type PublicStruct struct {
    PublicField string
    privateField string  // Private field
}

func (p *PublicStruct) PublicMethod() string {
    return p.PublicField
}
```

### 2. Private (Unexported)

```go
// Tên bắt đầu bằng chữ thường = Private
func privateFunction() string {
    return "This is private"
}

var privateVariable = "Private"

type privateStruct struct {
    field string
}

func (p *privateStruct) privateMethod() string {
    return p.field
}
```

## Ví Dụ Thực Tế

### 1. Tạo Service Layer (Tương tự NestJS Service)

```go
// services/user.service.go
package services

import (
    "fmt"
    "go-domain-driven-design/models"
)

type UserService struct {
    users []models.User
}

// Constructor function (tương tự NestJS constructor)
func NewUserService() *UserService {
    return &UserService{
        users: make([]models.User, 0),
    }
}

// Public methods (exported)
func (s *UserService) CreateUser(user models.User) error {
    s.users = append(s.users, user)
    fmt.Printf("User created: %s\n", user.Name)
    return nil
}

func (s *UserService) GetUsers() []models.User {
    return s.users
}

func (s *UserService) FindUserByID(id int) (*models.User, error) {
    for _, user := range s.users {
        if user.ID == id {
            return &user, nil
        }
    }
    return nil, fmt.Errorf("user not found")
}

// Private method (unexported)
func (s *UserService) validateUser(user models.User) bool {
    return user.Name != "" && user.Email != ""
}
```

### 2. Tạo Model (Tương tự NestJS Entity)

```go
// models/user.go
package models

import "time"

type User struct {
    ID        int       `json:"id"`
    Name      string    `json:"name"`
    Email     string    `json:"email"`
    CreatedAt time.Time `json:"created_at"`
}

// Constructor
func NewUser(id int, name, email string) User {
    return User{
        ID:        id,
        Name:      name,
        Email:     email,
        CreatedAt: time.Now(),
    }
}

// Public methods
func (u *User) UpdateName(name string) {
    u.Name = name
}

func (u *User) GetDisplayName() string {
    return u.Name
}
```

### 3. Tạo Controller (Tương tự NestJS Controller)

```go
// controllers/user.controller.go
package controllers

import (
    "fmt"
    "go-domain-driven-design/services"
    "go-domain-driven-design/models"
)

type UserController struct {
    userService *services.UserService
}

// Constructor (Dependency Injection tương tự NestJS)
func NewUserController(userService *services.UserService) *UserController {
    return &UserController{
        userService: userService,
    }
}

// Public methods (tương tự NestJS endpoints)
func (c *UserController) CreateUser(name, email string) error {
    user := models.NewUser(1, name, email)
    return c.userService.CreateUser(user)
}

func (c *UserController) GetAllUsers() []models.User {
    return c.userService.GetUsers()
}

func (c *UserController) GetUserByID(id int) (*models.User, error) {
    return c.userService.FindUserByID(id)
}
```

### 4. Main Application (Tương tự NestJS App)

```go
// cmd/api/main.go
package main

import (
    "fmt"
    "go-domain-driven-design/controllers"
    "go-domain-driven-design/services"
    "go-domain-driven-design/utils"
)

func main() {
    // Dependency Injection (tương tự NestJS DI)
    userService := services.NewUserService()
    userController := controllers.NewUserController(userService)

    // Demo các utility functions
    utils.PrintWithTimestamp("Starting application...")

    // Demo user operations
    err := userController.CreateUser("John Doe", "john@example.com")
    if err != nil {
        fmt.Printf("Error: %v\n", err)
        return
    }

    users := userController.GetAllUsers()
    fmt.Printf("Total users: %d\n", len(users))

    for _, user := range users {
        fmt.Printf("User: %s (%s)\n", user.Name, user.Email)
    }

    utils.PrintWithTimestamp("Application completed!")
}
```

## So Sánh với NestJS

### NestJS Style

```typescript
// user.service.ts
@Injectable()
export class UserService {
    private users: User[] = [];

    createUser(user: User): void {
        this.users.push(user);
    }

    getUsers(): User[] {
        return this.users;
    }
}

// user.controller.ts
@Controller('users')
export class UserController {
    constructor(private userService: UserService) {}

    @Post()
    createUser(@Body() userData: CreateUserDto): void {
        this.userService.createUser(userData);
    }

    @Get()
    getUsers(): User[] {
        return this.userService.getUsers();
    }
}
```

### Go Equivalent

```go
// services/user.service.go
type UserService struct {
    users []User
}

func NewUserService() *UserService {
    return &UserService{users: make([]User, 0)}
}

func (s *UserService) CreateUser(user User) {
    s.users = append(s.users, user)
}

func (s *UserService) GetUsers() []User {
    return s.users
}

// controllers/user.controller.go
type UserController struct {
    userService *UserService
}

func NewUserController(userService *UserService) *UserController {
    return &UserController{userService: userService}
}

func (c *UserController) CreateUser(userData CreateUserDto) {
    c.userService.CreateUser(userData)
}

func (c *UserController) GetUsers() []User {
    return c.userService.GetUsers()
}
```

## Best Practices

### 1. Package Organization

```

```

### 2. Naming Conventions

```go
// Package names: lowercase, short
package utils
package services
package models

// Exported functions: PascalCase
func CreateUser() {}
func GetUserByID() {}

// Private functions: camelCase
func validateUser() {}
func internalHelper() {}

// Constants: PascalCase hoặc UPPER_CASE
const MaxUsers = 100
const API_VERSION = "v1"
```

### 3. Interface Design

```go
// interfaces/user.interface.go
package interfaces

type UserService interface {
    CreateUser(user User) error
    GetUsers() []User
    FindUserByID(id int) (*User, error)
}

// Implementation
type userServiceImpl struct {
    users []User
}

func NewUserService() UserService {
    return &userServiceImpl{
        users: make([]User, 0),
    }
}
```

### 4. Error Handling

```go
// errors/user.errors.go
package errors

import "errors"

var (
    ErrUserNotFound = errors.New("user not found")
    ErrInvalidEmail = errors.New("invalid email")
    ErrUserExists   = errors.New("user already exists")
)

// Usage
func (s *UserService) FindUserByID(id int) (*User, error) {
    for _, user := range s.users {
        if user.ID == id {
            return &user, nil
        }
    }
    return nil, ErrUserNotFound
}
```

## Kết Luận

Go sử dụng package system thay vì module system như NestJS:

- **Export**: Tên bắt đầu bằng chữ hoa
- **Import**: Sử dụng `import` statement với package path
- **Dependency Injection**: Manual thay vì decorator
- **Organization**: Package-based thay vì module-based

Cấu trúc này giúp Go có performance tốt hơn và đơn giản hơn trong việc quản lý dependencies.
