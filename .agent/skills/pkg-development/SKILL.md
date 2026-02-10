---
name: Package Development (Core/Libs)
description: Rules and patterns for developing shared libraries in pkg adhering to SOLID, KISS, DRY, and OOP.
---

## 🎯 Core Principles

All code in `pkg/` must strictly adhere to:

1. **SOLID**:
    * **SRP**: Each function/struct does ONE thing well.
    * **OCP**: Open for extension, closed for modification (use Interfaces).
    * **LSP**: Subtypes must be substitutable for base types.
    * **ISP**: Small, specific interfaces are better than large, general ones.
    * **DIP**: Depend on abstractions, not concretions.

2. **KISS (Keep It Simple, Stupid)**:
    * Avoid over-engineering.
    * Simple code is easier to debug and maintain.

3. **DRY (Don't Repeat Yourself)**:
    * Abstract common logic into reusable functions.
    * Single source of truth.

## 🏗️ OOP in Go

Use Go's idiomatic OOP features to ensure extensibility and clean code:

* **Encapsulation**:
  * Use private structs/fields (`lowerCase`) for internal implementation.
  * Expose only what is necessary via public methods (`PascalCase`).
  * Use `New...` constructors to enforce initialization logic.

* **Composition over Inheritance**:
  * Embed structs to reuse behavior.
  * Use Interfaces to define behavior contracts.

* **Polymorphism**:
  * Accept Interfaces as function arguments, return Interfaces (or concrete types if strict).

## 📝 Coding Standards

* **Naming**: Clear, descriptive names. `pkg` functions are used everywhere, so ambiguity is expensive.
* **Documentation**: EVERY exported function/type MUST have a comment explaining *what* it does and *why*.
* **Coverage**: Target >90% test coverage for `pkg`. Bugs here propagate everywhere.
* **Stability**: Avoid breaking changes. Deprecate old methods before removing them.

## Example

```go
// ✅ GOOD: Defined Interface (DIP)
type Logger interface {
    Info(msg string)
    Error(msg string, err error)
}

// ✅ GOOD: Encapsulation & Composition
type FileLogger struct {
    filterLevel string // Private
    writer      io.Writer
}

// Constructor
func NewFileLogger(w io.Writer) Logger {
    return &FileLogger{
        filterLevel: "INFO",
        writer:      w,
    }
}

// Implementation
func (l *FileLogger) Info(msg string) {
    // ... implementation
}
```
