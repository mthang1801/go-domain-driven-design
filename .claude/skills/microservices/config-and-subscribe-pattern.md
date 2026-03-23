# RabbitMQ/Kafka: Complete Flow Guide - Config, Publish & Subscribe

Hướng dẫn đầy đủ về cách cấu hình RabbitMQ/Kafka và implement flow communication giữa các microservices, bao gồm:
- **Config**: Định nghĩa patterns/queues
- **Publish (emit)**: Fire-and-forget events
- **Send**: Request-response (async/await)
- **Subscribe**: Consumer xử lý messages

## 📋 Flow Overview

```
Service A (Publisher)              Queue              Service B (Consumer)
     │                                │                       │
     ├─1. Define Config──────────────┤                       │
     │   (messages/events)            │                       │
     │                                ├───────────────────────┤
     │                                │    1. Define Config   │
     │                                │    (same patterns)    │
     │                                │                       │
     ├─2. Inject Client               │                       │
     │   @Inject(Queue.name)          │                       │
     │                                │                       │
     ├─3. Publish/Send────────────────►                      │
     │   client.emit() / .send()      │                       │
     │                                │                       │
     │                                ├───────────────────────►
     │                                │    4. Subscribe       │
     │                                │    @SubscribePattern  │
     │                                │                       │
     │◄───────────────────────────────┤◄──────────────────────┤
     │   (if send: response)          │    5. Return result   │
```

---

## 🎯 Real Example: loan-product ⟷ dynamic-form

### Architecture Overview

```
loan-product Service               dynamic-form Service
      │                                   │
      ├── Config Pattern ◄────────────────┤ Config Pattern
      │   FIND_BY_FORM_ID_..._MOBILE      │ FIND_BY_FORM_ID_..._MOBILE
      │                                   │
      ├── UseCase (Publisher)             │
      │   .send() with pattern ──────────►│ Subscriber (Consumer)
      │   await response                  │ @SubscribeMessagePattern
      │   ◄───────────────────────────────│ return result
```

---

## Step 1️⃣: Define Shared Config (Both Services)

### Service A: loan-product (Publisher)

```typescript
// loan-product/src/infrastructure/messaging/rabbitmq/configs/loan-product-to-dynamic-form.ts

import { ENUM_RABBITMQ_QUEUE } from '@module-shared/enum';
import { Microservice } from '@shared/types';
import { rabbitMQUrls } from '../rabbitmq.helper';

const LOAN_PRODUCT_TO_DYNAMIC_FORM = ENUM_RABBITMQ_QUEUE.LOAN_PRODUCT_TO_DYNAMIC_FORM;

export const LoanProductToDynamicForm = {
    name: LOAN_PRODUCT_TO_DYNAMIC_FORM,
    isAck: true,
    urls: rabbitMQUrls,
    prefetchCount: 50,
    events: {
        // Fire-and-forget events
    },
    messages: {
        // Request-response patterns
        CREATE: `${LOAN_PRODUCT_TO_DYNAMIC_FORM}.CREATE`,
        FIND_BY_FORM_ID_AND_MAPPING_EKYC_MOBILE: `${LOAN_PRODUCT_TO_DYNAMIC_FORM}.FIND_BY_FORM_ID_AND_MAPPING_EKYC_MOBILE`,
        CREATE_FORM_SUBMIT_VALUE: `${LOAN_PRODUCT_TO_DYNAMIC_FORM}.CREATE_FORM_SUBMIT_VALUE`,
        // ... other patterns
    },
} satisfies Microservice.RabbitMQ.Value<typeof LOAN_PRODUCT_TO_DYNAMIC_FORM>;
```

### Service B: dynamic-form (Consumer)

