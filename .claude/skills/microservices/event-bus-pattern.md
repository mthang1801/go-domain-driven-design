# Kafka Event Bus - Complete Setup Guide

## Bối cảnh 
### Sự khác biệt giữa EVENT DISPATCHER vs EVENT BUS

#### DOMAIN EVENT MANAGER (Current - Simple Dispatcher)
 * Chức năng:
 * - Đánh dấu aggregates có events
 * - Dispatch events trong process
 * - Gọi EventEmitter2 để publish
 * 
 * Hạn chế:
 * - Không có queue/buffer
 * - Không có retry mechanism
 * - Không có event filtering
 * - Không có distributed support
 * - Không có event versioning
 * - Đồng bộ, blocking

#### EVENT BUS (Advanced - Message Bus)
 * Chức năng:
 * - Queue management (in-memory or external)
 * - Retry mechanism với exponential backoff
 * - Event filtering và routing
 * - Dead letter queue
 * - Event versioning
 * - Distributed support (RabbitMQ, Kafka)
 * - Async, non-blocking
 * - Event ordering
 * - Idempotency handling

## 📦 Project Structure

```
project-root/
├── libs/
│   └── shared/
│       └── ddd/
│           ├── event-bus/
│           │   ├── interfaces/
│           │   │   └── event-bus.interface.ts
│           │   ├── kafka-event-bus.ts ✨ NEW
│           │   ├── kafka-event-bus.module.ts ✨ NEW
│           │   ├── in-memory-event-bus.ts
│           │   └── rabbitmq-event-bus.ts
│           ├── domain/
│           │   ├── base-aggregate-root.ts
│           │   ├── base-domain-event.ts
│           │   └── domain-event-manager.ts
│           ├── infrastructure/
│           │   └── domain-event-publisher-with-bus.service.ts
│           └── ddd.module.ts ✨ UPDATED
│
├── src/
│   ├── domain/
│   │   └── order/
│   │       ├── entities/
│   │       ├── events/
│   │       ├── services/
│   │       ├── factories/
│   │       └── policies/
│   ├── application/
│   │   └── order/
│   │       ├── use-cases/
│   │       ├── queries/
│   │       └── sagas/
│   │           └── order-placement-kafka.saga.ts ✨ NEW
│   ├── infrastructure/
│   │   ├── order/
│   │   │   ├── repositories/
│   │   │   ├── projections/
│   │   │   │   └── order-read-model-kafka.projection.ts ✨ NEW
│   │   │   └── events/
│   │   │       └── kafka-handlers/
│   │   │           ├── order-created.kafka-handlers.ts ✨ NEW
│   │   │           ├── order-paid.kafka-handlers.ts ✨ NEW
│   │   │           ├── order-shipped.kafka-handlers.ts ✨ NEW
│   │   │           └── order-cancelled.kafka-handlers.ts ✨ NEW
│   │   └── monitoring/
│   │       └── kafka-event-bus-monitor.service.ts ✨ NEW
│   └── presentation/
│       └── order/
│           └── controllers/
│
├── docker-compose.yml ✨ NEW
├── package.json
└── .env
```

## System với Event Bus - Complete Integration
🎯 Tổng quan
Event Bus được tích hợp vào TẤT CẢ các patterns:

Domain Events → Event Bus
Saga → Subscribe qua Event Bus
Projections (CQRS) → Subscribe qua Event Bus
Event Sourcing → Publish qua Event Bus

📊 Architecture Diagram
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
🔄 Complete Order Flow với Event Bus
Step 1: Create Order
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
Step 2: Pay Order
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
Step 3: Cancel Order
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
🎯 Event Bus Benefits trong E-commerce
1. Reliability (Retry Mechanism)
typescript// Email handler fails? → Event Bus retries automatically
OrderCreatedEmailHandler
  - Attempt 1: Failed (email service down)
  - Wait 1s
  - Attempt 2: Failed
  - Wait 2s (exponential backoff)
  - Attempt 3: Success ✅
  
// Without Event Bus: Email lost, customer không nhận confirmation!
2. Priority Processing
typescript// Critical handlers processed first
[P:100] Email Handler      → 🚀 Processed immediately
[P:90]  Saga Orchestrator  → 🚀 Processed next
[P:50]  Analytics          → ⏳ Processed when free
[P:10]  Marketing          → ⏳ Processed last

