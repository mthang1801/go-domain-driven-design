---
name: microservices
description: Hướng dẫn config RabbitMQ/Kafka và Subscribe Pattern
---
# Hướng dẫn config RabbitMQ/Kafka và Subscribe Pattern

Tài liệu này mô tả cách cấu hình RabbitMQ/Kafka và cách dùng decorator `SubscribeEventPattern`/`SubscribeMessagePattern` trong các service. Nội dung được trích từ các file:

- `lending-evf/src/infrastructure/messaging/rabbitmq/rabbitmq.config.ts`
- `dynamic-form/src/main.ts`
- `loan-product/libs/src/common/decorators/subscribe-pattern.decorator.ts`
- `nest-library-cms/src/infrastructure/messaging/kafka/kafka.config.ts`
- `nest-library-cms/libs/src/core/kafka/kafka.module.ts`

## 1) Cấu hình RabbitMQ registry (urls resolve một lần)

Khai báo `RabbitMQClientConfig`, `RabbitMQConsumerConfig` và khởi tạo registry.
URLs được resolve một lần từ `RMQ_URI` để tránh truyền `ConfigService` xuống từng config:

```typescript
import { RabbitMQRegistry } from '@core/rabbitmq';
import { ConfigService } from '@nestjs/config';
import { Microservice } from '@shared/types';
import { toArray } from '@shared/utils';

const configService = new ConfigService();
const urls: string[] = toArray(configService.get('RMQ_URI'));

export enum ENUM_RABBITMQ_QUEUES {
  PortalRabbitMQ = 'PortalRabbitMQ',
}

export const PortalRabbitMQ = {
  name: 'PortalRabbitMQ',
  isAck: true,
  urls,
  events: {
    PING: 'PortalRabbitMQ.PING',
  },
  messages: {
    ECHO: 'PortalRabbitMQ.ECHO',
  },
  queueOptions: {
    retryMessageTTL: 5000,
    retryMessageAttemps: 2,
    excludedRetryStatusCodes: [400, 404, 500],
    retryFactor: 1,
  },
} satisfies Microservice.RabbitMQ.Value<'PortalRabbitMQ'>;

export const RabbitMQClientConfig = {
  PortalRabbitMQ,
};

export const RabbitMQConsumerConfig = {
  PortalRabbitMQ,
};

export const rabbitMQRegistry = new RabbitMQRegistry(ENUM_RABBITMQ_QUEUES)
    .setClientConfig(RabbitMQClientConfig)
    .setConsumerConfig(RabbitMQConsumerConfig);
```

## 2) Đăng ký RabbitMQ module trong infrastructure

Vì `urls` đã resolve sẵn, module chỉ cần đăng ký client từ registry:

```typescript
import { LibRabbitMQModule } from '@core/rabbitmq';
import { Module } from '@nestjs/common';
import { rabbitMQRegistry } from './rabbitmq.config';

@Module({
  imports: [
    LibRabbitMQModule.registerAsync(
      rabbitMQRegistry.allClientConfigValues.map((client) => ({
        name: client.name,
        useFactory: () => client,
      })),
    ),
  ],
})
export class RabbitMQInfrastructureModule {}
```

## 3) Khởi tạo RabbitMQ consumer trong `main.ts`

`rabbitMQRegistry` đã có `urls` sẵn nên chỉ cần init consumer:

```typescript
import { rabbitMQRegistry } from '@infrastructure/messaging/rabbitmq/rabbitmq.config';
// ...
const configService = app.get<ConfigService>(ConfigService);
rabbitMQRegistry.initConsumersApplication(app);
// ...
await Promise.race([
    app.startAllMicroservices(),
    app.listen(configService.get<number>('PORT'), async () => {
        Logger.log(`server is running on ${await app.getUrl()}`, 'Main');
    }),
]);
```

## 4) Dùng Subscribe Pattern Decorator

Decorator `SubscribeEventPattern`/`SubscribeMessagePattern` wrap `EventPattern`/`MessagePattern` và gắn interceptor xử lý:

- log bắt đầu/kết thúc
- ack message khi xử lý thành công
- retry/đẩy DLQ khi lỗi
- bọc lỗi thành `RpcException` để trả về chuẩn

Ví dụ định nghĩa decorator:

```typescript
import { EventPattern, MessagePattern } from '@nestjs/microservices';
import { applyDecorators, UseInterceptors } from '@nestjs/common';

export const SubscribeEventPattern = (pattern: Microservice.Pattern) =>
    applyDecorators(EventPattern(pattern), UseInterceptors(handleMessageMixin(pattern)));

export const SubscribeMessagePattern = (pattern: Microservice.Pattern) =>
    applyDecorators(MessagePattern(pattern), UseInterceptors(handleMessageMixin(pattern)));
```

## 5) Example dùng Subscribe Pattern trong subscriber

Ví dụ lấy từ `dynamic-form`:

```typescript
import { SubscribeEventPattern, SubscribeMessagePattern } from '@common/decorators';
import { Controller, UsePipes, ValidationPipe } from '@nestjs/common';
import { Payload } from '@nestjs/microservices';
import { LoanProductToDynamicForm } from '../configs';

@Controller()
export class LoanProductToDynamicFormSubscriber {
    @SubscribeEventPattern(LoanProductToDynamicForm.messages.CREATE)
    public async subscribeCreatedDynamicForm(@Payload() payload: CreateFormDto) {
        return await this.createFormUsecase.execute(payload);
    }

    @SubscribeMessagePattern(LoanProductToDynamicForm.messages.FIND_BY_FORM_ID_PORTAL)
    public async subscribeFindByFormIdPortal(
        @Payload() payload: { formId: number; formTemplateId?: number },
    ) {
        return await this.getDetailFormPortalUsecase.query(payload);
    }

    @SubscribeMessagePattern(
        LoanProductToDynamicForm.messages.FIND_BY_FORM_ID_AND_MAPPING_EKYC_MOBILE,
    )
    @UsePipes(new ValidationPipe({ transform: true }))
    public async subscribeFindByFormIdMobile(@Payload() payload: FindFormMappingEKYCDto) {
        return await this.getDetailFormMappingEKYCMobileUsecase.query(payload);
    }
}
```

