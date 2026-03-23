---
description: Workflow: Create New Feature
---

# Workflow: Create New Feature

## Step-by-Step Guide

### Step 1: Plan the Feature (5-10 min)

- [ ] Read requirements carefully
- [ ] Identify bounded context
- [ ] List aggregates and entities needed
- [ ] List value objects
- [ ] Map domain events
- [ ] Sketch use cases

#### Requirements analysis checklist

- [ ] Identify bounded context
- [ ] List aggregates and entities
- [ ] Identify value objects
- [ ] List use cases
- [ ] Map domain events

**Cursor Command:**

```
@Codebase Analyze the requirements for {{FEATURE}} and create a plan
following the structure in .claude/PATTERNS.md
```

### Step 2: Create Domain Layer (20-30 min)

- [ ] Create aggregate(s) extending BaseAggregateRoot
- [ ] Create value objects
- [ ] Create domain events
- [ ] Create repository interface (port)
- [ ] Write unit tests for domain logic

**Cursor Command:**

```
Create the domain layer for {{FEATURE}}:
1. @.claude/PATTERNS.md Use Aggregate Pattern for {{Entity}}
2. @.claude/PATTERNS.md Use Value Object Pattern for {{ValueObjects}}
3. @.claude/PATTERNS.md Use Domain Event Pattern for {{Events}}
4. Create repository interface in src/domain/{{context}}/repositories/

Include comprehensive unit tests for all domain logic.
```

### Step 3: Create Application Layer (20-30 min)

- [ ] Create use case commands/queries
- [ ] Implement use cases extending BaseCommand/BaseQuery
- [ ] Add permission checks
- [ ] Handle domain events
- [ ] Write integration tests

**Cursor Command:**

```
Create application layer for {{FEATURE}}:
1. @.claude/PATTERNS.md Use Use Case Pattern for:
   - Create{{Entity}}UseCase
   - Update{{Entity}}UseCase
   - Delete{{Entity}}UseCase
   - Get{{Entity}}Query
   - List{{Entity}}Query
2. Inject dependencies: repository, permission service, event bus
3. Implement permission checks using PermissionService
4. Handle and publish domain events

Include integration tests mocking dependencies.
```

### Step 4: Create Mapper Layer (10-15 min)

- [ ] Create mapper in `src/shared/mappers/`
- [ ] Extend `BaseMapper<{{Entity}}, {{Entity}}Orm>` from `@ddd/infrastructure`
- [ ] Implement `toDomain(orm)` (VO.create, Entity.create/reconstitute)
- [ ] Implement `toOrm(domain)` (plain object or `Orm.fromInput(...)`)
- [ ] For aggregates with nested entities, use child mappers (e.g. OrderItemMapper in OrderMapper)
- [ ] Export from `src/shared/mappers/index.ts`

**Cursor Command:**

```
Create mapper for {{FEATURE}}:
1. @.claude/PATTERNS.md Use Mapper Pattern (Domain ↔ ORM)
2. Create src/shared/mappers/{{entity}}.mapper.ts
3. toDomain: build ValueObjects and domain entity from ORM
4. toOrm: map domain to ORM (use Orm.fromInput if available)
5. Add to shared/mappers/index.ts

Reference @.claude/EXAMPLES.md AgreementMapper / OrderMapper.
```

### Step 5: Create Infrastructure Layer (15-20 min)

- [ ] Create ORM entity (`*.orm.entity.ts`) in `src/infrastructure/{{module}}/entities/`
- [ ] Implement repository extending `BaseRepositoryTypeORM<{{Entity}}, {{Entity}}Orm>`
- [ ] Constructor: `DataSource` + `{{Entity}}Mapper.create()` (no `@InjectRepository`)
- [ ] Override `save()` to call `super.saveOne()` then `dispatchDomainEventsForAggregates()`
- [ ] Register repository provider in `src/infrastructure/persistence/typeorm/typeorm.module.ts`
- [ ] Create migration for `{{entity}}` table
- [ ] Test repository with test database

**Cursor Command:**

