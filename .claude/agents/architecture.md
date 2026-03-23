---
name: architecture
---

# Project Structure (with libs)

```
domain-driven-design/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── domain/
│   │   ├── order/
│   │   │   ├── entities/
│   │   │   │   ├── order.entity.ts
│   │   │   │   ├── order-event-sourced.entity.ts
│   │   │   │   └── order-item.entity.ts
│   │   │   ├── value-objects/
│   │   │   │   ├── money.vo.ts
│   │   │   │   ├── order-number.vo.ts
│   │   │   │   └── address.vo.ts
│   │   │   ├── events/
│   │   │   │   ├── order-created.event.ts
│   │   │   │   ├── order-paid.event.ts
│   │   │   │   └── order-shipped.event.ts
│   │   │   ├── services/
│   │   │   │   ├── pricing-domain.service.ts
│   │   │   │   └── inventory-domain.service.ts
│   │   │   ├── factories/
│   │   │   │   └── order.factory.ts
│   │   │   └── policies/
│   │   │       ├── cancellation-policy.interface.ts
│   │   │       ├── standard-cancellation.policy.ts
│   │   │       └── premium-cancellation.policy.ts
│   │   └── payment/
│   │       └── entities/
│   │           ├── payment-method.base.ts
│   │           ├── credit-card-payment.ts
│   │           ├── paypal-payment.ts
│   │           └── wallet-payment.ts
│   ├── application/
│   │   ├── order/
│   │   │   ├── use-cases/
│   │   │   │   ├── create-order.use-case.ts
│   │   │   │   ├── pay-order.use-case.ts
│   │   │   │   └── cancel-order.use-case.ts
│   │   │   ├── sagas/
│   │   │   ├── services/
│   │   │   ├── policies/
│   │   │   └── events/
│   │   └── agreement/
│   │       ├── use-cases/
│   │       │   ├── create-agreement.use-case.ts
│   │       │   └── approve-agreement.use-case.ts
│   │       ├── sagas/
│   │       ├── services/
│   │       ├── policies/
│   │       └── events/
│   ├── infrastructure/
│   │   ├── persistence/
│   │   │   ├── typeorm/
│   │   │   │   └── typeorm.module.ts
│   │   │   ├── topup/
│   │   │   │   ├── topup.repository.ts
│   │   │   │   └── topup.orm.entity.ts
│   │   │   ├── outbox/
│   │   │   │   ├── outbox.repository.ts
│   │   │   │   └── outbox.orm.entity.ts
│   │   │   └── inbox/
│   │   │       ├── inbox.repository.ts
│   │   │       └── inbox.orm.entity.ts
│   │   ├── event-store/
│   │   │   ├── entities/
│   │   │   │   └── event-store.orm-entity.ts
│   │   │   └── repositories/
│   │   │       └── event-store.repository.ts
│   │   ├── redis/
│   │   │   └── redis.module.ts
│   │   ├── http/
│   │   │   ├── wallet.http-client.ts
│   │   │   ├── connector.http-client.ts
│   │   │   ├── rule.http-client.ts
│   │   │   └── sso.http-client.ts
│   │   ├── resilience/
│   │   │   ├── circuit-breaker.ts
│   │   │   ├── retry.strategy.ts
│   │   │   ├── timeout.interceptor.ts
│   │   │   └── bulkhead.limiter.ts
│   │   └── rabbitmq/
│   │       ├── rabbitmq.module.ts
│   │       └── rabbitmq-config/
│   │           ├── order.config.ts
│   │           ├── user.config.ts
│   │           └── product.config.ts
│   │   └── modules/
│   │       ├── dashboard/
│   │       ├── ai-agent/
│   │       ├── database/
│   │       ├── settings/
│   │       ├── sql-editor/
│   │       ├── storage/
│   │       └── table-editor/
│   ├── presentation/
│   │   └── portal/
│   │       └── order/
│   │           ├── controllers/
│   │           │   ├── order-command.controller.ts
│   │           │   └── order-query.controller.ts
│   │           ├── subscribers/
│   │           │   ├── order-created.subscriber.ts
│   │           │   └── order-query.subscriber.ts
│   │           └── dtos/
│   │               ├── create-order.dto.ts
│   │               ├── pay-order.dto.ts
│   │               └── search-orders.dto.ts
│   │       └── product/
│   │           ├── controllers/
│   │           │   ├── product-command.controller.ts
│   │           │   └── product-query.controller.ts
│   │           ├── subscribers/
│   │           │   ├── product-created.subscriber.ts
│   │           │   └── product-query.subscriber.ts
│   │           └── dtos/
│   │               ├── create-product.dto.ts
│   │               ├── pay-product.dto.ts
│   │               └── search-products.dto.ts
│   └── test/
│       ├── e2e/
│       ├── unit/
│       └── mocks/
├── libs/
│   ├── src/
│   │   ├── common/
│   │   │   ├── decorators/
│   │   │   │   ├── api-expose.decorator.ts
│   │   │   │   ├── auto-api-property.decorator.ts
│   │   │   │   ├── auto-expose.decorator.ts
│   │   │   │   ├── log.decorator.ts
│   │   │   │   ├── mark-controller.decorator.ts
│   │   │   │   ├── merge-params-body.decorator.ts
│   │   │   │   ├── method-module-init.decorator.ts
│   │   │   │   ├── plain-to-instance-query.decorator.ts
│   │   │   │   ├── retry.decorator.ts
│   │   │   │   ├── subscribe-pattern.decorator.ts
│   │   │   │   ├── subscribe-pattern.temp.decorator.ts
│   │   │   │   ├── track-performance.decorator.ts
│   │   │   │   ├── validator.decorator.ts
│   │   │   │   └── index.ts
│   │   │   ├── exceptions/
│   │   │   │   ├── codes/
│   │   │   │   ├── handlers/
│   │   │   │   ├── interfaces/
│   │   │   │   ├── exception.base.ts
│   │   │   │   ├── exception.constant.ts
│   │   │   │   ├── exception.filter.ts
│   │   │   │   ├── exception.interceptor.ts
│   │   │   │   └── index.ts
│   │   │   ├── guards/
│   │   │   │   └── index.ts
│   │   │   ├── interceptors/
│   │   │   │   ├── merge-params-body.interceptor.ts
│   │   │   │   ├── mongoose-class-serialize.interceptor.ts
│   │   │   │   ├── upload-file.interceptor.ts
│   │   │   │   ├── upload-files.interceptor.ts
│   │   │   │   └── index.ts
│   │   │   ├── middleware/
│   │   │   │   ├── merge-params-body.middleware.ts
│   │   │   │   ├── request-context.middleware.ts
│   │   │   │   └── index.ts
│   │   │   ├── modules/
│   │   │   │   ├── assets-base/
│   │   │   │   ├── auth/
│   │   │   │   ├── dynamic-api-editor/
│   │   │   │   ├── exceljs/
│   │   │   │   ├── formula-engine/
│   │   │   │   ├── import-engine/
│   │   │   │   ├── json-rule-engine/
│   │   │   │   ├── pdf/
│   │   │   │   ├── redis-manager/
│   │   │   │   ├── report/
│   │   │   │   ├── stream-pipeline/
│   │   │   │   ├── transform-editor/
│   │   │   │   └── yaml-to-json/
│   │   │   ├── pipes/
│   │   │   │   ├── app-validation.pipe.ts
│   │   │   │   └── index.ts
│   │   │   ├── transform/
│   │   │   └── validators/
│   │   │       ├── between-length.validator.ts
│   │   │       └── index.ts
│   │   ├── core/
│   │   │   ├── async-local-storage/
│   │   │   ├── base/
│   │   │   ├── bot/
│   │   │   ├── bullmq/
│   │   │   ├── database/
│   │   │   ├── events/
│   │   │   ├── health/
│   │   │   ├── http/
│   │   │   ├── i18n/
│   │   │   ├── kafka/
│   │   │   ├── logger/
│   │   │   ├── rabbitmq/
│   │   │   ├── redis/
│   │   │   ├── router/
│   │   │   ├── sse/
│   │   │   ├── swagger/
│   │   │   └── trace-monitoring/
│   │   ├── ddd/
│   │   │   ├── application/
│   │   │   ├── domain/
│   │   │   ├── infrastructure/
│   │   │   ├── interfaces/
│   │   │   ├── utils/
│   │   │   ├── ddd.module.ts
│   │   │   └── index.ts
│   │   ├── shared/
│   │   │   ├── constants/
│   │   │   │   ├── microservice.constant.ts
│   │   │   │   ├── yaml-to-json.constant.ts
│   │   │   │   └── index.ts
│   │   │   ├── ddd/
│   │   │   │   ├── application/
│   │   │   │   ├── domain/
│   │   │   │   └── infrastructure/
│   │   │   ├── dto/
│   │   │   │   ├── api-error.response.ts
│   │   │   │   ├── api.response.dto.ts
│   │   │   │   └── index.ts
│   │   │   ├── enum/
│   │   │   │   ├── action.enum.ts
│   │   │   │   ├── import.enum.ts
│   │   │   │   ├── request.enum.ts
│   │   │   │   ├── status.enum.ts
│   │   │   │   └── index.ts
│   │   │   ├── helpers/
│   │   │   │   └── index.ts
│   │   │   ├── interfaces/
│   │   │   │   ├── base-service.interface.ts
│   │   │   │   ├── factory.interface.ts
│   │   │   │   ├── mapper.interface.ts
│   │   │   │   ├── request.interface.ts
│   │   │   │   ├── response.interface.ts
│   │   │   │   ├── track-performance.interface.ts
│   │   │   │   ├── util.interface.ts
│   │   │   │   └── index.ts
│   │   │   ├── types/
│   │   │   │   ├── abstract.type.ts
│   │   │   │   ├── global.d.ts
│   │   │   │   ├── interceptor.types.ts
│   │   │   │   ├── microservice.type.ts
│   │   │   │   └── index.ts
│   │   │   └── utils/
│   │   │       ├── boolean.util.ts
│   │   │       ├── convert-type.util.ts
│   │   │       ├── cryptography.util.ts
│   │   │       ├── date.util.ts
│   │   │       ├── dotenv.ts
│   │   │       ├── function.util.ts
│   │   │       ├── icons.util.ts
│   │   │       ├── number.util.ts
│   │   │       ├── stream.util.ts
│   │   │       ├── string.util.ts
│   │   │       ├── transform.util.ts
│   │   │       └── index.ts
│   │   └── schematics/
│   │       ├── generate-feature.js
│   │       ├── README.md
│   │       └── templates/
│   ├── README.md
│   ├── LICENSE
│   ├── .git
│   ├── tsconfig.json
│   └── tsconfig.build.json
├── frontend/                          # Next.js frontend application
│   ├── src/
│   │   ├── app/
│   │   │   ├── globals.css            # Global styles (206KB — full design system)
│   │   │   ├── layout.tsx             # Root layout
│   │   │   ├── page.tsx               # Landing / redirect
│   │   │   └── (studio)/             # Route group — main workspace
│   │   │       ├── layout.tsx         # Studio layout (sidebar + header)
│   │   │       ├── ai-agent/          # AI Agent assistant page
│   │   │       ├── auth/              # Authentication pages
│   │   │       ├── dashboard/         # Dashboard overview
│   │   │       ├── data-models/       # Data model management
│   │   │       ├── database/          # Database connections UI
│   │   │       ├── examples/          # Examples gallery
│   │   │       ├── logs/              # System logs viewer
│   │   │       ├── realtime/          # Realtime data streams
│   │   │       ├── settings/          # Application settings
│   │   │       ├── sql-editor/        # SQL query editor
│   │   │       ├── storage/           # S3/Storage management
│   │   │       └── table-editor/      # Table editor (CRUD + visualization)
│   │   ├── components/
│   │   │   ├── ai/                    # AI chat components
│   │   │   ├── database/             # Database connection wizard
│   │   │   ├── layout/               # Sidebar, Header, Navigation
│   │   │   ├── providers/            # React context providers
│   │   │   ├── table-editor/         # DataGrid, column editor
│   │   │   ├── ui/                   # Shared UI primitives
│   │   │   ├── AiAgentAssistant.tsx
│   │   │   └── TableEditorLayout.tsx
│   │   └── lib/
│   │       ├── api-client.ts          # Centralized API client (fetch wrapper)
│   │       └── csv-utils.ts           # CSV export utilities
│   ├── public/                        # Static assets
│   ├── next.config.ts
│   ├── tsconfig.json
│   └── package.json
├── docs/                              # Project documentation
│   ├── README.md                      # Docs index
│   ├── agent-access.md                # Agent access control rules
│   ├── architecture/
│   │   └── README.md                  # High-level architecture overview
│   ├── design/
│   │   └── ui-ux-philosophy.md        # UI/UX design philosophy & principles
│   ├── diagrams/
│   │   ├── erd/                       # Entity-Relationship Diagrams
│   │   ├── sequence/                  # Sequence diagrams
│   │   └── user-workflow.md           # User workflow documentation
│   ├── ddd/                           # DDD interactive viewers (JSX)
│   ├── microservices/
│   │   └── README.md                  # Microservices architecture guide
│   ├── modules/                       # Per-module feature specs & requirements
│   │   ├── ai-assistant/
│   │   ├── auth/
│   │   ├── dashboards/
│   │   ├── database-connections/      # ⭐ Multi-DB connection (PostgreSQL, MySQL, MongoDB)
│   │   ├── embedding/
│   │   ├── examples/
│   │   ├── questions/
│   │   ├── realtime/
│   │   ├── sql-editor/
│   │   ├── storage/                   # ⭐ S3/Storage management (planned: dynamic connections)
│   │   └── table-editor/
│   └── plan/                          # Sprint planning & progress
│       ├── progress.md                # Task progress tracker (master task list)
│       ├── bugs.md   
│       └── sprints/               ← Per-sprint detail files (1 file per sprint)
            ├── sprint-00.md       ← Foundation (Done)
            ├── sprint-01.md … sprint-05.md ← Done
            ├── sprint-06.md … sprint-12.md ← Mixed/Partial (có task Open)
            ├── sprint-13.md … sprint-22.md ← Open (Realtime/AI/SQL backlog)
            ├── sprint-23.md       ← Bug Report System (Done)
            ├── sprint-24.md       ← Global DB Selector + ERD (In Progress)
            ├── sprint-25.md       ← Multi-Connection UX + DDL CRUD (In Progress)
            ├── sprint-26.md       ← Bug Report Enhanced (Open ← NEXT)
            └── sprint-27.md       ← Landing Page "Signal Room" (Open)
├── memory/
│   └── MEMORY.md                      # Persistent memory — lessons learned, decisions, context
├── assets/                            # Server-side rendered UI assets
│   ├── ddd-viewer/                    # DDD interactive viewer
│   ├── dynamic-api-editor/            # Dynamic API editor UI
│   ├── formula-editor/                # Formula editor UI
│   ├── redis-manager/                 # Redis management dashboard
│   ├── transform-editor/              # Data transform editor
│   └── views/                         # Shared EJS/HTML views
├── config/                            # Environment configuration
│   ├── .dev.env                       # Development environment variables
│   ├── .local.env                     # Local environment variables
│   └── .prod.env                      # Production environment variables
├── rules/
│   └── structure.md
├── package.json
├── tsconfig.json
└── README.md
```