// Ensures critical operations complete first
3. Idempotency
typescript// Event processed twice? → Event Bus skips duplicate
OrderCreatedEvent (orderId: 123)
  - 1st time: Process ✅
  - 2nd time: Skip (already processed) ⏭️

// Prevents: Duplicate emails, double charging, etc.
4. Filtering
typescript// Only process relevant events
AnalyticsHandler {
  filter: (event) => event.totalAmount > 100
}
// Orders < $100: ⏭️ Skipped
// Orders > $100: ✅ Processed

// Saves resources, improves performance
5. Dead Letter Queue
typescript// Handler fails 5 times → Send to DLQ
OrderCreatedEmailHandler
  - Attempt 1-5: All failed ❌
  - Move to Dead Letter Queue 💀
  - Alert operations team 🚨
  - Manual intervention required

// Prevents: Silent failures, data loss
📊 Monitoring & Metrics
typescriptEvent Bus Statistics:
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
🔧 Configuration Examples
Development (Simple)
yamlEVENT_BUS_TYPE=in-memory
EVENT_BUS_RETRY_MAX_ATTEMPTS=3
EVENT_BUS_QUEUE_SIZE=1000
Production (Reliable)
yamlEVENT_BUS_TYPE=rabbitmq
RABBITMQ_URL=amqp://user:pass@rabbitmq:5672
EVENT_BUS_RETRY_MAX_ATTEMPTS=5
EVENT_BUS_ENABLE_DLQ=true
EVENT_BUS_ENABLE_MONITORING=true
EVENT_BUS_MAX_CONCURRENT_HANDLERS=100
✅ Summary
Before Event Bus
Order.create() → OrderCreatedEvent
  ↓
EventEmitter2.emit() (synchronous, no retry)
  ↓
Handler fails? → Event lost! ❌
With Event Bus
Order.create() → OrderCreatedEvent
  ↓
EVENT BUS.publishAll() (async, queued)
  ↓
Queue → Retry → Priority → Filter → Idempotency
  ↓
Handler fails? → Retry 5 times ✅
Still fails? → Dead Letter Queue → Alert team 🚨
Key Improvements
FeatureWithout Event BusWith Event BusRetry❌✅ (3-5 attempts)Priority❌✅ (Critical first)Idempotency❌✅ (No duplicates)Filtering❌✅ (Skip irrelevant)DLQ❌✅ (Manual review)Monitoring❌✅ (Full visibility)Reliability⭐⭐⭐⭐⭐⭐
🎓 Next Steps

Start with In-Memory Event Bus → No infrastructure needed
Add monitoring → Track queue length, success rates
Configure retries → Based on handler criticality
Set up alerts → For queue growth, failures
Migrate to RabbitMQ → When scaling to multiple instances


Result: Hệ thống E-commerce robust, reliable, scalable với Event Bus! 🚀

## 🚀 Step-by-Step Setup

### Step 1: Install Dependencies

```bash
# Install Kafka client
npm install kafkajs

# Install other required dependencies (if not installed)
npm install uuid
npm install @nestjs/config
```

### Step 2: Create Docker Compose for Kafka

```yaml
# docker-compose.yml
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    hostname: zookeeper
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    networks:
      - kafka-network

  kafka-1:
    image: confluentinc/cp-kafka:7.5.0
    hostname: kafka-1
    container_name: kafka-1
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "19092:19092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-1:9092,PLAINTEXT_HOST://localhost:19092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 2
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 2
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
    networks:
      - kafka-network

  kafka-2:
    image: confluentinc/cp-kafka:7.5.0
    hostname: kafka-2
    container_name: kafka-2
    depends_on:
      - zookeeper
    ports:
      - "9093:9093"
      - "19093:19093"
    environment:
      KAFKA_BROKER_ID: 2
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-2:9093,PLAINTEXT_HOST://localhost:19093
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 2
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 2
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
    networks:
      - kafka-network

  kafka-3:
    image: confluentinc/cp-kafka:7.5.0
    hostname: kafka-3
    container_name: kafka-3
    depends_on:
      - zookeeper
    ports:
      - "9094:9094"
      - "19094:19094"
    environment:
      KAFKA_BROKER_ID: 3
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka-3:9094,PLAINTEXT_HOST://localhost:19094
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 2
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 2
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 2
      KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS: 0
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
    networks:
      - kafka-network

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    depends_on:
      - kafka-1
      - kafka-2
      - kafka-3
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka-1:9092,kafka-2:9093,kafka-3:9094
      KAFKA_CLUSTERS_0_ZOOKEEPER: zookeeper:2181
    networks:
      - kafka-network

  postgres:
    image: postgres:15
    container_name: postgres
    environment:
      POSTGRES_DB: ecommerce
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - kafka-network

networks:
  kafka-network:
    driver: bridge

volumes:
  postgres_data:
```

