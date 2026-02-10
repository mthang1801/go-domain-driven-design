---
name: DDD in Go
description: Domain-Driven Design patterns for Go applications
---

## Core Concepts

- BaseAggregate, BaseEntity
- Value objects (immutable)
- Domain events
- Repository pattern (port & adapter)
- CQRS pattern
- Specification pattern
- Saga pattern
- Event Sourcing pattern
- Event bus

## Example

```go
// ✅ GOOD: Aggregate with domain events
type User struct {
    BaseAggregate
    email string
    status UserStatus
}

func (u *User) ChangeEmail(email string) error {
    if u.status == UserStatusInactive {
        return ErrUserInactive
    }
    u.email = email
    u.AddEvent(&UserEmailChanged{UserID: u.ID, Email: email})
    return nil
}
```