## Bundled Skills

| Skill                    | Purpose                                         | Path                                             |
| ------------------------ | ----------------------------------------------- | ------------------------------------------------ |
| `backend-patterns-skill` | DDD patterns, layer rules, base classes         | `./agents/skills/backend-patterns-skill/SKILL.md` |
| `microservices`          | RabbitMQ/Kafka patterns, event contracts        | `./agents/skills/microservices/SKILL.md`          |
| `saga`                   | Distributed transaction, compensation, SagaStep | `./agents/skills/saga/SKILL.md`                   |
| `idempotency-key`        | Idempotency patterns across layers              | `./agents/skills/idempotency-key/SKILL.md`        |
| `database`               | Schema design, migration strategy, TypeORM      | `./agents/skills/database/SKILL.md`               |
| `security-review`        | Cross-cutting security concerns                 | `./agents/skills/security-review/SKILL.md`        |
| `redis`                  | Distributed cache, lock, session design         | `./agents/skills/redis/SKILL.md`                  |

---

### Layer Dependency Rules (ONE-WAY — KHÔNG ĐƯỢC VI PHẠM)

```
Presentation → Application → Domain ← Infrastructure

FORBIDDEN (sẽ bị block ngay):
❌ Domain import từ Infrastructure (NestJS, TypeORM, HTTP client)
❌ Application import từ Presentation
❌ Infrastructure import từ Application
❌ Presentation import trực tiếp từ Infrastructure module
❌ Port interface đặt trong Application (phải ở Domain/ports/)
```

