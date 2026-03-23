# NestJS + DDD Monorepo - AI Assistant Rules

> This file is automatically loaded by Cursor IDE. For Claude Code, see `.claude/AGENTS.md`

## Project Overview

NestJS + DDD monorepo following Clean Architecture principles.
Architecture: DDD + Event Sourcing
Coding style: Clean code, SOLID principles
Core DDD utilities located in `libs/src/ddd/`.

| Item | Value |
|---|---|
| Framework | NestJS (TypeScript) |
| Architecture | Clean Architecture + DDD + Event Sourcing |
| Monorepo | TurboRepo — `src/` (app) + `libs/` (shared) |
| Databases | PostgreSQL (TypeORM), MongoDB, Redis |
| Messaging | RabbitMQ, Kafka, BullMQ |
| DevOps | Docker, Kubernetes, Terraform, Sentry |
| Business Domains | Fintech, DMS, Ecommerce, Data Visualizer |

---

ignore_patterns:

- node_modules/\*\*
- dist/\*\*
- .git/\*\*
- coverage/\*\*
- \*.log

focus_areas:

- src/domain/\*\*
- src/application/\*\*
- src/infrastructure/\*\*
- src/presentation
- libs/src\*\*
- docs/\*\*
- database/\*\*

## 📚 Required Reading (BEFORE ANY CHANGE)

Before making ANY changes, you MUST read these files:

- `.claude/agents/architecture.md` - Architecture overview
- `libs/src/ddd` - DDD base classes
- `.claude/PATTERNS.md` - Code style and patterns
- `changelogs/changes` - All changes must be documented in this folder, explain the root cause, the solution, and the impact
- `changelogs/CHANGELOG.md` - Changelog & Requirement Tracker
- `docs/README.md` - Cấu trúc folder tài liệu (business + diagrams) ERD/flows

## Architecture (MUST FOLLOW)

### Saga Pattern (MUST FOLLOW)

- Khi implement/debug bất kỳ flow saga nào, bắt buộc tham chiếu `@.claude/skills/saga/SKILL.md` trước khi sửa code.
- Khi cần ví dụ triển khai end-to-end (orchestrator, participant, reply-consumer, test scenarios), bắt buộc đọc `@.claude/skills/saga/README.md`.
- Saga orchestration phải dùng core tại `libs/src/ddd/saga` (`SagaDefinition`, `SagaStep`, `SagaManager`), không tự triển khai pattern khác.
- Header contract saga phải giữ stateless routing (echo các header `command_reply_*` từ participant replies).
- Không hardcode env key names trong `libs/src/ddd/saga`; mapping env key nằm ở `src/infrastructure/**`.

### Layer Dependencies (One-way only)

```text
Presentation → Application → Domain ← Infrastructure
```

- **Presentation**: Controllers, DTOs, Guards, Pipes, Filters
- **Application**: Use-cases, Sagas, Application Services, Policies
- **Domain**: Entities, Value Objects, Domain Events, Repository Interfaces
- **Infrastructure**: Repository implementations, HTTP clients, Messaging, Cache

### DDD Core Classes (libs/src/ddd)

| Base Class              | Purpose                               | Location                      |
| ----------------------- | ------------------------------------- | ----------------------------- |
| `BaseCommand`           | Write use-cases with hooks + validate | `libs/src/ddd/application`    |
| `BaseQuery`             | Read use-cases with hooks + validate  | `libs/src/ddd/application`    |
| `BaseAggregateRoot`     | Aggregate roots with domain events    | `libs/src/ddd/domain`         |
| `BaseEntity`            | Domain entities                       | `libs/src/ddd/domain`         |
| `BaseDomainEvents`      | Domain event base                     | `libs/src/ddd/domain`         |
| `BaseRepositoryTypeORM` | TypeORM repository with mapping       | `libs/src/ddd/infrastructure` |


### Dependency Direction (One-Way Only)

```text
Presentation → Application → Domain ← Infrastructure
```

| Layer | Trách nhiệm | KHÔNG được |
|---|---|---|
| **Domain** | Entity, Aggregate, VO, Domain Events, Repository Port | Import bất kỳ layer nào |
| **Infrastructure** | Repository impl, ORM entity, HTTP client, Messaging, Cache | Import Application, Presentation |
| **Application** | Use-cases (Command/Query), Sagas, App Services | Import Presentation, ORM entity |
| **Presentation** | Controllers, DTOs, Guards, Pipes, Subscribers | Import Domain trực tiếp, ORM entity, Infrastructure |

