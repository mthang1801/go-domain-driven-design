
---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

---
name: summary
model: fast
---

# Tài liệu Tổng hợp
## Triển khai DDD với Clean Architecture trong NestJS

Tôi sẽ hướng dẫn bạn triển khai đầy đủ các khái niệm DDD còn thiếu và tạo base classes có thể tái sử dụng cho nhiều service.

## 1. Định nghĩa các khái niệm DDD

### Domain Events
Domain Events là các sự kiện nghiệp vụ quan trọng đã xảy ra trong domain, được sử dụng để:
- Giao tiếp giữa các Aggregate
- Kích hoạt các side effects
- Đảm bảo eventual consistency

### Aggregate Root
Aggregate Root là entity gốc của một cụm các đối tượng liên quan, chịu trách nhiệm:
- Đảm bảo tính nhất quán của toàn bộ aggregate
- Là điểm truy cập duy nhất từ bên ngoài
- Quản lý lifecycle của các entity con

### Value Object
Value Object là đối tượng không có identity, được định nghĩa bởi các thuộc tính:
- Immutable (bất biến)
- So sánh bằng giá trị, không phải reference
- Không có ID riêng

## Project Structure (with libs)

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
├── rules/
│   └── structure.md
├── package.json
├── tsconfig.json
└── README.md
```

## 1. Base Classes Library (Có thể tái sử dụng cho nhiều services)

- ✅ UniqueEntityID - Type-safe entity IDs
- ✅ BaseEntity - Base class cho entities
- ✅ BaseAggregateRoot - Quản lý domain events
- ✅ ValueObject với Result và Guard patterns
- ✅ BaseDomainEvent và DomainEvents infrastructure
- ✅ BaseRepository và BaseTypeOrmRepository
- ✅ BaseUseCase với lifecycle hooks
- ✅ BaseMapper cho data transformation
- ✅ Specification pattern
- ✅ UnitOfWork và TransactionManager

## 2. Ví dụ thực tế

- Agreement module hoàn chỉnh
- Use cases với validation
- Event handlers
- Repository implementation
- Controller integration

## 3. Advanced Patterns

- Domain Services
- Factory Pattern
- Policy Pattern
- Double Dispatch
- Saga Pattern
- Event Sourcing with CQRS

## 4. Documentation đầy đủ

- README với hướng dẫn chi tiết
- Quick Reference Cheat Sheet
- Migration Strategy từ legacy code
- Best practices và anti-patterns
- Testing strategies

## 5. Migration Guide

- 12 phases migration plan
- Feature flag strategy
- Parallel run approach
- Rollback procedures
- Metrics tracking

## 🎯 Lợi ích của kiến trúc này:

- Tái sử dụng code: Tất cả base classes trong libs/shared có thể dùng cho nhiều services
- Type Safety: Full TypeScript support
- Testability: Dễ dàng unit test với Result pattern
- Maintainability: Business logic tập trung trong domain
- Scalability: Rõ ràng về boundaries và dependencies
- Event-Driven: Loose coupling qua domain events

## 📝 Tổng kết cho bạn:

Tôi đã giải thích chi tiết 6 Advanced DDD Patterns với ví dụ thực tế:
- 1️⃣ Domain Service - ⭐ EASY
  - Là gì: Logic không thuộc về một entity
  - Ví dụ: Tính giảm giá (cần Order + Customer)
  - Code: pricingService.calculateDiscount(order, customer)
- 2️⃣ Factory - ⭐⭐ MEDIUM
  - Là gì: Tạo objects phức tạp
  - Ví dụ: Tạo Order từ Cart (validate, calculate, create)
  - Code: orderFactory.createFromCart(customerId, items, address)
- 3️⃣ Policy - ⭐⭐ MEDIUM
  - Là gì: Pluggable business rules
  - Ví dụ: Chính sách hủy đơn (VIP vs Thường)
  - Code: order.cancel(policy, reason) - policy được inject
- 4️⃣ Double Dispatch - ⭐⭐ MEDIUM
  - Là gì: Polymorphic behavior
  - Ví dụ: Payment methods (CreditCard, PayPal, Wallet)
  - Code: order.pay(paymentMethod) - tự động gọi đúng implementation
- 5️⃣ Saga - ⭐⭐⭐ HARD
  - Là gì: Distributed transactions với compensation
  - Ví dụ: Order flow (Inventory → Payment → Shipping)
  - Code: Orchestrator với compensation khi fail
- 6️⃣ Event Sourcing - ⭐⭐⭐ HARD
  - Là gì: Rebuild state từ events
  - Ví dụ: Complete audit trail của Order
  - Code: OrderEventSourced.fromHistory(id, events)

## 🎯 Khuyến nghị:

- Domain Service ✅
- Factory ✅
- Policy ✅