### Step 3: Start Kafka Cluster

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f kafka-1

# Access Kafka UI at: http://localhost:8080
```

### Step 4: Configure Environment Variables

```bash
# .env.development
NODE_ENV=development

# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=ecommerce
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres

# Kafka Configuration
KAFKA_CLIENT_ID=ecommerce-dev
KAFKA_BROKERS=localhost:19092,localhost:19093,localhost:19094
KAFKA_GROUP_ID=ecommerce-dev-group
KAFKA_SSL=false

# Application
PORT=3000
```

```bash
# .env.production
NODE_ENV=production

# Database
DATABASE_HOST=prod-postgres.example.com
DATABASE_PORT=5432
DATABASE_NAME=ecommerce_prod
DATABASE_USER=ecommerce_user
DATABASE_PASSWORD=super-secret-password

# Kafka Configuration
KAFKA_CLIENT_ID=ecommerce-prod
KAFKA_BROKERS=kafka-1.prod:9092,kafka-2.prod:9092,kafka-3.prod:9092
KAFKA_GROUP_ID=ecommerce-prod-group
KAFKA_SSL=true
KAFKA_SASL_ENABLED=true
KAFKA_SASL_MECHANISM=scram-sha-512
KAFKA_SASL_USERNAME=ecommerce-kafka-user
KAFKA_SASL_PASSWORD=kafka-super-secret-password

# Application
PORT=3000
```

### Step 5: Update package.json

```json
{
  "name": "ecommerce-api",
  "version": "1.0.0",
  "scripts": {
    "start": "nest start",
    "start:dev": "nest start --watch",
    "start:prod": "node dist/main",
    "build": "nest build",
    "test": "jest",
    "kafka:up": "docker-compose up -d",
    "kafka:down": "docker-compose down",
    "kafka:logs": "docker-compose logs -f",
    "kafka:topics": "docker exec kafka-1 kafka-topics --list --bootstrap-server localhost:9092"
  },
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/config": "^3.0.0",
    "@nestjs/typeorm": "^10.0.0",
    "typeorm": "^0.3.0",
    "postgres": "^3.3.0",
    "kafkajs": "^2.2.4",
    "uuid": "^9.0.0",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0.0",
    "@nestjs/schematics": "^10.0.0",
    "@nestjs/testing": "^10.0.0",
    "@types/jest": "^29.5.0",
    "@types/node": "^20.0.0",
    "@types/uuid": "^9.0.0",
    "jest": "^29.5.0",
    "ts-jest": "^29.1.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  }
}
```

### Step 6: Run Application

```bash
# Start Kafka
npm run kafka:up

# Wait for Kafka to be ready (30 seconds)
sleep 30

# Run database migrations
npm run migration:run

# Start application
npm run start:dev

# Check Kafka topics created
npm run kafka:topics
```

## 📊 Kafka Topics & Partitions

After starting the application, these topics will be auto-created:

```
Topic: order.created
  Partitions: 3
  Replication: 2
  Consumers: EmailHandler, AnalyticsHandler, MarketingHandler, Saga, Projection

Topic: order.confirmed
  Partitions: 3
  Replication: 2
  Consumers: Projection

Topic: order.paid
  Partitions: 3
  Replication: 2
  Consumers: Saga, Projection, AnalyticsHandler

Topic: order.shipped
  Partitions: 3
  Replication: 2
  Consumers: Projection, NotificationHandler

Topic: order.cancelled
  Partitions: 3
  Replication: 2
  Consumers: Saga, Projection

Topic: dead-letter-queue
  Partitions: 1
  Replication: 2
  Consumers: Manual review
