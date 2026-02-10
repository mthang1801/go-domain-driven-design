---
name: Go Backend Development
description: Patterns for building Go HTTP Backends using Gin, Wire, and standard library
---

## Patterns
- Gin handler patterns
- Middleware (auth, logging, rate limit)
- Google Wire DI
- Error handling with domain errors
- Repository pattern
- Testing with mocks

## Example

```go
// ✅ GOOD: Thin handler, delegate to use case
func (h *Handler) CreateUser(c *gin.Context) {
    user, err := h.useCase.Execute(ctx, cmd)
    if err != nil {
        h.handleError(c, err)
        return
    }
    c.JSON(201, toResponse(user))
}
```