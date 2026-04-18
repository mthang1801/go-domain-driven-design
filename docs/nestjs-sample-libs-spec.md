# NestJS Sample Libs Specification

## Scope

This document specifies the role of `examples/nestjs-sample/libs/src` in relation to the primary application in `examples/nestjs-sample/src`.

It answers four questions:

1. What each top-level library folder is responsible for.
2. Which reusable NestJS modules exist in the library and what they are for.
3. How the primary source should consume the library.
4. What dependency rules keep the architecture consistent.

The goal is to make `libs/src` understandable as an internal platform layer, not a miscellaneous shared folder.

## Executive Summary

`examples/nestjs-sample/libs/src` is the reusable platform/kernel for the sample app.

- `src/` contains product-specific business code for the data visualizer application.
- `libs/src/ddd` provides the architectural foundation for DDD and Clean Architecture.
- `libs/src/core` provides NestJS and infrastructure adapters such as routing, persistence bootstrap, messaging, transport-agnostic microservice config orchestration, Swagger, Redis, uploads, and logging.
- `libs/src/common` provides cross-cutting behavior and reusable feature modules such as exceptions, transform interceptors, stream pipelines, import engine, report engine, and asset-backed editors.
- `libs/src/shared` provides low-level stateless helpers, DTO shells, interfaces, constants, and types.
- `libs/src/schematics` is a code generation aid and is not part of the runtime path.

The primary app should treat `libs/src` as a stable internal framework:

- `src/domain` should build on `@ddd/domain` and `@ddd/interfaces`.
- `src/application` should build on `@ddd/application` plus selected `@common` and `@shared` utilities.
- `src/infrastructure` should wrap and configure `@core/*` modules, and should model messaging topology through `@core/microservices` when building Kafka/RabbitMQ infrastructure.
- `src/presentation` should use `@core/router`, `@core/swagger`, and selected `@common/modules/*`.
- `src/main.ts` and `src/app.module.ts` are the composition roots for global library behavior.

## Architectural Positioning

```text
examples/nestjs-sample/
├── src/                     # Primary application: product-specific code
│   ├── domain/             # Business concepts, ports, repositories
│   ├── application/        # Use cases and orchestration
│   ├── infrastructure/     # Adapters, persistence, external integrations
│   ├── presentation/       # Controllers and route modules
│   └── shared/             # App-specific mappers/configs
└── libs/src/               # Reusable platform layer
    ├── ddd/               # DDD kernel
    ├── core/              # Infrastructure primitives and Nest integrations
    ├── common/            # Cross-cutting runtime and reusable feature engines
    ├── shared/            # Low-level utilities, types, constants
    └── schematics/        # Feature generator templates
```

The dependency direction should be:

```text
src/presentation -> src/application -> src/domain
src/infrastructure -> src/domain
src/* -> libs/src/*
libs/src/* -X-> src/*
```

`libs/src` may depend on external packages and on other library folders, but it should not depend on application-specific code under `src/`.

## Top-Level Folder Contract

| Folder | Role | Runtime? | Primary consumers |
| --- | --- | --- | --- |
| `libs/src/ddd` | DDD kernel: entities, aggregate roots, value objects, base use cases, domain event and saga infrastructure | Yes | `src/domain`, `src/application`, `src/shared/mappers`, some `src/infrastructure` repositories |
| `libs/src/core` | Technical foundation for NestJS: database bootstrapping, messaging, transport-agnostic microservice orchestration, Redis, router, Swagger, upload, logger, i18n | Yes | Mostly `src/infrastructure`, plus bootstrap and presentation |
| `libs/src/common` | Cross-cutting runtime behavior and reusable feature engines | Yes | `src/app.module.ts`, `src/main.ts`, `src/presentation`, selected `src/application` features |
| `libs/src/shared` | Stateless helpers, DTO wrappers, constants, interfaces, enums, types | Yes | All layers when the concern is generic rather than business-specific |
| `libs/src/schematics` | Code generation templates for new features | No | Humans and tooling only |

## Alias Meaning

The primary source uses the library through alias-style imports. In practice, these aliases define the intended contract:

| Alias family | Meaning | Current role in `src/` |
| --- | --- | --- |
| `@ddd/*` | Architecture kernel | Most application use cases extend `BaseCommand` or `BaseQuery`; domain entities extend DDD base classes; repositories and mappers build on DDD infrastructure |
| `@core/*` | Configurable technical adapters and transport orchestration | Presentation routing and Swagger, bootstrap logger and websocket adapter, infrastructure persistence/messaging/upload/telegram integration, and manager-based messaging config abstractions |
| `@common/*` | Cross-cutting policies and reusable feature modules | Exception model, transform interceptors, middleware, import/report/stream engines, asset-backed editors |
| `@shared/*` | Generic helpers and shared type contracts | Utility functions, request context helpers, response DTOs, microservice types |

## Detailed Folder Specification

### `libs/src/ddd`

This folder is the architecture backbone.

#### Responsibilities

- Provide base classes for use cases.
- Provide base classes for entities, aggregate roots, value objects, and unique IDs.
- Provide repository and mapper bases for DDD-oriented persistence.
- Provide domain event publishing infrastructure.
- Provide saga orchestration infrastructure for distributed transactions.

#### Internal areas

| Path | Role |
| --- | --- |
| `ddd/application` | `BaseCommand`, `BaseQuery`, and use-case lifecycle hooks |
| `ddd/domain` | `BaseEntity`, `BaseAggregateRoot`, `Result`, `ValueObject`, `UniqueEntityID`, domain event dispatcher |
| `ddd/infrastructure` | `BaseMapper`, `BaseRepositoryTypeORM`, domain event publisher services |
| `ddd/event-bus` | Kafka-backed event bus for domain events |
| `ddd/saga` | Saga definition, steps, manager, message parser, Kafka reply consumer base |
| `ddd/interfaces` | Contracts that decouple DDD primitives from concrete implementations |

#### How `src/` currently uses it

- `src/application/**/use-cases/*` extends `@ddd/application`.
- `src/domain/entities/*` extends `@ddd/domain` base classes and uses `@ddd/interfaces`.
- `src/shared/mappers/*` extends `@ddd/infrastructure/BaseMapper`.
- `src/infrastructure/modules/*/repositories/*` often extends `BaseRepositoryTypeORM`.
- `src/app.module.ts` imports `LibDDDModule` to enable domain event publishing.

#### Usage rule

Use `@ddd/*` for architectural mechanics, not for business rules. Business rules stay in `src/domain` and `src/application`.

### `libs/src/core`

This folder contains configurable infrastructure primitives and NestJS integration helpers.

#### Responsibilities

- Encapsulate external system clients behind reusable Nest modules.
- Provide platform-level adapters that should be configured once and reused.
- Provide transport-agnostic abstractions for describing and registering microservice configs.
- Avoid application-specific business logic.

#### Internal areas

| Path | Role |
| --- | --- |
| `core/database` | Reusable database bootstrap and TypeORM/Mongo infrastructure |
| `core/microservices` | Transport-agnostic messaging config layer: config base classes, role-aware manager, Kafka/RabbitMQ adapters |
| `core/kafka` | Kafka client registration and publishing/consuming infrastructure |
| `core/rabbitmq` | RabbitMQ module registration and client infrastructure |
| `core/redis` | Redis client registration, proxy, decorators, websocket adapter |
| `core/router` | Thin wrapper around Nest router registration |
| `core/swagger` | Swagger decorators, response wrappers, setup adapter, swagger asset support |
| `core/logger` | Logging factories and transport composition |
| `core/i18n` | Global i18n setup |
| `core/bot` | Telegram bot client module and tokens |
| `core/upload` | S3 upload module and scoped upload services |
| `core/async-local-storage` | Request context propagation |
| `core/http`, `core/events`, `core/health`, `core/sse`, `core/trace-monitoring`, `core/bullmq` | Specialized technical utilities |

#### How `src/` should use it

- Configure `@core/*` inside infrastructure modules or application bootstrap.
- Do not put product-specific logic into `libs/src/core`.
- Prefer wrapping a core module with an app-specific infrastructure module when environment variables, tokens, or domain ports are involved.

#### Messaging flow in `core/microservices`

`core/microservices` is a transport-agnostic orchestration layer that sits above transport contracts and below concrete transport runtime modules.

The intended flow is:

1. `shared/types/microservice.type.ts` defines the canonical transport value shapes for Kafka and RabbitMQ.
2. `AbstractMicroserviceConfig` owns transport identity, service name, and auto-prefixed `events`, `messages`, and optional `topics`.
3. `AbstractKafkaConfig` and `AbstractRabbitMQConfig` turn that metadata into transport-specific runtime definitions.
4. `MicroserviceManager` registers each config with one or both roles: `client` and `consumer`.
5. `KafkaTransportAdapter` and `RabbitMQTransportAdapter` read the manager state to:
   - generate async client module options
   - bootstrap Nest microservice consumers