```

## 🧪 Testing

### Test 1: Create Order

```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "CUST-001",
    "items": [
      { "productId": "PROD-001", "quantity": 2 },
      { "productId": "PROD-002", "quantity": 1 }
    ],
    "shippingAddress": {
      "street": "123 Main St",
      "city": "Los Angeles",
      "state": "CA",
      "country": "USA",
      "zipCode": "90001"
    },
    "billingAddress": {
      "street": "123 Main St",
      "city": "Los Angeles",
      "state": "CA",
      "country": "USA",
      "zipCode": "90001"
    }
  }'
```

**Expected Kafka Flow:**

```
1. OrderCreatedEvent published to order.created topic
2. Kafka distributes to 5 consumers:
   - EmailHandler (P:100) → Sends email
   - Saga (P:90) → Reserves inventory, confirms order
   - Projection (P:80) → Updates read model
   - AnalyticsHandler (P:50) → Records metrics (if > $100)
   - MarketingHandler (P:10) → Sends offer (if new customer)
```

### Test 2: Monitor Kafka UI

1. Open http://localhost:8080
2. Navigate to Topics
3. See messages in order.created topic
4. Check consumer groups
5. Monitor lag and throughput

### Test 3: Check Logs

```bash
# Application logs
docker-compose logs -f app

# Kafka logs
docker-compose logs -f kafka-1

# Check consumer group
docker exec kafka-1 kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group ecommerce-dev-group
```

## 📈 Monitoring & Metrics

### Kafka Metrics

```bash
# Topic details
docker exec kafka-1 kafka-topics \
  --bootstrap-server localhost:9092 \
  --describe \
  --topic order.created

# Consumer lag
docker exec kafka-1 kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --describe \
  --group ecommerce-dev-group

# Message count
docker exec kafka-1 kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic order.created
```

### Application Metrics

Access application metrics at: http://localhost:3000/metrics

## 🔧 Troubleshooting

### Issue 1: Kafka not connecting

```bash
# Check if Kafka is running
docker-compose ps

# Restart Kafka
docker-compose restart kafka-1 kafka-2 kafka-3

# Check Kafka logs
docker-compose logs kafka-1
```

### Issue 2: Messages not being consumed

```bash
# Check consumer group
docker exec kafka-1 kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --list

# Reset consumer offset (development only!)
docker exec kafka-1 kafka-consumer-groups \
  --bootstrap-server localhost:9092 \
  --group ecommerce-dev-group \
  --topic order.created \
  --reset-offsets \
  --to-earliest \
  --execute
```

### Issue 3: Dead Letter Queue growing

```bash
# View DLQ messages
docker exec kafka-1 kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic dead-letter-queue \
  --from-beginning

# Manual intervention required for DLQ messages
```

## 🚀 Production Deployment

### Kubernetes Deployment

```yaml
# kubernetes/kafka-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ecommerce-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ecommerce-api
  template:
    metadata:
      labels:
        app: ecommerce-api
    spec:
      containers:
      - name: ecommerce-api
        image: ecommerce-api:latest
        env:
        - name: KAFKA_BROKERS
          value: "kafka-1.prod:9092,kafka-2.prod:9092,kafka-3.prod:9092"
        - name: KAFKA_GROUP_ID
          value: "ecommerce-prod-group"
        ports:
        - containerPort: 3000
```

## ✅ Benefits of Kafka vs In-Memory

| Feature               | In-Memory          | Kafka                 |
| --------------------- | ------------------ | --------------------- |
| **Durability**  | ❌ Lost on restart | ✅ Persisted to disk  |
| **Scalability** | ❌ Single instance | ✅ Multiple consumers |
| **Throughput**  | ⭐⭐               | ⭐⭐⭐⭐⭐            |
| **Reliability** | ⭐⭐               | ⭐⭐⭐⭐⭐            |
| **Ordering**    | ✅                 | ✅ Per partition      |
| **Replay**      | ❌                 | ✅ Can replay events  |
| **Monitoring**  | ⭐                 | ⭐⭐⭐⭐⭐            |
| **Setup**       | Easy               | Complex               |
| **Cost**        | Free               | Infrastructure        |

---

 **Result** : Production-ready E-commerce system với Kafka Event Bus! 🚀