### Core DDD Base Classes (libs/src/ddd — bắt buộc kế thừa)

| Base Class                   | Layer          | Bắt buộc khi                                   |
| ---------------------------- | -------------- | ---------------------------------------------- |
| `BaseAggregateRoot`          | Domain         | Mọi Aggregate Root                             |
| `BaseEntity`                 | Domain         | Entity không phải aggregate                    |
| `BaseDomainEvents`           | Domain         | Mọi domain event                               |
| `BaseCommand`                | Application    | Use-case ghi (create/update/delete/approve...) |
| `BaseQuery`                  | Application    | Use-case đọc (get/list/search...)              |
| `BaseRepositoryTypeORM<D,O>` | Infrastructure | Mọi TypeORM repository                         |
| `BaseMapper<D,O>`            | Shared         | Mọi Domain↔ORM mapper                          |

### Module Folder Rule (đã chốt — không thay đổi)

```
✅ ĐÚNG: src/application/dashboard/       (module trực tiếp dưới layer)
✅ ĐÚNG: src/infrastructure/modules/dashboard/
✅ ĐÚNG: src/presentation/portal/dashboard/controllers/

❌ SAI: src/application/data-builder/dashboard/  (group-folder lồng nhau)
❌ SAI: src/infrastructure/adapters/             (phân mảnh không theo module)
```