### Folder Structure Rules (ĐÃ CHỐT — BẮT BUỘC TUÂN THEO)

```text
src/
├── domain/<module>/              ← Pure domain logic
├── application/<module>/         ← Use-cases, Sagas, Policies
├── infrastructure/
│   └── modules/<module>/         ← ORM entity, Repository impl
└── presentation/
    └── portal/<module>/          ← Controllers, DTOs, Subscribers
```

Chi tiết nguyên tắc tổ chức layer, dependency direction, mapper/repository boundaries và module wiring phải follow theo `@.claude/agents/architecture.md`.

> ⛔ NGHIÊM CẤM: Gộp nhiều module vào một group-folder lớn (VD: `application/data-builder/dashboard/`).
> ✅ ĐÚNG: Mỗi module là một folder độc lập trực tiếp dưới layer.

### Use-Case Layer (MUST FOLLOW)

Tất cả use-case phải extend `BaseCommand` hoặc `BaseQuery`:

- **BaseQuery**: Get list, get detail (read-only) → implement `query(request)`, gọi `queryWithHooks(request)`
- **BaseCommand**: Create, Update, Delete, Approve, Cancel, Pay, Ship... (write) → implement `execute(request)`, gọi `executeWithHooks(request)`

### 📁 Module Wiring Convention

```typescript
// ĐÚNG: Infrastructure module provide Port binding
@Module({
  providers: [
    { provide: OrderRepositoryPort, useClass: OrderRepository },
  ],
  exports: [OrderRepositoryPort],
})
export class OrderInfraModule {}

// ĐÚNG: Application module import Infra để lấy binding
@Module({
  imports: [OrderInfraModule, OrderDomainModule],
  providers: [CreateOrderUseCase],
})
export class OrderApplicationModule {}

// ĐÚNG: Presentation chỉ import Application
@Module({
  imports: [OrderApplicationModule],
  controllers: [OrderCommandController],
})
export class OrderPresentationModule {}
```

## Code Style & Config (MUST FOLLOW)

All detailed coding standards and configuration conventions are centralized in:

- `@.claude/skills/coding-standards/SKILL.md`

Before coding, MUST read coding-standards, security-review, tdd-workflow.

## Frontend Stack & Architecture (IMPORTANT)

- **Primary Frontend**: The main frontend for the project must be built with React and Next.js. You MUST strictly follow the `@.claude/skills/vercel-react-best-practices/SKILL.md` skill for optimal performance and component architecture.
- **Backend Embedded Views (SSR)**: If a specific module strictly requires rendering within the NestJS backend, use the `server-side-render` skill (`@.claude/skills/server-side-render/SKILL.md`) with Handlebars (`.hbs`).

## Big Data

### Stream Export

- **Stream Pipeline** (`libs/src/common/modules/stream-pipeline`): Dùng stream pipeline hoặc async generator cho dataset lớn; tránh load toàn bộ vào memory. Xem `@.claude/skills/stream-pipeline/SKILL.md`
- **Report Stream Export** (`libs/src/common/modules/report`): SDK export CSV/Excel qua stream. Xem `@.claude/skills/stream-pipeline/report/SKILL.md`

### Import Engine (MUST FOLLOW)

- Khi implement bất kỳ import flow nào, bắt buộc đọc `@.claude/skills/stream-pipeline/import/SKILL.md` trước khi code.
- Flow chi tiết tham chiếu `@.claude/skills/stream-pipeline/import/FLOW.md`.
- Example đầy đủ tại `@.claude/skills/stream-pipeline/import/EXAMPLE.md`.
- **Local saga compensation** (không dùng `SagaManager`): Strategy → Saga.execute() → try/catch → compensate() → deleteByIds(). Xem SKILL.md section "Local Saga Compensation Pattern".
- Mỗi repository phải có `deleteByIds(ids)` và `createWithRelations()` trả về `Promise<string>` (ID).

## Security (CRITICAL)

Security checklist and secure coding patterns are centralized in:

- `@.claude/skills/security-review/SKILL.md`

## 🚨 CRITICAL: Agent Workflows (MUST FOLLOW STRICTLY) 🚨

