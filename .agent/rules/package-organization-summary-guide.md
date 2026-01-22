---
trigger: always_on
---

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