## 6) Checklist cấu hình

- [ ] Khai báo queue config trong `RabbitMQClientConfig`/`RabbitMQConsumerConfig`.
- [ ] `urls` đã resolve sẵn từ `RMQ_URI` (string[]).
- [ ] Gọi `rabbitMQRegistry.initConsumersApplication(app)`.
- [ ] Trong subscriber, dùng `@SubscribeEventPattern` cho event, `@SubscribeMessagePattern` cho request/response.

---

## 7) Cấu hình Kafka registry (theo project hiện tại)

Khai báo `KafkaClientConfig`, `KafkaConsumerConfig` và khởi tạo registry:

```typescript
import { ConfigService } from '@nestjs/config';
import { KafkaRegistry } from '@core/kafka';
import { Microservice } from '@shared/types';

export enum ENUM_KAFKA_CLIENTS {
  PortalKafka = 'PortalKafka',
  UserKafka = 'UserKafka',
}

export const PortalKafkaConfig = {
  name: ENUM_KAFKA_CLIENTS.PortalKafka,
  clientId: (configService: ConfigService) => configService.get<string>('KAFKA_DEFAULT_CLIENT_ID_1'),
  brokers: (configService: ConfigService) =>
    configService.get<string>('KAFKA_DEFAULT_BROKER_1').split(',').map((b) => b.trim()).filter(Boolean),
  groupId: (configService: ConfigService) => configService.get<string>('KAFKA_GROUP_ID_1'),
  events: { PING: 'PortalKafka.PING' },
  messages: { ECHO: 'PortalKafka.ECHO' },
  defaultTopicOptions: {
    enableAutoCommit: false,
    retryOptions: {
      retryMessageAttemps: 3,
      retryMessageTTL: 1000,
      retryFactor: 2,
      maxRetryDelay: 30000,
      excludedRetryStatusCodes: [400, 401, 403, 404],
      foreverRetryStatusCodes: [],
    },
    partitionsConsumedConcurrently: 3,
  },
} satisfies Microservice.Kafka.Value<'PortalKafka'>;

export const UserKafkaConfig = {
  name: ENUM_KAFKA_CLIENTS.UserKafka,
  clientId: (configService: ConfigService) => configService.get<string>('KAFKA_DEFAULT_CLIENT_ID'),
  brokers: (configService: ConfigService) =>
    configService.get<string>('KAFKA_DEFAULT_BROKER').split(',').map((b) => b.trim()).filter(Boolean),
  groupId: (configService: ConfigService) => configService.get<string>('KAFKA_GROUP_ID'),
  events: { PING: 'UserKafka.PING' },
  messages: { ECHO: 'UserKafka.ECHO' },
  defaultTopicOptions: {
    enableAutoCommit: false,
    retryOptions: {
      retryMessageAttemps: 2,
      retryMessageTTL: 1000,
      retryFactor: 2,
      maxRetryDelay: 30000,
      excludedRetryStatusCodes: [400, 401, 403, 404],
      foreverRetryStatusCodes: [],
    },
    partitionsConsumedConcurrently: 3,
  },
} satisfies Microservice.Kafka.Value<'UserKafka'>;

export const KafkaClientConfig = {
  PortalKafka: PortalKafkaConfig,
  UserKafka: UserKafkaConfig,
};

export const KafkaConsumerConfig = {
  PortalKafka: PortalKafkaConfig,
  UserKafka: UserKafkaConfig,
};

export const kafkaRegistry = new KafkaRegistry(ENUM_KAFKA_CLIENTS)
  .setClientConfig(KafkaClientConfig)
  .setConsumerConfig(KafkaConsumerConfig);
```

## 8) Đăng ký Kafka module trong infrastructure

```typescript
import { LibKafkaModule } from '@core/kafka';
import { kafkaRegistry } from './kafka.config';

@Module({
  imports: [
    LibKafkaModule.registerAsync(
      kafkaRegistry.allClientConfigValues.map((client) => ({
        name: client.name,
        inject: [ConfigService],
        useFactory: (configService: ConfigService) =>
          Object.assign(client, {
            brokers: (client.brokers as (configService: ConfigService) => string[])(configService),
            clientId: (client.clientId as (configService: ConfigService) => string)(configService),
            groupId: (client.groupId as (configService: ConfigService) => string)(configService),
          }),
      })),
    ),
  ],
})
export class KafkaInfrastructureModule {}
```

## 9) Khởi tạo Kafka consumer trong `main.ts`

```typescript
import { kafkaRegistry } from '@infrastructure/messaging/kafka/kafka.config';

// ...
kafkaRegistry.initConsumersApplication(app);
await app.startAllMicroservices();
```

## 10) Checklist cấu hình Kafka

- [ ] Khai báo `KafkaClientConfig`/`KafkaConsumerConfig`.
- [ ] Đăng ký `LibKafkaModule.registerAsync(...)`.
- [ ] Gọi `kafkaRegistry.initConsumersApplication(app)` trong `main.ts`.
- [ ] Trong subscriber, dùng `@SubscribeEventPattern`/`@SubscribeMessagePattern`.