```
Create infrastructure layer for {{FEATURE}}:
1. @.claude/PATTERNS.md Use Repository Pattern (DataSource + Mapper, no InjectRepository)
2. Create {{Entity}}Orm in src/infrastructure/{{module}}/entities/
3. Implement {{Entity}}Repository: super({{Entity}}Orm, dataSource, {{Entity}}Mapper.create())
4. Override save() with dispatchDomainEventsForAggregates after saveOne
5. Add repository provider to persistence/typeorm/typeorm.module.ts
6. Create migration for {{entity}} table

Domain ↔ ORM mapping is in Mapper (Step 4), not in repository.
Reference @docs/diagrams/erd/erd.md (or @docs/diagrams/erd/ARCHITECTURE.md) for table structure.

**Antigravity Mission Control Checkpoint**: Before generating these infrastructure files, write your architectural decisions into the `implementation_plan.md` artifact and use `notify_user` to request approval. Do not proceed until approved.
```

### Step 6: Create Presentation Layer (15-20 min)

- [ ] Create DTOs with validation
- [ ] Create JSON controller independently of views (for future detached SPA: React/Next/Vue)
- [ ] Setup SSR `.hbs` controller conditionally if view is needed
- [ ] Add Swagger documentation
- [ ] Write E2E tests

**Cursor Command:**

```
Create presentation layer for {{FEATURE}}:
1. @.claude/PATTERNS.md Use Controller Pattern (SwaggerApiTags, SwaggerApiCreatedResponse, SwaggerApiListResponse, SwaggerApiResponse from @core/swagger)
2. @.claude/PATTERNS.md Use DTO Pattern for requests/responses
3. Add validation decorators to DTOs
4. Controllers call useCase.executeWithHooks() / useCase.queryWithHooks()
5. Implement all CRUD endpoints independently to support separate frontend client in the future.

Include E2E tests for all endpoints.
```

### Step 7: Integration (10 min)

- [ ] Create module (presentation + application wiring)
- [ ] Register use-case and controller providers
- [ ] Repository already registered in persistence/typeorm (Step 5)
- [ ] Import module into AppModule (or portal module)
- [ ] Update documentation

**Cursor Command:**

```
Wire {{Entity}} feature:
1. Create/update {{Entity}}Module with use cases and controller
2. Provide I{{Entity}}Repository -> {{Entity}}Repository (if not already in TypeOrmInfrastructureModule)
3. Import module in AppModule or presentation portal module
4. Update README.md with feature documentation
```

### Step 8: Testing, Verification & Walkthrough Artifact (15 min)

- [ ] Run all tests: `pnpm test`
- [ ] Check coverage: `pnpm test:cov`
- [ ] Run linter: `pnpm lint`
- [ ] Manual API testing
- [ ] Generate `walkthrough.md` documenting what was created and the test results

**Commands:**
// turbo-all

```bash
pnpm test
pnpm test:cov
pnpm lint
pnpm format
```

## Create Feature Checklist (Quick)

- [ ] Domain: Aggregates, entities, value objects, events
- [ ] Domain: Repository interface (port)
- [ ] Application: Use cases (commands/queries)
- [ ] Infrastructure: Repository implementation
- [ ] Infrastructure: ORM entities + migration
- [ ] Presentation: Controller + DTOs + Swagger
- [ ] Tests: Unit + integration + E2E
- [ ] Docs: Update README + JSDoc for key APIs

## Recommended File Generation Order

1. Domain events
2. Value objects
3. Entities/Aggregates
4. Repository port (interface)
5. Use cases
6. Repository implementation
7. ORM entities
8. DTOs
9. Controller
10. Tests
11. Migration

## Total Time: ~2–2.5 hours

## Checklist Before PR

- [ ] All tests passing
- [ ] Code coverage >80%
- [ ] No linter errors
- [ ] No TypeScript errors
- [ ] API documented in Swagger (custom decorators from @core/swagger)
- [ ] README updated
- [ ] **Mapper** in `src/shared/mappers/` with toDomain/toOrm
- [ ] **Repository** uses DataSource + Mapper (no toPersistence/toDomain in repo)
- [ ] Migration created
- [ ] Follows DDD principles
- [ ] Follows rules.md
