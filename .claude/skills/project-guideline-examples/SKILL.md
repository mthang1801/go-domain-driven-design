---
name: project-guideline-examples
description: Project Organization Example (NestJS)
---
# Project Organization Example (NestJS)

## Muc Luc

1. [Tong quan](#tong-quan)
2. [Entry point](#entry-point)
3. [Domain layer](#domain-layer)
4. [Application layer](#application-layer)
5. [Infrastructure layer](#infrastructure-layer)
6. [Presentation layer](#presentation-layer)
7. [Best practices](#best-practices)

## Tong quan

Tai lieu nay mo ta cach to chuc code theo NestJS, bam sat cau truc trong project hien tai.
Su dung pattern: Presentation -> Application -> Domain -> Infrastructure.

## Entry point

`src/main.ts` la diem khoi dong ung dung:

- init app, config, swagger
- connect microservices (Kafka/RabbitMQ)
- start HTTP server

```ts
// src/main.ts
async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule, { logger });
  kafkaRegistry.initConsumersApplication(app);
  rabbitMQRegistry.initConsumersApplication(app);
  await app.startAllMicroservices();
  await app.listen(configService.get<number>('PORT'));
}
```

## Domain layer

**Muc dich:** logic nghiep vu thuần, khong phu thuoc framework.

```
src/domain/
  order/
    entities/
    value-objects/
    events/
    services/
    factories/
    policies/
```

Vi du entity (domain):

```ts
// src/domain/order/entities/order.entity.ts
export class OrderEntity {
  constructor(private readonly id: string) {}
}
```

## Application layer

**Muc dich:** orchestration use-case, xu ly sagas/services/policies theo tung module.

```
src/application/
  order/
    use-cases/
    sagas/
    services/
    policies/
    events/
```

Use-case ke thua `BaseCommand`/`BaseQuery` tu `libs/src/ddd/application`:

```ts
// src/application/order/use-cases/create-order.use-case.ts
export class CreateOrderUseCase extends BaseCommand<CreateOrderInput, Order> {
  async execute(request: CreateOrderInput) {
    // orchestration logic
  }
}
```

## Infrastructure layer

**Muc dich:** adapter cho database, messaging, cache, HTTP client, etc.

```
src/infrastructure/
  persistence/
  event-store/
  redis/
  http/
  resilience/
  rabbitmq/
  messaging/kafka/
```

Vi du kafka subscriber:

```ts
// src/infrastructure/messaging/kafka/subscribers/portal.subscriber.ts
@SubscribeMessagePattern('PortalKafka.ECHO')
async handleEcho(@Payload() data: any, @Ctx() ctx: KafkaContext) {
  return { ok: true, data };
}
```

## Presentation layer

**Muc dich:** REST/WebSocket entry, DTO validation.

```
src/presentation/portal/
  order/
    controllers/
    subscribers/
    dtos/
```

Vi du controller:

```ts
// src/presentation/portal/kafka/kafka.controller.ts
@Post('send')
async send(@Body() payload: KafkaSendPayload) {
  return this.kafkaService.send('PortalKafka.ECHO', payload.data);
}
```

## Best practices

- Moi folder nen co `index.ts` lam barrel export.
- Domain khong phu thuoc NestJS, khong su dung decorator.
- Application layer chi orchestration, use-case ke thua `BaseCommand`/`BaseQuery`.
- Infrastructure layer implement cac port/service ben ngoai.
- Presentation layer chi mapping request/response va validate DTO.

## Core DDD (libs/src/ddd)

- `LibDDDModule` khoi tao Domain Event Dispatcher.
- `BaseAggregateRoot`, `BaseEntity`, `ValueObject`.
- `BaseCommand`/`BaseQuery` cho use-case lifecycle.
- `BaseRepositoryTypeORM` cho mapping Domain <-> ORM va dispatch events.

# Complete Integration Example

## 🎯 Tổng quan

Event Bus được tích hợp vào **TẤT CẢ** các patterns:

1. Domain Events → Event Bus
2. Saga → Subscribe qua Event Bus
3. Projections (CQRS) → Subscribe qua Event Bus
4. Event Sourcing → Publish qua Event Bus

## 📊 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                               │
│  ┌──────────────────────┐         ┌──────────────────────┐         │
│  │ Order Command        │         │ Order Query          │         │
│  │ Controller (Write)   │         │ Controller (Read)    │         │
│  └──────────┬───────────┘         └────────────┬─────────┘         │
└─────────────┼──────────────────────────────────┼───────────────────┘
              │                                   │
┌─────────────▼───────────────────────────────────▼───────────────────┐
│                    APPLICATION LAYER                                │
│  ┌──────────────────────┐         ┌──────────────────────┐         │
│  │ Use Cases            │         │ Query Services       │         │
│  │ - CreateOrder        │         │ - GetOrder           │         │
│  │ - PayOrder           │         │ - SearchOrders       │         │
│  │ - CancelOrder        │         └──────────────────────┘         │
│  └──────────┬───────────┘                                           │
└─────────────┼───────────────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                                   │
│  ┌──────────────────────────────────────────────────────┐          │
│  │ Order Aggregate (Event Sourced)                      │          │
│  │  - order.confirm() → OrderConfirmedEvent             │          │
│  │  - order.pay() → OrderPaidEvent                      │          │
│  │  - order.ship() → OrderShippedEvent                  │          │
│  │  - order.cancel() → OrderCancelledEvent              │          │
│  └──────────┬───────────────────────────────────────────┘          │
│             │ addDomainEvent()                                      │
│             │                                                       │
│  ┌──────────▼───────────────────────────────────────────┐          │
│  │ Domain Event Manager                                 │          │
│  │  - markAggregateForDispatch()                        │          │
│  │  - dispatchEventsForAggregate()                      │          │
│  └──────────┬───────────────────────────────────────────┘          │
└─────────────┼───────────────────────────────────────────────────────┘
              │ publishAll()
              │
┌─────────────▼───────────────────────────────────────────────────────┐
│                         EVENT BUS                                   │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              In-Memory / RabbitMQ / Kafka                    │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │  │
│  │  │ QUEUE      │ │ RETRY      │ │ PRIORITY   │              │  │
│  │  │ - Buffer   │ │ - Expo     │ │ - High:100 │              │  │
│  │  │ - FIFO     │ │ - Linear   │ │ - Med: 50  │              │  │
│  │  │            │ │ - 3-5x     │ │ - Low: 10  │              │  │
│  │  └────────────┘ └────────────┘ └────────────┘              │  │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │  │
│  │  │ FILTER     │ │ IDEMPOTENT │ │ DEAD       │              │  │
│  │  │ - Amount   │ │ - Check    │ │ LETTER     │              │  │
│  │  │ - Customer │ │ - Skip dup │ │ QUEUE      │              │  │
│  │  └────────────┘ └────────────┘ └────────────┘              │  │
│  └──────────────────────────────────────────────────────────────┘  │
└──────┬────────────────┬────────────────┬─────────────────┬─────────┘
       │                │                │                 │
       │ Priority:100   │ Priority:90    │ Priority:50     │ Priority:10
       │                │                │                 │
┌──────▼──────┐  ┌──────▼──────┐  ┌─────▼────────┐  ┌────▼─────────┐
│ Email       │  │ SAGA        │  │ Analytics    │  │ Marketing    │
│ Handler     │  │ Orchestrator│  │ Handler      │  │ Handler      │
│             │  │             │  │              │  │              │
│ Critical!   │  │ Placement   │  │ High-value   │  │ New customer │
│ 5 retries   │  │ Fulfillment │  │ orders only  │  │ only         │
│ Idempotent  │  │ Cleanup     │  │ 3 retries    │  │ 2 retries    │
└─────────────┘  └──────┬──────┘  └──────────────┘  └──────────────┘
                        │
                 ┌──────▼──────┐
                 │ Projection  │
                 │ Read Model  │
                 │ Update      │
                 │             │
                 │ 5 retries   │
                 │ Idempotent  │
                 └─────────────┘
```

## 🔄 Complete Order Flow với Event Bus

### Step 1: Create Order

```
User → CreateOrderUseCase
  ↓
OrderFactory.createFromCart()
  ↓ (Domain Services)
PricingService.calculateDiscount()
InventoryService.checkAvailability()
  ↓
Order.create() → OrderCreatedEvent
  ↓
OrderEventSourcedRepository.save()
  ↓
EventStore.appendEvents()
  ↓
EVENT BUS.publishAll([OrderCreatedEvent])
  ↓
┌─────────────────────────────────────────────────┐
│ Event Bus Queue                                 │
│ [OrderCreatedEvent] → Process in priority order │
└─────────────────────────────────────────────────┘
  ↓
Parallel Processing (Non-blocking!):
├─→ [P:100] OrderCreatedEmailHandler (5 retries, idempotent)
│     → Send confirmation email
├─→ [P:90]  OrderPlacementSaga (3 retries, idempotent)
│     → Reserve inventory
│     → Confirm order
│     → Create payment intent
├─→ [P:80]  OrderReadModelProjection (5 retries, idempotent)
│     → Create read model entry
├─→ [P:50]  OrderCreatedAnalyticsHandler (3 retries, filtered)
│     → Record analytics (if amount > $100)
└─→ [P:10]  OrderCreatedMarketingHandler (2 retries, filtered)
      → Send welcome offer (if new customer)
```

### Step 2: Pay Order

```
User → PayOrderUseCase
  ↓
Load Order from Event Store
  ↓
order.pay(paymentMethod) → Double Dispatch
  ├─→ CreditCardPayment.processPayment()
  │     → Stripe Gateway
  ├─→ PayPalPayment.processPayment()
  │     → PayPal API
  └─→ WalletPayment.processPayment()
        → Check balance, deduct
  ↓
OrderPaidEvent raised
  ↓
OrderEventSourcedRepository.save()
  ↓
EVENT BUS.publishAll([OrderPaidEvent])
  ↓
Parallel Processing:
├─→ [P:90] OrderPlacementSaga.handleOrderPaid()
│     → Commit inventory
│     → Create shipment
│     → Update tracking
├─→ [P:80] OrderReadModelProjection.onOrderPaid()
│     → Update read model: status = PAID
├─→ [P:50] PaymentAnalyticsHandler
│     → Record revenue
└─→ [P:10] PaymentMarketingHandler
      → Upsell recommendations
```

### Step 3: Cancel Order

```
User → CancelOrderUseCase
  ↓
Load Order, Load Customer
  ↓
Select Policy (Policy Pattern):
  ├─→ StandardCancellationPolicy (if normal customer)
  └─→ PremiumCancellationPolicy (if VIP)
  ↓
order.cancel(policy, reason)
  → Calculate cancellation fee
  → OrderCancelledEvent
  ↓
EVENT BUS.publishAll([OrderCancelledEvent])
  ↓
Parallel Processing:
├─→ [P:95] OrderPlacementSaga.handleOrderCancelled() (CRITICAL!)
│     → Release inventory
│     → Process refund
│     → Cancel shipment
├─→ [P:80] OrderReadModelProjection.onOrderCancelled()
│     → Update read model: status = CANCELLED
└─→ [P:50] CancellationAnalyticsHandler
      → Track cancellation reasons
```

## 🎯 Event Bus Benefits trong E-commerce

### 1. Reliability (Retry Mechanism)

```typescript
// Email handler fails? → Event Bus retries automatically
OrderCreatedEmailHandler
  - Attempt 1: Failed (email service down)
  - Wait 1s
  - Attempt 2: Failed
  - Wait 2s (exponential backoff)
  - Attempt 3: Success ✅
  
// Without Event Bus: Email lost, customer không nhận confirmation!
```

### 2. Priority Processing

```typescript
// Critical handlers processed first
[P:100] Email Handler      → 🚀 Processed immediately
[P:90]  Saga Orchestrator  → 🚀 Processed next
[P:50]  Analytics          → ⏳ Processed when free
[P:10]  Marketing          → ⏳ Processed last

// Ensures critical operations complete first
```

### 3. Idempotency

```typescript
// Event processed twice? → Event Bus skips duplicate
OrderCreatedEvent (orderId: 123)
  - 1st time: Process ✅
  - 2nd time: Skip (already processed) ⏭️

// Prevents: Duplicate emails, double charging, etc.
```

### 4. Filtering

```typescript
// Only process relevant events
AnalyticsHandler {
  filter: (event) => event.totalAmount > 100
}
// Orders < $100: ⏭️ Skipped
// Orders > $100: ✅ Processed

// Saves resources, improves performance
```

### 5. Dead Letter Queue

```typescript
// Handler fails 5 times → Send to DLQ
OrderCreatedEmailHandler
  - Attempt 1-5: All failed ❌
  - Move to Dead Letter Queue 💀
  - Alert operations team 🚨
  - Manual intervention required

// Prevents: Silent failures, data loss
```

## 📊 Monitoring & Metrics

```typescript
Event Bus Statistics:
┌────────────────────────────────────┐
│ Queue Length: 23                   │
│ Handler Count: 15                  │
│ Processed Count: 10,523            │
│ Success Rate: 98.5%                │
│ Average Processing Time: 145ms     │
│ Dead Letter Queue: 3 items         │
└────────────────────────────────────┘

Alerts:
⚠️ Queue length > 100 → Scale handlers
⚠️ Success rate < 95% → Investigate failures
🚨 DLQ growing → Manual intervention needed
```

## 🔧 Configuration Examples

### Development (Simple)

```yaml
EVENT_BUS_TYPE=in-memory
EVENT_BUS_RETRY_MAX_ATTEMPTS=3
EVENT_BUS_QUEUE_SIZE=1000
```

### Production (Reliable)

```yaml
EVENT_BUS_TYPE=rabbitmq
RABBITMQ_URL=amqp://user:pass@rabbitmq:5672
EVENT_BUS_RETRY_MAX_ATTEMPTS=5
EVENT_BUS_ENABLE_DLQ=true
EVENT_BUS_ENABLE_MONITORING=true
EVENT_BUS_MAX_CONCURRENT_HANDLERS=100
```

## ✅ Summary

### Before Event Bus

```
Order.create() → OrderCreatedEvent
  ↓
EventEmitter2.emit() (synchronous, no retry)
  ↓
Handler fails? → Event lost! ❌
```

### With Event Bus

```
Order.create() → OrderCreatedEvent
  ↓
EVENT BUS.publishAll() (async, queued)
  ↓
Queue → Retry → Priority → Filter → Idempotency
  ↓
Handler fails? → Retry 5 times ✅
Still fails? → Dead Letter Queue → Alert team 🚨
```

### Key Improvements

| Feature     | Without Event Bus | With Event Bus       |
| ----------- | ----------------- | -------------------- |
| Retry       | ❌                | ✅ (3-5 attempts)    |
| Priority    | ❌                | ✅ (Critical first)  |
| Idempotency | ❌                | ✅ (No duplicates)   |
| Filtering   | ❌                | ✅ (Skip irrelevant) |
| DLQ         | ❌                | ✅ (Manual review)   |
| Monitoring  | ❌                | ✅ (Full visibility) |
| Reliability | ⭐                | ⭐⭐⭐⭐⭐           |

## 🎓 Next Steps

1. **Start with In-Memory Event Bus** → No infrastructure needed
2. **Add monitoring** → Track queue length, success rates
3. **Configure retries** → Based on handler criticality
4. **Set up alerts** → For queue growth, failures
5. **Migrate to RabbitMQ** → When scaling to multiple instances

---

 **Result** : Hệ thống E-commerce robust, reliable, scalable với Event Bus! 🚀