6. `LibKafkaModule` and `LibRabbitMQModule` remain the concrete runtime modules that receive those definitions.

This separates concerns cleanly:

- config classes describe messaging topology and patterns
- the manager owns registration state
- transport adapters convert generic metadata into Nest runtime wiring
- transport modules still own the final client proxy and server strategy setup

Current codebase status:

- `core/microservices` is implemented and covered by unit tests under `libs/src/core/microservices/__tests__`
- `LibKafkaModule` and `LibRabbitMQModule` still expose direct `register` and `registerAsync` APIs
- because of that, the repo is currently in a transition state where legacy direct transport registration and the newer manager/adapters layer coexist

Usage rule:

- when adding or refactoring messaging infrastructure, prefer `@core/microservices` as the source of truth for config metadata
- keep transport-specific runtime details in `@core/kafka` and `@core/rabbitmq`, not in the manager

### `libs/src/common`

This folder contains cross-cutting behavior and reusable feature engines.

#### Responsibilities

- Standardize errors, transform behavior, middleware, guards, validators, and pipes.
- Provide reusable mini-products or engines that the app can expose directly.
- Provide asset-backed developer tools or admin utilities.

#### Internal areas

| Path | Role |
| --- | --- |
| `common/exceptions` | Base exceptions, handlers, interceptor, filters, error codes |
| `common/transform` | Response wrapping and tracing/Sentry-aware interceptors |
| `common/middleware` | Request context and body/params merging middleware |
| `common/modules/report` | Report engine, queueing, plugins, report editor |
| `common/modules/import-engine` | Background import engine, processors, progress, streaming pipeline integration |
| `common/modules/stream-pipeline` | Stream processing utilities and services |
| `common/modules/formula-engine` | Formula parsing/evaluation engine with asset-backed UI |
| `common/modules/transform-editor` | Asset-backed transform editor module |
| `common/modules/dynamic-api-editor` | Asset-backed dynamic API editor module |
| `common/modules/ddd-viewer` | Asset-backed DDD viewer module |
| `common/modules/assets-base` | Common asset copy/setup behavior for asset-backed modules |
| `common/modules/auth` | Shared auth helpers and guard strategy infrastructure |
| `common/modules/pdf`, `json-rule-engine`, `redis-manager`, `yaml-to-json` | Specialized reusable modules |

#### Usage rule

If a capability is generic and reusable but larger than a helper, it belongs in `common`. If it is purely technical plumbing, it belongs in `core`. If it is business-specific, it belongs in `src/`.

### `libs/src/shared`

This folder is the low-level toolbox.

#### Responsibilities

- Hold stateless helpers and generic contracts.
- Stay lightweight and avoid business knowledge.
- Be safe to import from many layers.

#### Internal areas

| Path | Role |
| --- | --- |
| `shared/utils` | Utility functions for strings, dates, cryptography, streams, env loading, logging helpers |
| `shared/types` | Shared type aliases, global declarations, and canonical transport value contracts used by `core/microservices` |
| `shared/interfaces` | Generic interfaces |
| `shared/dto` | Generic API response DTOs and wrappers |
| `shared/constants` | Cross-cutting constants |
| `shared/enum` | Cross-cutting enums |
| `shared/helpers` | Generic helper functions |

#### Usage rule

`shared` should remain generic. If a helper only makes sense for the data visualizer domain, it should live under `src/`, not `libs/src/shared`.

### `libs/src/schematics`

This folder exists to generate new feature scaffolding.

#### Responsibilities

- Provide templates for new feature slices.
- Reinforce the intended 4-layer architecture.

#### Usage rule

Do not import schematics at runtime. Treat them as authoring tools only.

## Key Reusable Modules and Packages Relevant to the Primary Source

The entries below are the reusable modules and runtime packages that matter most to the primary app and its infrastructure assembly.