```typescript
// dynamic-form/src/infrastructure/messaging/rabbitmq/configs/loan-product-to-dynamic-form.ts

import { ENUM_RABBITMQ_QUEUE } from '@module-shared/enum';
import { Microservice } from '@shared/types';
import { rabbitMQUrls } from '../rabbitmq.helper';

const LOAN_PRODUCT_TO_DYNAMIC_FORM = ENUM_RABBITMQ_QUEUE.LOAN_PRODUCT_TO_DYNAMIC_FORM;

export const LoanProductToDynamicForm = {
    name: LOAN_PRODUCT_TO_DYNAMIC_FORM,
    isAck: true,
    urls: rabbitMQUrls,
    prefetchCount: 500, // Higher for consumer
    events: {},
    messages: {
        // ⚠️ MUST match patterns from publisher
        CREATE: `${LOAN_PRODUCT_TO_DYNAMIC_FORM}.CREATE`,
        FIND_BY_FORM_ID_AND_MAPPING_EKYC_MOBILE: `${LOAN_PRODUCT_TO_DYNAMIC_FORM}.FIND_BY_FORM_ID_AND_MAPPING_EKYC_MOBILE`,
        CREATE_FORM_SUBMIT_VALUE: `${LOAN_PRODUCT_TO_DYNAMIC_FORM}.CREATE_FORM_SUBMIT_VALUE`,
        // ... other patterns
    },
} satisfies Microservice.RabbitMQ.Value<typeof LOAN_PRODUCT_TO_DYNAMIC_FORM>;
```

**Key Points:**
- ✅ Pattern strings **MUST be identical** in both services
- ✅ `name` must match queue name
- ✅ `urls` from shared config
- ℹ️ `prefetchCount` can differ (publisher vs consumer)

---

## Step 2️⃣: Publisher - Inject Client & Send

### Inject RabbitMQ Client in UseCase

```typescript
// loan-product/src/application/finance-product/use-cases/get-finance-product-form.mobile.usecase.ts

import { IRabbitClientProxy } from '@core/rabbitmq';
import { LoanProductToDynamicForm } from '@infrastructure/messaging/rabbitmq/configs';
import { Inject, Injectable } from '@nestjs/common';

@Injectable()
export class GetFinanceProductFormMobileUsecase {
    constructor(
        // 1️⃣ Inject RabbitMQ client by queue name
        @Inject(LoanProductToDynamicForm.name)
        private readonly loanProductToDynamicForm: IRabbitClientProxy,
        // ... other dependencies
    ) {}

    public async query(id: number): Promise<FinanceProductForm> {
        // Business logic...
        const formId = 123;
        const ekycData = { /* ... */ };
        const lenderIntegrationCode = 'BVB';
        const formTemplateId = 456;

        // 2️⃣ Send message with pattern (Request-Response)
        return await this.loanProductToDynamicForm.send(
            LoanProductToDynamicForm.messages.FIND_BY_FORM_ID_AND_MAPPING_EKYC_MOBILE,
            { 
                formId, 
                ekycData, 
                lenderIntegrationCode, 
                formTemplateId 
            },
        );
        // ⏳ Wait for response from consumer
    }
}
```

**Methods Available:**

```typescript
interface IRabbitClientProxy {
    // Fire-and-forget (no response)
    emit(pattern: string, data: any): Observable<any>;
    
    // Request-response (await response)
    send<TResult = any, TInput = any>(
        pattern: string, 
        data: TInput
    ): Promise<TResult>;
}
```

---

## Step 3️⃣: Consumer - Subscribe to Pattern

### Define Subscriber

```typescript
// dynamic-form/src/infrastructure/messaging/rabbitmq/subscribers/dynamic-form.subscriber.ts

import { SubscribeMessagePattern } from '@common/decorators';
import { Controller, UsePipes, ValidationPipe } from '@nestjs/common';
import { Payload } from '@nestjs/microservices';
import { LoanProductToDynamicForm } from '../configs';
import { FindFormMappingEKYCDto } from '@application/form/dto';
import { GetDetailFormMappingEKYCMobileUsecase } from '@application/form/use-cases';

@Controller()
export class LoanProductToDynamicFormSubscriber {
    constructor(
        private readonly getDetailFormMappingEKYCMobileUsecase: GetDetailFormMappingEKYCMobileUsecase,
        // ... other use-cases
    ) {}

    // 1️⃣ Subscribe to message pattern
    @SubscribeMessagePattern(
        LoanProductToDynamicForm.messages.FIND_BY_FORM_ID_AND_MAPPING_EKYC_MOBILE
    )
    @UsePipes(new ValidationPipe({ transform: true }))
    public async subscribeFindByFormIdMobile(
        @Payload() payload: FindFormMappingEKYCDto
    ) {
        // 2️⃣ Execute use-case
        const result = await this.getDetailFormMappingEKYCMobileUsecase.query(payload);
        
        // 3️⃣ Return response (automatically sent back to publisher)
        return result;
    }
}
```