Tất cả assistant/agent **PHẢI TUÂN THỦ NGHIÊM NGẶT** các workflow định nghĩa tại `data-visualizer/.claude/workflows/`. Đây là yêu cầu cao nhất, không được phép bỏ qua hoặc làm tắt:

1. `@.claude/workflows/orchestration.md` - Luồng điều phối tổng thể và TDD workflow.
2. `@.claude/workflows/new-feature.md` - Các bước bắt buộc khi tạo tính năng mới (Plan -> TDD -> Implement -> Verify).
3. `@.claude/workflows/debugging.md` - Quy trình điều tra và fix bug chuẩn.

**Bất kỳ vi phạm nào đối với các bước trong workflows sẽ bị coi là lỗi nghiêm trọng (critical failure).** Mọi hành động đều phải bám sát các luồng đã được định nghĩa.

## Testing (TDD Mandatory)

TDD workflow, project test baseline, and test examples are centralized in:

- `@.claude/workflows/orchestration.md`
- `@.claude/skills/tdd-workflow/SKILL.md`
- `@.claude/workflows/new-feature.md`
- `@.claude/workflows/debugging.md`

---

## 📖 Documentation Requirements

| Loại tài liệu                          | Vị trí                  |
|----------------------------------------|-------------------------|
| Business glossary, requirements, rules | `docs/business/`        |
| ERD (ưu tiên Mermaid `.mmd`)           | `docs/diagrams/erd/`    |
| Business flow / sequence diagram       | `docs/diagrams/flows/`  |

> **Antigravity Agentic Artifacts**: Khi đưa ra quyết định kiến trúc, Agent **PHẢI** generate Mermaid diagram (ERD/Flow) và append vào `implementation_plan.md` trước khi viết code. Thay đổi lớn → dùng `notify_user` để request approval của Mission Commander.

---

## 🔀 Git Workflow

### Commit Format

```text
<type>: <description>

Types: feat | fix | refactor | docs | test | chore | perf | ci
```

### Before Commit

```bash
pnpm format && pnpm lint && pnpm test
```

---

## Available Agents

Reference agents with `@` in your prompts:

| Agent             | When to Use                    | Reference                             |
| ----------------- | ------------------------------ | ------------------------------------- |
| Architecture      | System design, layer decisions | `@.claude/agents/architecture.md`      |
| Code Reviewer     | After writing code             | `@.claude/agents/code-reviewer.md`     |
| TDD Guide         | New features, bug fixes        | `@.claude/agents/tdd-guide.md`         |
| Refactor Cleaner  | Dead code cleanup              | `@.claude/agents/refactor-cleaner.md`  |
| Security Reviewer | Before commits                 | `@.claude/agents/security-reviewer.md` |
| E2E Runner        | Critical user flows            | `@.claude/agents/e2e-runner.md`        |
| Planner           | Complex features               | `@.claude/agents/planner.md`           |

## Available Skills