## 1. Muc tieu kien truc

NestJS Monorepo ap dung Clean Architecture + Domain-Driven Design. Core domain tach biet hoan toan khoi adapter (HTTP, DB, Message Broker). Use-case ke thua BaseCommand / BaseQuery tu libs/src/ddd. Saga orchestration qua SagaManager cho distributed transactions.

Kien truc can dam bao:

- De mo rong route/connector moi (Open/Closed)
- De thay doi adapter (HTTP -> gRPC -> Kafka)
- Saga rollback chinh xac va minh bach (SagaDefinition + SagaStep)
- Truy vet end-to-end qua nhieu service (OpenTelemetry)
- Dam bao idempotency va reliability
- Khong gian doan van hanh khi scale len (multi-instance)
- **Frontend tối ưu hiệu năng**: Xây dựng bằng React/Next.js tuân thủ nghiêm ngặt `vercel-react-best-practices`.
- **UI/UX đồng nhất**: Áp dụng Metabase Design System (Font Lato, Primary #509EE3) theo định nghĩa dự án (`project.md`).

## 2. Kien truc tong the (Clean Architecture)

Service chia thanh 4 layer chinh:

### Presentation Layer

REST, WebSocket, guards, validation - nhan request tu client.

### Application Layer

Xu ly nghiep vu dieu phoi:

- Use-cases (ghi/doc). Uu tien ke thua `BaseCommand` / `BaseQuery` tu `libs/src/ddd/application`.
- Saga Orchestrator (theo tung module)
- Application Services (theo tung module)
- Policies (theo tung module)

Use-cases theo cau truc hien tai:

- `src/application/order/use-cases/`
    - `create-order.use-case.ts`
    - `pay-order.use-case.ts`
    - `cancel-order.use-case.ts`
- `src/application/agreement/use-cases/`
    - `create-agreement.use-case.ts`
    - `approve-agreement.use-case.ts`

### Domain Layer

Logic nghiep vu thuan:

- Aggregate Root (ke thua `BaseAggregateRoot`)
- Entity (ke thua `BaseEntity`) va `ValueObject`
- Domain Events (ke thua `BaseDomainEvents`)
- UniqueEntityId
- Repository/Service Ports (interface)

### Infrastructure Layer

Cac adapter trien khai port:

- Repository (TypeORM/Mongoose) ke thua `BaseRepositoryTypeORM` (neu dung TypeORM)
- HTTP Clients (Wallet, Connector, Rule, SSO)
- Kafka/RabbitMQ Publisher/Consumer
- Outbox/Inbox
- Resilience (circuit, retry, timeout)
- Cache (Redis)

## 3. Vai tro tung folder

### 3.1 Presentation Layer

- controllers/ REST endpoint, chi goi use-case. Khong chua business logic.
- gateways/ WebSocket push event topup cho client.
- guards/ Auth, maintenance, rate-limit.
- pipes/ Validation DTO.
- filters/ Exception filter chuan hoa output.
- dto/ Request/response object.

### 3.2 Application Layer

- use-cases/ Tat ca luong nghiep vu (ca ghi va doc). Moi use-case doc lap và tách riêng thành từng file, không gộp chung nhiều usecase class trong 1 file
    - Ke thua `BaseCommand`/`BaseQuery` tu `libs/src/ddd/application` de dung hook + validate.
- sagas/ Dat trong tung module (order/, agreement/...), gom orchestration theo domain.
- services/ Dat trong tung module, chi orchestration, khong chua business logic domain.
- policies/ Dat trong tung module, retry/timeout/idempotency theo nghiep vu.
- events/ Dat trong tung module, publish ra Kafka qua EventPort.

### 3.3 Domain Layer

- aggregates/ Aggregate root (ke thua `BaseAggregateRoot`).
- entities/ Entity co ban (ke thua `BaseEntity`).
- value-objects/ `ValueObject`.
- events/ Domain event (ke thua `BaseDomainEvents`).
- repositories/ RepositoryPort interface.
- ports/ WalletPort, ConnectorPort, RulePort, EventPort.
- exceptions/ BusinessError, TechnicalError...

Domain khong phu thuoc framework, khong nhap Prisma/NestJS/HTTP client.

### 3.4 Infrastructure Layer

- persistence/ Trien khai repository bang TypeORM (ke thua `BaseRepositoryTypeORM`, inject `DataSource` + mapper, khong dung `@InjectRepository`) hoac Mongo.
- http-clients/ Wallet/Connector/Rule/SSO HTTP clients. Implement domain ports.
- messaging/kafka Kafka publisher/consumer.
- messaging/rabbitmq RabbitMQ publisher/consumer.
- resilience/ Circuit breaker, retry, timeout, bulkhead.
- cache/ Redis client, Idempotency store, Route cache.
- observability/ OpenTelemetry tracing, metrics, structured logging.

### 3.4a Mapper layer (shared/mappers)

- Mapper chuyen Domain entity <-> ORM entity, extend `BaseMapper<Domain, Orm>` tu `@ddd/infrastructure`.
- Dat trong `src/shared/mappers/` (trong project nay: agreement.mapper, order.mapper, order-item.mapper, customer.mapper, product.mapper, inventory.mapper). Repository nhan `DataSource` va `XxxMapper.create()` trong constructor; base repository dung mapper de `toDomain` / `toOrm`, khong viet mapping truc tiep trong repository.
- **toDomain(orm):** Tao ValueObject/Entity tu ORM (VO.create, Entity.create hoac reconstitute), tra ve domain entity.
- **toOrm(domain):** Map domain ra plain object hoac ORM (co the dung `Orm.fromInput(...)` neu ORM ho tro). Aggregate co nested entity thi dung mapper con (vd. OrderMapper dung OrderItemMapper).
- Vi du: `src/shared/mappers/agreement.mapper.ts`, `order.mapper.ts`, `order-item.mapper.ts`.

## 3.5 Core DDD (libs/src/ddd) - bat buoc follow

- `LibDDDModule` khoi tao `DomainEventDispatcher` va `DomainEventPublisherService`.
- `BaseAggregateRoot` quan ly domain events va dispatch.
- `BaseCommand` / `BaseQuery` cung cap lifecycle hooks + validate; use-case bat buoc extend mot trong hai.
- `BaseRepositoryTypeORM` dung Mapper (shared/mappers) de map Domain <-> Orm va dispatch domain events sau save.

> Khi trien khai project, uu tien ke thua va su dung cac base class trong `libs/src/ddd`
> de dam bao dong nhat lifecycle va domain events.

## 3.6 Summary

1️⃣ Domain Service - ⭐ EASY

Là gì: Logic không thuộc về một entity
Ví dụ: Tính giảm giá (cần Order + Customer)
Code: pricingService.calculateDiscount(order, customer)

2️⃣ Factory - ⭐⭐ MEDIUM

Là gì: Tạo objects phức tạp
Ví dụ: Tạo Order từ Cart (validate, calculate, create)
Code: orderFactory.createFromCart(customerId, items, address)

3️⃣ Policy - ⭐⭐ MEDIUM

Là gì: Pluggable business rules
Ví dụ: Chính sách hủy đơn (VIP vs Thường)
Code: order.cancel(policy, reason) - policy được inject

4️⃣ Double Dispatch - ⭐⭐ MEDIUM

Là gì: Polymorphic behavior
Ví dụ: Payment methods (CreditCard, PayPal, Wallet)
Code: order.pay(paymentMethod) - tự động gọi đúng implementation

5️⃣ Saga - ⭐⭐⭐ HARD

Là gì: Distributed transactions với compensation
Ví dụ: Order flow (Inventory → Payment → Shipping)
Code: Orchestrator với compensation khi fail

6️⃣ Event Sourcing - ⭐⭐⭐ HARD

Là gì: Rebuild state từ events
Ví dụ: Complete audit trail của Order
Code: OrderEventSourced.fromHistory(id, events)

## 3.7 Frontend Architecture (React / Next.js)

Primary Frontend được xây dựng bằng **React** và **Next.js** nằm ở thư mục `frontend/`, tuân thủ chặt chẽ `@.claude/skills/vercel-react-best-practices/SKILL.md` và các quy định từ `project.md`.

### Tiêu chuẩn kỹ thuật (Vercel Best Practices)

- **Eliminating Waterfalls (CRITICAL)**: Tránh await tuần tự, sử dụng `Promise.all` và tính năng `Suspense` để stream dữ liệu.
- **Bundle Size Optimization (CRITICAL)**: Không dùng barrel files (`index.ts` xuất khẩu tất cả), ưu tiên import trực tiếp. Dùng `next/dynamic` cho các component nặng.
- **Re-render Optimization**: Tránh re-render không cần thiết thông qua `memo`, tách các state không ảnh hưởng tới UI ra khỏi vòng đời component (dùng `refs`). Sắp xếp lại hook dependencies.
- **Server/Client Data Fetching**: Tận dụng server-side components để giảm serialize data, dùng `SWR` với deduplication cho phần fetch ở client.

### Tiêu chuẩn UI/UX & Design System

- **Metabase Design System**: Áp dụng chuẩn context hiển thị (Dark/Light mode).
- **Typography & Colors**: Bắt buộc sử dụng font `Lato, sans-serif`. Mã màu chính là **Picton Blue (`#509EE3`)**.
- **Layout & Canvas**: Không gian hiển thị Data Cards cần có inner padding `24px` và border radius `8px`.
- **Visual Query Builder**: Tránh dùng Tailwind chung chung cho core builder; dùng component styles quy định trong `.claude/skills/ui-ux/components`. Phần front-end tích hợp client-side reactivity (React) cùng `SortableJS` cho canvas kép kéo-thả, hỗ trợ `SweetAlert2` cho các prompt.- **Layout & Canvas**: Không gian hiển thị Data Cards cần có inner padding `24px` và border radius `8px`.
- **Visual Query Builder**: Tránh dùng Tailwind chung chung cho core builder; dùng component styles quy định trong `.claude/skills/ui-ux/components`. Phần front-end tích hợp client-side reactivity (React) cùng `SortableJS` cho canvas kép kéo-thả, hỗ trợ `SweetAlert2` cho các prompt.

## 3.8 Documentation (`docs/`)

Chứa toàn bộ tài liệu dự án — **PHẢI đọc trước khi implement module liên quan**.

| Thư mục                 | Nội dung                                | Khi nào cần đọc                        |
| ----------------------- | --------------------------------------- | -------------------------------------- |
| `docs/architecture/`    | High-level architecture & Impl Plans    | Khi thiết kế module mới                |
| `docs/architecture/design-philosophy.md` | UI/UX philosophy & design principles | Khi làm frontend                       |
| `docs/diagrams/`        | ERD, sequence diagrams, user workflows  | Khi cần hiểu data flow                 |
| `docs/architecture/diagrams/` | DDD interactive viewers (JSX)      | Khi cần review DDD layers              |
| `docs/features/`        | Implementation Plans cho Feature mới    | Khi bắt đầu làm tính năng mới          |
| `docs/bugs/`            | Implementation Plans cho Bug fixes      | Khi điều tra và fix bug phức tạp       |
| `docs/microservices/`   | Microservices guide (RabbitMQ/Kafka)    | Khi làm cross-service                  |
| `docs/modules/<name>/`  | Feature specs + requirements per module | **Bắt buộc đọc trước khi code module** |
| `docs/plan/progress.md` | Master task list — toàn bộ task status  | Khi lên task / check status            |
| `docs/plan/sprint*.md`  | Sprint-specific feature plans           | Khi cần context sprint hiện tại        |

## 3.9 Memory (`memory/`)

- `memory/MEMORY.md` — **Knowledge base** lưu decisions, patterns, pitfalls, gotchas xuyên suốt dự án.
- **KHÔNG trùng lặp** với `CHANGELOG.md` (what changed) hay `progress.md` Activity Log (what happened).
- File này trả lời: "Tại sao chọn approach X?", "Pattern nào đã chứng minh hiệu quả?", "Lỗi nào cần tránh?"
- Agents nên đọc khi cần context lịch sử, trước quyết định kiến trúc, hoặc khi gặp vấn đề tương tự đã từng xảy ra.
- **Orchestrator** đọc khi init (step 2.3) và append lessons learned khi close session (Rule 5).

## 3.10 Assets (`assets/`)

Chứa **server-side rendered UI assets** — các tool/editor được serve qua NestJS backend (không phải Next.js frontend).

| Thư mục                      | Mô tả                          |
| ---------------------------- | ------------------------------ |
| `assets/ddd-viewer/`         | DDD layer interactive viewer   |
| `assets/dynamic-api-editor/` | Dynamic API endpoint editor    |
| `assets/formula-editor/`     | Formula/expression editor      |
| `assets/redis-manager/`      | Redis management dashboard     |
| `assets/transform-editor/`   | Data transformation editor     |
| `assets/views/`              | Shared EJS/HTML view templates |

> **Lưu ý**: Các asset này được serve qua `assets-base` module (`libs/src/common/modules/assets-base/`), xem thêm skill `server-side-render`.

## 3.11 Config (`config/`)

Chứa environment variables cho các môi trường:

| File         | Môi trường  | Ghi chú                    |
| ------------ | ----------- | -------------------------- |
| `.dev.env`   | Development | Dùng khi chạy local dev    |
| `.local.env` | Local       | Cấu hình đặc thù máy local |
| `.prod.env`  | Production  | Cấu hình production        |

Các key quan trọng: DB connection, Redis, S3, Sentry DSN, JWT secrets, Kafka/RabbitMQ config. **Không hardcode secrets trong code** — luôn reference từ `config/`.

## 4. Chay linter

```bash
pnpm lint
```

## 5. Kiem tra toan bo

```bash
# Format + Lint + Test
pnpm format && pnpm lint && pnpm test
```

## 6. Cau hinh

### eslint.config.js / .eslintrc.js

- Cau hinh cac rules cho TypeScript/NestJS
- Thiet lap muc do strict, rule exceptions
- Loai tru mot so file/pattern khong can kiem tra

### .prettierrc

- Cau hinh format code (indent, quotes, trailing commas)
- Dam bao consistency giua cac editor

### .editorconfig

- Cau hinh editor de tu dong format
- Thiet lap indentation cho cac loai file khac nhau
- Dam bao consistency giua cac editor

## 7. Code Style Rules (NestJS/TypeScript)

### 7.1 Formatting

- Su dung 4 spaces cho indentation
- Do dai dong toi da: 120 ky tu
- Format tu dong bang Prettier

### 7.2 Imports

- Nhom imports: standard library, third-party, local
- Sap xep imports alphabetically trong moi nhom
- Tu dong loai bo unused imports bang ESLint/TS

### 7.3 Naming

- camelCase cho variables va functions
- PascalCase cho class/interface/type
- Su dung `I` prefix cho interface neu du an yeu cau

### 7.4 Comments

- Moi exported class/function/type can comment ngan
- Comment bat dau bang ten cua class/function/type

### 7.5 Error Handling

- Throw HttpException hoac custom Exception trong `libs/src/common/exceptions`
- Khong throw raw Error trong layer application/domain

## 8. Git Hooks

### Pre-commit Hook

Tu dong chay khi commit:

1. Format code (Prettier)
2. Chay linter (ESLint)
3. Chay tests (optional)
4. Tu choi commit neu co loi

## 9. Summary

### 9.1 Kien truc tong quan

- Ap dung Clean Architecture + DDD core (`libs/src/ddd`) -> tach core domain khoi adapter.
- Use-case ke thua `BaseCommand`/`BaseQuery` (hook + validate).
- Dung Saga cho qua trinh reserve -> connector -> confirm/reverse.
- Toan bo giao tiep voi he thong khac qua Outbound Ports.
- Tat ca request vao qua Inbound Ports (REST, WS, Kafka Callback).
- Dung Domain Event + Event Bus de cap nhat trang thai.

### 9.2 Do tin cay va chong loi

- Idempotency key cho moi request.
- Outbox pattern de dam bao event khong mat.
- Circuit breaker + retry + timeout cho tat ca external calls.
- Tu dong chuyen trang thai giao dich ve manual neu connector pending.

### 9.3 Kha nang mo rong

- Them connector -> chi tao adapter moi, khong dong vao core.
- Them loai topup moi -> them UseCase + Saga Steps, core van giu nguyen.
- Dung TurboRepo chia se thu vien chung (contracts, decorators, utils).

### 9.4 Quan sat - Monitoring

- OpenTelemetry tracing day du toan Saga.
- Log dang structured JSON.
- Metrics Prometheus:
    - so giao dich
    - ty le loi
    - latency tung step
    - trang thai Saga

## 10. Antigravity Agentic Artifacts

When making architectural decisions or proposing layer structures:

1. Always generate Mermaid diagrams (ERD, Flow) to explain your design.
2. Append these diagrams and decisions into the `implementation_plan.md` artifact for user review.
3. If this design involves significant changes, use the `notify_user` tool to request the Mission Commander's approval before writing code.

---

## 11. Bài học kinh nghiệm (Lessons Learned)

Sau một số sai sót trong việc phân bổ cấu trúc thư mục, dưới đây là nguyên tắc ĐÃ CHỐT về cấu trúc module phân rã theo layer (Presentation, Application, Domain, Infrastructure), bắt buộc phải tuân theo dự án tham khảo `domain-driven-design/src`:

1. **Mỗi Module là một Folder trực tiếp dưới các tầng kiến trúc (Layer).**
    - **ĐÚNG**: `src/application/dashboard/`, `src/application/ai-agent/`
    - **SAI**: Tạo các group-folder nhồi nhét nhiều module (vd: `src/application/data-builder/dashboard/`, `src/application/data-builder/ai-agent/`). Việc gộp tất cả module vào chung một folder lớn là sai thiết kế ban đầu.
2. **Tại Presentation Layer (Portal):**
    - **ĐÚNG**: `src/presentation/portal/<module_name>/controllers/<module_name>-command.controller.ts`
    - **SAI**: Đặt ngang hàng tất cả controllers tại `src/presentation/portal/data-builder/controllers/...` hay chia nhỏ lẻ theo từng file không có quy củ.
3. **Tại Infrastructure Layer:**
    - **ĐÚNG**: Đặt tất cả file infrastructure vao trong folder `modules/<module_name>`. Ví dụ: `src/infrastructure/modules/dashboard/entities/dashboard.orm.entity.ts`, `src/infrastructure/modules/dashboard/repositories/dashboard.repositories.ts`.
    - **SAI**: Phân mảnh file theo `adapters/`, `persistence/`, `workers/` độc lập mà không gom nhóm theo tính năng module trực tiếp.
4. **Bài học:** Mọi component, controller, use-case, entity, hay repository đều TỪ CHỐI bị nhồi nhét vào một Feature package lớn đa domain. Hãy phân rã thành các module độc lập ngay từ cấp thư mục cao nhất của Layer để tuân thủ chặt chẽ Separation of Concerns và chuẩn DDD của dự án.