**Decorator Options:**

```typescript
// For Events (fire-and-forget)
@SubscribeEventPattern(pattern: string)
- No response expected
- Use for notifications, logs, analytics

// For Messages (request-response)
@SubscribeMessagePattern(pattern: string)
- Response expected
- Use for queries, commands with results
```

---

## Step 4️⃣: Register Client & Consumer

### Publisher Service: Register Client

```typescript
// loan-product/src/infrastructure/messaging/rabbitmq/rabbitmq.module.ts

import { LibRabbitMQModule } from '@core/rabbitmq';
import { Module } from '@nestjs/common';
import { rabbitMQRegistry } from './rabbitmq.config';

@Module({
  imports: [
    LibRabbitMQModule.registerAsync(
      rabbitMQRegistry.allClientConfigValues.map((client) => ({
        name: client.name,
        useFactory: () => client,
      }))
    ),
  ],
})
export class RabbitMQInfrastructureModule {}
```

### Consumer Service: Init Consumers in main.ts

```typescript
// dynamic-form/src/main.ts

import { rabbitMQRegistry } from '@infrastructure/messaging/rabbitmq/rabbitmq.config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
    const app = await NestFactory.create(AppModule);
    
    // 1️⃣ Initialize all consumers from registry
    rabbitMQRegistry.initConsumersApplication(app);
    
    // 2️⃣ Start microservices
    await Promise.race([
        app.startAllMicroservices(),
        app.listen(3000, () => {
            console.log('Server running on port 3000');
        }),
    ]);
}
bootstrap();
```

---

## 🔥 Pattern Types & Use Cases

### 1. Events (emit) - Fire and Forget

```typescript
// Publisher
client.emit(
    LoanProductToDynamicForm.events.ORDER_CREATED,
    { orderId: '123', customerId: 'C001' }
);
// ✅ No await, no response

// Consumer
@SubscribeEventPattern(LoanProductToDynamicForm.events.ORDER_CREATED)
async handleOrderCreated(@Payload() payload: OrderCreatedDto) {
    // Process event
    await this.sendEmail(payload);
    // No return value needed
}
```

**Use Cases:**
- Notifications
- Logging
- Analytics events
- Audit trails
- Non-critical operations

### 2. Messages (send) - Request-Response

```typescript
// Publisher
const result = await client.send(
    LoanProductToDynamicForm.messages.GET_USER_PROFILE,
    { userId: '123' }
);
// ⏳ Waits for response

// Consumer
@SubscribeMessagePattern(LoanProductToDynamicForm.messages.GET_USER_PROFILE)
async getUserProfile(@Payload() payload: { userId: string }) {
    const user = await this.userService.findById(payload.userId);
    return user; // ✅ Response sent back
}
```

**Use Cases:**
- Data queries
- Synchronous operations
- Commands that need confirmation
- Critical operations requiring feedback

---

## 📦 Complete Registry Setup

### RabbitMQ Registry

```typescript
// rabbitmq.config.ts
import { RabbitMQRegistry } from '@core/rabbitmq';
import { ConfigService } from '@nestjs/config';
import { toArray } from '@shared/utils';

const configService = new ConfigService();
const urls: string[] = toArray(configService.get('RMQ_URI'));

export enum ENUM_RABBITMQ_QUEUES {
  LOAN_PRODUCT_TO_DYNAMIC_FORM = 'LOAN_PRODUCT_TO_DYNAMIC_FORM',
  ORDER_SERVICE = 'ORDER_SERVICE',
  NOTIFICATION_SERVICE = 'NOTIFICATION_SERVICE',
}

export const RabbitMQClientConfig = {
  LoanProductToDynamicForm,
  OrderService,
  NotificationService,
};

export const RabbitMQConsumerConfig = {
  LoanProductToDynamicForm,
  OrderService,
  NotificationService,
};

export const rabbitMQRegistry = new RabbitMQRegistry(ENUM_RABBITMQ_QUEUES)
    .setClientConfig(RabbitMQClientConfig)
    .setConsumerConfig(RabbitMQConsumerConfig);
```