| Skill              | Purpose                                                                 | Reference                                                   |
| ------------------ | ----------------------------------------------------------------------- | ----------------------------------------------------------- |
| Coding Standards   | Universal best practices                                                | `@.claude/skills/coding-standards/SKILL.md`                  |
| TDD Workflow       | Test-driven development                                                 | `@.claude/skills/tdd-workflow/SKILL.md`                      |
| Security Review    | Security checklist and secure coding patterns                           | `@.claude/skills/security-review/SKILL.md`                   |
| NestJS Config      | Configuration management                                                | `@.claude/skills/nestjs-config/SKILL.md`                     |
| Database           | Persistence, queries, transactions                                      | `@.claude/skills/database/`                                  |
| Redis              | Cache, streams                                                          | `@.claude/skills/redis/`                                     |
| Microservices      | Event bus, rabbitmq, kafka on nestjs patterns                           | `@.claude/skills/microservices/`                             |
| Saga               | Distributed transaction orchestration, compensation, idempotency        | `@.claude/skills/saga/SKILL.md`                              |
| Idempotency Key    | Prevent duplicate HTTP requests                                         | `@.claude/skills/idempotency-key/SKILL.md`                   |
| Import Engine      | CSV/Excel import với stream pipeline, BullMQ queue, local saga rollback | `@.claude/skills/stream-pipeline/import/SKILL.md`            |
| Server-Side Render | Server-Side Rendering (SSR) pages & static assets with `assets-base`    | `@.claude/skills/server-side-render/SKILL.md`               |
| React / Next.js    | Primary frontend framework using Vercel best practices                  | `@.claude/skills/vercel-react-best-practices/SKILL.md`      |
| UI/UX Intelligence | Generative UX/UI layouts, styles, and typography patterns (Tailwind)    | `@.claude/skills/ui-ux/SKILL.md`                            |
| Agent Browser      | Browser automation via inference.sh CLI                                 | `@.claude/skills/agent-browser/SKILL.md`                    |
| Agent Tools        | Run 150+ AI apps (LLMs, Video, Image) via inference.sh                  | `@.claude/skills/agent-tools/SKILL.md`                      |
| AI Image Gen       | Generate AI images with FLUX, Gemini, etc.                              | `@.claude/skills/ai-image-generation/SKILL.md`              |
| Design MD          | Analyze projects to synthesize DESIGN.md files                          | `@.claude/skills/design-md/SKILL.md`                        |
| Frontend Design    | Create distinctive, production-grade frontend interfaces                | `@.claude/skills/frontend-design/SKILL.md`                  |
| Nano Banana        | Gemini native image generation                                          | `@.claude/skills/nano-banana/SKILL.md`                      |
| Nano Banana 2      | Gemini 3.1 Flash Image preview                                          | `@.claude/skills/nano-banana-2/SKILL.md`                    |
| Skill Creator      | Create, modify, and evaluate skills                                     | `@.claude/skills/skill-creator/SKILL.md`                    |
| Supabase Postgres  | Postgres performance optimization and best practices                    | `@.claude/skills/supabase-postgres-best-practices/SKILL.md` |
| UI/UX Pro Max      | UI/UX design intelligence (styles, palettes, fonts)                     | `@.claude/skills/ui-ux-pro-max/SKILL.md`                    |
| Web Design Guide   | Review UI code for Web Interface Guidelines compliance                  | `@.claude/skills/web-design-guidelines/SKILL.md`            |

## 💡 Tips

1. **Multi-file edits**: Use Cursor Composer for creating related files
2. **Context**: Reference other files with `@filename`
3. **Terminal**: Use Cursor terminal for running tests
4. **Codebase**: Use `@Codebase` to search across project
5. **Docs**: Use `@docs/README.md` cho cấu trúc tài liệu; `@docs/business/`, `@docs/diagrams/erd/`, `@docs/diagrams/flows/` cho tài liệu nghiệp vụ và sơ đồ

## 🔍 Before Making Changes

Always ask yourself:

1. ✅ Am I in the correct layer?
2. ✅ Does this follow DDD principles?
3. ✅ Am I using the correct base class?
4. ✅ Are my dependencies pointing inward?
5. ✅ Have I added tests?
6. ✅ Is this documented?

## 🚀 Feature Delivery References

- New feature implementation workflow: `@.claude/workflows/new-feature.md`
- Debug workflow: `@.claude/workflows/debugging.md`
- Code comments, JSDoc, and module README standards: `@.claude/skills/coding-standards/SKILL.md`

## 📊 Observability

- **Tracing**: Sentry — full trace xuyên Saga flow.
- **Logging**: Structured JSON logs.
- **Metrics** (Prometheus): transaction count, error rate, latency per saga step, saga state.

## Real-World Examples

Ví dụ code theo từng layer (Domain, Application, Infrastructure, Presentation) dựa trên Agreement và Order, **infrastructure theo flow mới** (persistence trong `src/infrastructure/persistence`, không dùng `infrastructure/database`):

| Reference                        | Mục đích                                                                                                                                         |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `@.claude/EXAMPLES.md`            | Agreement/Order: entity, VO, repository port, use-case (Command/Query), infra (TypeORM module, repository, mapper, ORM entity), controller, DTOs |
| `@.claude/PATTERNS.md`            | Cách sử dụng cho từng layer                                                                                                                      |
| `@.claude/skills/saga/EXAMPLE.md` | Saga pattern end-to-end: orchestrator, use-case start, participant/reply consumer, test scenarios                                                |

## Quick Commands

```bash
# Development
pnpm start              # Start dev server
pnpm start:dev          # Start dev server
pnpm test              # Run tests
pnpm test:cov          # Coverage report
pnpm lint              # Lint code
pnpm format            # Format code

# Build
pnpm build             # Production build
pnpm start:prod        # Start production
```

---

> **Note**: For advanced features like hooks, continuous learning, and agent orchestration,
> use Claude Code with configuration in `.claude/` folder.
