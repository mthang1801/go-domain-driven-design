# Package Organization voi DDD va Event Bus (NestJS)

## Tong Quan Cau Truc

```
domain-driven-design/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── domain/
│   │   ├── order/
│   │   │   ├── entities/
│   │   │   ├── value-objects/
│   │   │   ├── events/
│   │   │   ├── services/
│   │   │   ├── factories/
│   │   │   └── policies/
│   │   └── payment/
│   │       └── entities/
│   ├── application/
│   │   ├── order/
│   │   │   ├── use-cases/
│   │   │   ├── sagas/
│   │   │   ├── services/
│   │   │   ├── policies/
│   │   │   └── events/
│   ├── infrastructure/
│   │   ├── persistence/
│   │   ├── event-store/
│   │   ├── redis/
│   │   ├── http/
│   │   ├── resilience/
│   │   └── rabbitmq/
│   └── presentation/
│       └── portal/
│           └── order/
│               ├── controllers/
│               ├── subscribers/
│               └── dtos/
├── libs/
│   ├── src/
│   │   ├── common/
│   │   ├── core/
│   │   ├── ddd/
│   │   ├── shared/
│   │   └── schematics/
│   ├── README.md
│   ├── LICENSE
│   ├── tsconfig.json
│   └── tsconfig.build.json
├── rules/
│   ├── structure.md
│   ├── project-organization-example-guide.md
│   └── project-organize-example-summary.md
└── package.json
```

## Chi Tiet Tung Package

### src/
- **domain/**: logic nghiep vu thuan (entities, value objects, domain events).
- **application/**: use-cases + sagas/services/policies theo tung module.
- **infrastructure/**: adapter ket noi he thong ben ngoai (DB, messaging, HTTP, cache).
- **presentation/**: REST/WebSocket entry, DTO validation.

### libs/
- **common/**: decorators, exceptions, interceptors, modules dung chung.
- **core/**: kafka, rabbitmq, redis, health, logger, trace-monitoring, ...
- **ddd/**: core DDD (BaseAggregateRoot, BaseCommand/BaseQuery, Domain Events).
- **shared/**: constants, dto, enum, interfaces, types, utils.
- **schematics/**: generate-feature templates.

## Event Bus Architecture

- **Domain events** duoc tao trong domain layer (ke thua `BaseDomainEvents`).
- **Dispatcher** duoc khoi tao qua `LibDDDModule`.
- **Infrastructure** implement EventBus (Kafka/RabbitMQ).
- **Presentation subscribers** lang nghe event tu bus.

## Best Practices

- Moi folder nen co `index.ts` lam barrel export.
- Domain layer khong phu thuoc framework.
- Application layer chi orchestration, use-case ke thua `BaseCommand`/`BaseQuery`.
- Infrastructure layer chi lam adapter (DB, HTTP, Messaging).
- Presentation layer chi xu ly input/output va validation.

## Dependency Flow

```
Presentation -> Application -> Domain
Infrastructure -> Domain (implement ports)
Infrastructure -> Application (implement adapters)
```