| Module | Library path | Current primary usage | Role |
| --- | --- | --- | --- |
| `LibDDDModule` | `libs/src/ddd/ddd.module.ts` | `src/app.module.ts` | Enables DDD event publishing and the event bus integration |
| `LibI18nModule` | `libs/src/core/i18n/i18n.module.ts` | `src/app.module.ts` | Global i18n bootstrap |
| `LibReportModule` | `libs/src/common/modules/report/report.module.ts` | `src/app.module.ts` | Report engine with queueing, editor, stream integration, and export plugins |
| `LibRouterModule` | `libs/src/core/router/router.module.ts` | `src/presentation/presentation.module.ts`, `src/presentation/portal/portal.module.ts` | Registers route trees and extracts their modules automatically |
| `LibTypeormModule` | `libs/src/core/database/typeorm/typeorm.module.ts` | `src/infrastructure/persistence/typeorm/typeorm.module.ts` | Shared TypeORM bootstrap plus SQL script loading |
| `MicroserviceManager` + transport adapters | `libs/src/core/microservices` | Intended for `src/infrastructure/messaging/*` and bootstrap composition | Single source of truth for messaging config metadata, role registration, and adapter-driven Kafka/RabbitMQ bootstrap |
| `LibUploadS3Module` | `libs/src/core/upload/s3/upload-s3.module.ts` | `src/infrastructure/storage/storage-infrastructure.module.ts` | Scoped S3 clients and upload adapters |
| `LibTelegramModule` | `libs/src/core/bot/telegram/telegram.module.ts` | `src/infrastructure/telegram/telegram.module.ts` | Configured Telegram service instances |
| `LibKafkaModule` | `libs/src/core/kafka/kafka.module.ts` | `src/infrastructure/messaging/kafka/kafka.module.ts` | Kafka client registration and consumer runtime module; can be fed directly or via `KafkaTransportAdapter` |
| `LibRabbitMQModule` | `libs/src/core/rabbitmq/rabbitmq.module.ts` | `src/infrastructure/messaging/rabbitmq/rabbitmq.module.ts` | RabbitMQ client registration and consumer runtime module; can be fed directly or via `RabbitMQTransportAdapter` |
| `LibRedisModule` | `libs/src/core/redis/redis.module.ts` | `src/infrastructure/redis/redis.module.ts` | Redis client registration |
| `RedisIoAdapter` | `libs/src/core/redis` | `src/main.ts` | WebSocket adapter backed by Redis |
| `SwaggerServiceAdapter` | `libs/src/core/swagger/swagger-service.adapter.ts` | `src/main.ts` | Swagger document mounting and asset serving |
| `BaseAssetsModule` | `libs/src/common/modules/assets-base/assets-base.module.ts` | `src/main.ts` | Copies and serves assets for editor/viewer modules |
| `LibFormulaEngineModule` | `libs/src/common/modules/formula-engine/formula-engine.module.ts` | `src/presentation/presentation.module.ts` | Formula engine routes plus editor assets |
| `LibTransformEditorModule` | `libs/src/common/modules/transform-editor/transform-editor.module.ts` | `src/presentation/presentation.module.ts` | Transform editor routes plus assets |
| `DynamicApiEditorModule` | `libs/src/common/modules/dynamic-api-editor/dynamic-api-editor.module.ts` | `src/presentation/presentation.module.ts` | Dynamic API editor routes plus assets |
| `LibDddViewerModule` | `libs/src/common/modules/ddd-viewer/ddd-viewer.module.ts` | `src/presentation/presentation.module.ts` | DDD viewer routes plus assets |
| `ImportEngineModule` | `libs/src/common/modules/import-engine/import-engine.module.ts` | `src/application/import/import.module.ts` | Shared import workflow engine |
| `LibStreamPipelineModule` | `libs/src/common/modules/stream-pipeline/stream-pipeline.module.ts` | `src/presentation/portal/table-editor/table-editor.module.ts` and internally by report/import modules | Shared stream processing services |

## Canonical Usage Patterns in the Primary Source

### 1. Bootstrap pattern

Global library behavior belongs in the composition roots:

- `src/app.module.ts` imports global modules and global interceptors.
- `src/main.ts` configures logger, Swagger, websocket adapter, validation pipe, and asset setup.

Use this pattern for features that must affect the whole application.

### 2. Presentation routing pattern

Feature route trees are defined in presentation modules and registered through `LibRouterModule.register(...)`.

This pattern is used in:

- `src/presentation/presentation.module.ts`
- `src/presentation/portal/portal.module.ts`

Use this when the app wants declarative route trees without manually duplicating route-module wiring.

### 3. Controller documentation pattern

Controllers in `src/presentation/**/controllers/*` use `@core/swagger` decorators such as:

- `SwaggerApiTags`
- `SwaggerApiResponse`
- `SwaggerApiListResponse`
- `SwaggerApiCreatedResponse`
- `SwaggerApiUploadFile`

This keeps response docs consistent with the shared response envelope generated by the transform interceptor.

### 4. Use case lifecycle pattern