---

## 🎯 Kafka Setup (Similar Flow)

### Config

```typescript
// kafka.config.ts
export const LoanProductKafka = {
  name: ENUM_KAFKA_CLIENTS.LoanProductKafka,
  clientId: (configService: ConfigService) => configService.get('KAFKA_CLIENT_ID'),
  brokers: (configService: ConfigService) => 
    configService.get('KAFKA_BROKERS').split(','),
  groupId: (configService: ConfigService) => configService.get('KAFKA_GROUP_ID'),
  events: {
    FORM_CREATED: 'loan-product.form.created',
  },
  messages: {
    GET_FORM: 'loan-product.form.get',
  },
} satisfies Microservice.Kafka.Value<'LoanProductKafka'>;
```

### Publisher

```typescript
@Injectable()
export class FormService {
    constructor(
        @Inject(LoanProductKafka.name)
        private readonly kafka: IKafkaClientProxy
    ) {}

    async createForm(data: CreateFormDto) {
        // Emit event
        await this.kafka.emit(
            LoanProductKafka.events.FORM_CREATED,
            { formId: '123', ...data }
        );

        // Or send with response
        const result = await this.kafka.send(
            LoanProductKafka.messages.GET_FORM,
            { formId: '123' }
        );
        return result;
    }
}
```

### Consumer

```typescript
@Controller()
export class FormKafkaSubscriber {
    @SubscribeEventPattern(LoanProductKafka.events.FORM_CREATED)
    async handleFormCreated(@Payload() payload: FormCreatedDto) {
        // Process event
    }

    @SubscribeMessagePattern(LoanProductKafka.messages.GET_FORM)
    async getForm(@Payload() payload: { formId: string }) {
        return await this.formService.findById(payload.formId);
    }
}
```

---

## ✅ Checklist

### Publisher Service (loan-product)

- [ ] Define config with patterns in `configs/queue-name.ts`
- [ ] Register client in module: `LibRabbitMQModule.registerAsync(...)`
- [ ] Inject client in use-case: `@Inject(QueueName.name)`
- [ ] Call `client.emit()` for events or `client.send()` for messages

### Consumer Service (dynamic-form)

- [ ] Define config with **same patterns** in `configs/queue-name.ts`
- [ ] Create subscriber: `@Controller()` class
- [ ] Add methods with `@SubscribeEventPattern` or `@SubscribeMessagePattern`
- [ ] Initialize consumers in `main.ts`: `registry.initConsumersApplication(app)`
- [ ] Start microservices: `app.startAllMicroservices()`

### Both Services

- [ ] Patterns match exactly between publisher & consumer
- [ ] Queue name (`name` field) matches
- [ ] `urls` configured correctly
- [ ] Error handling implemented
- [ ] Logging added for debugging

---

## 🐛 Debugging Tips

### 1. Pattern Mismatch

```typescript
// ❌ BAD: Different patterns
// Publisher: 'QUEUE.FIND_USER'
// Consumer: 'QUEUE.GET_USER'

// ✅ GOOD: Same pattern
// Both: 'QUEUE.FIND_USER'
```

### 2. Check Consumer Running

```bash
# RabbitMQ Management UI
http://localhost:15672

# Check connections, queues, consumers
```

### 3. Enable Debug Logging

```typescript
@SubscribeMessagePattern(pattern)
async handler(@Payload() payload: any) {
    console.log('Received:', pattern, payload);
    const result = await this.process(payload);
    console.log('Returning:', result);
    return result;
}
```

### 4. Timeout Issues

```typescript
// Increase timeout in config
queueOptions: {
    retryMessageTTL: 10000, // 10s
    retryMessageAttemps: 3,
}
```

---

## 📚 Related Documentation

- RabbitMQ: [config-and-subscribe-pattern.md](./config-and-subscribe-pattern.md)
- Kafka: [event-bus-pattern.md](./event-bus-pattern.md)
- Testing: See mocking examples in TDD workflow

---

**Remember:** 
- Events = Fire-and-forget (`emit`)
- Messages = Request-response (`send`)
- Patterns must match exactly between services
- Always test with real message broker in development