Use cases typically extend:

- `BaseCommand<IRequest, IResponse>`
- `BaseQuery<IRequest, IResponse>`

Controllers should call:

- `executeWithHooks(...)` for commands
- `queryWithHooks(...)` for queries

This keeps validation, before/after hooks, and error logging centralized.

### 5. Repository + mapper pattern

DDD-oriented repositories under `src/infrastructure/modules/*/repositories/*` usually:

1. Extend `BaseRepositoryTypeORM<DomainEntity, OrmEntity>`.
2. Use a mapper extending `BaseMapper<DomainEntity, OrmEntity>`.
3. Convert ORM entities into domain aggregates.
4. Dispatch domain events after save when the aggregate uses them.

This keeps persistence isolated from domain entities while preserving aggregate semantics.

### 6. Infrastructure wrapper pattern

Primary source infrastructure modules should wrap configurable core modules instead of using them directly everywhere.

Examples:

- `StorageInfrastructureModule` wraps `LibUploadS3Module.registerAsync(...)`.
- `TelegramModule` wraps `LibTelegramModule.registerAsync(...)`.
- `TypeOrmInfrastructureModule` wraps `LibTypeormModule.forRootAsync(...)`.
- `KafkaInfrastructureModule` wraps `LibKafkaModule.registerAsync(...)`.
- `RedisInfrastructureModule` wraps `LibRedisModule.registerAsync(...)`.

This is the preferred integration style because it localizes config, tokens, and domain-port bindings.

### 7. Messaging manager pattern

For Kafka and RabbitMQ, the preferred long-term flow is:

1. Define one class per logical transport config by extending `AbstractKafkaConfig` or `AbstractRabbitMQConfig`.
2. Register each config instance into one `MicroserviceManager` with role `client`, `consumer`, or both.
3. Use `KafkaTransportAdapter.createClientModuleOptions(manager)` or `RabbitMQTransportAdapter.createClientModuleOptions(manager)` to derive `registerAsync(...)` input for the transport module.
4. Use `bootstrapConsumers(app, manager)` during app bootstrap to connect consumer transports.
5. Use the config instance itself as the canonical source of prefixed patterns such as `config.events.CREATE` or `config.messages.ECHO`.

Benefits:

- removes manual pattern prefix duplication
- centralizes messaging registration state
- keeps transport-specific runtime behavior out of generic orchestration code

Important constraint:

- `MicroserviceManager` should remain transport-agnostic
- transport modules, client proxies, consumer strategies, retry behavior, and ack/offset semantics stay in `@core/kafka` and `@core/rabbitmq`

### 8. Asset-backed module pattern

Several reusable modules extend `BaseAssetsModule`.

That means:

- the Nest module exposes routes/controllers
- the module also ships public assets and view templates
- `BaseAssetsModule.setupAssets(app)` in `src/main.ts` is required so those assets become available at runtime

Use this pattern for admin tools, editors, or mini-UIs shipped inside the backend.

## Layer-by-Layer Rules for `src/`

### `src/domain`

Allowed library dependencies:

- `@ddd/domain`
- `@ddd/interfaces`
- selected generic `@shared/*` types if strictly generic

Not allowed by guideline for pure domain model code:

- `@nestjs/*`
- `@core/*`
- `@common/modules/*`
- concrete infrastructure adapters

Reason:

Domain code should express business meaning, not transport, framework, or runtime configuration.

Exception:

- a thin Nest module such as `src/domain/**/customer.module.ts` is acceptable as a registration artifact
- that module should remain empty of business logic and should not become a hidden application layer

### `src/application`

Allowed library dependencies:

- `@ddd/application`
- `@common/exceptions`
- selected `@common/modules/*` only when the feature is intentionally orchestrating a reusable engine
- selected `@shared/*`

Use this layer for:

- request validation and orchestration
- use-case flow
- business-level interaction with domain ports

Avoid in this layer:

- direct configuration of Kafka, Redis, TypeORM, S3, Swagger, or routing

### `src/infrastructure`

Allowed library dependencies:

- `@core/*`
- `@core/microservices`
- `@ddd/infrastructure`
- `@shared/*`
- selected `@common/*` if needed for cross-cutting runtime behavior

Use this layer for:

- implementing domain ports
- configuring external services
- wrapping library dynamic modules with app config
- registering messaging configs and adapting them into transport modules

This is the correct place for `registerAsync(...)` calls.

### `src/presentation`

Allowed library dependencies:

- `@core/router`
- `@core/swagger`
- selected `@common/modules/*`
- selected `@common/transform` indirectly through global interceptors

Use this layer for:

- controllers
- route aggregation
- DTO translation
- auth/interceptor application

Do not put business logic here.

### `src/app.module.ts` and `src/main.ts`

This is the only place that should assemble cross-feature global library behavior.

Use it for:

- global config
- global interceptors
- microservice consumer bootstrap via transport adapters when using `@core/microservices`
- asset setup
- websocket adapters
- Swagger setup
- app-wide library modules

## Guidance for Adding a New Primary-Source Feature

When adding a new feature under `src/`, follow this sequence:

1. Define the business concepts in `src/domain/<feature>`.
2. Implement use cases in `src/application/<feature>` by extending `BaseCommand` and `BaseQuery`.
3. If persistence is needed, add ORM entities and repositories in `src/infrastructure/modules/<feature>`.
4. Add mappers in `src/shared/mappers` or another app-specific shared location.
5. Add controllers and a presentation module in `src/presentation/portal/<feature>`.
6. Register routes through `LibRouterModule.register(...)`.
7. Only add code to `libs/src` if the concern is reusable beyond this single feature.

## Decision Rules: When Code Belongs in `libs/src` vs `src/`

Put code in `libs/src` when all of the following are true:

- it is generic or reusable across multiple product features
- it is not specific to the data visualizer domain
- it can be described as platform capability, architecture support, or cross-cutting runtime behavior

Keep code in `src/` when any of the following are true:

- it encodes domain vocabulary such as database connections, table editor, settings, logs, or semantic models
- it depends on app-specific entities, repositories, or ports
- it exists to serve the data visualizer product rather than a reusable platform concern

## What Each Major Library Area Should Not Do

### `ddd`

- Should not contain product-specific entities from `src/domain`.
- Should not contain controller or Swagger concerns.

### `core`

- Should not contain business rules.
- Should not depend on application-specific repositories or entities.

### `common`

- Should not become a dumping ground for arbitrary app logic.
- Should only host cross-cutting or reusable feature engines.

### `shared`

- Should not hide business logic under “utils”.
- Should not accumulate framework-heavy modules.

### `schematics`

- Should not be imported from runtime code.

## Current Observations and Important Notes

### 1. `libs/README.md` is not authoritative

`examples/nestjs-sample/libs/README.md` is still the generic Nest starter README. It does not describe the actual library structure or the sample app's usage.

This specification should be treated as the authoritative guide for the current sample architecture.

### 2. Event bus usage depends on messaging being configured

`libs/src/ddd/event-bus/event-bus.module.ts` documents that Kafka infrastructure must exist when the DDD event bus is used.

Practical rule:

- if a feature raises domain events that must go through Kafka, ensure messaging infrastructure is configured as part of the app composition
- keep domain event logic behind `LibDDDModule` and infrastructure messaging modules, not inside feature controllers

### 3. Messaging is now split into two layers

The new messaging architecture has two distinct layers:

- `libs/src/core/microservices`: config metadata, role registration, and transport adapters
- `libs/src/core/kafka` and `libs/src/core/rabbitmq`: concrete transport runtime modules and client/server implementations

Practical rule:

- use `core/microservices` to model and register messaging topology
- use `core/kafka` and `core/rabbitmq` to execute that topology in Nest runtime

### 4. The messaging stack is in transition

The library now contains the manager/adapters abstraction, but the transport modules still keep direct registration APIs.

Practical consequence:

- old direct transport registration is still technically available
- new work should prefer the manager/adapters flow
- documentation must not claim that the whole runtime has already consolidated onto one path unless the infrastructure wiring is also migrated

### 5. Prefer one integration style per reusable engine

Some reusable engines expose framework-level registration helpers such as `forRootAsync(...)` and `forFeature(...)`.

Primary-source guidance:

- use the engine’s registration API when it cleanly matches the feature
- if the feature needs app-specific factory logic, wrap the engine in an app module rather than modifying library internals

## Normative Summary

If there is uncertainty, use this priority order:

1. Business code belongs in `src/`.
2. Reusable architecture mechanics belong in `libs/src/ddd`.
3. Reusable technical plumbing belongs in `libs/src/core`.
4. Reusable cross-cutting runtime or feature engines belong in `libs/src/common`.
5. Stateless generic helpers belong in `libs/src/shared`.
6. Code generation belongs in `libs/src/schematics`.

That separation is the intended contract for the NestJS sample.
