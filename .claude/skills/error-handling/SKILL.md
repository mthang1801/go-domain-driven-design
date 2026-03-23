---
name: error-handling
description: error-handling
---
## Error Handling Guide (NestJS)

Tong quan cach xu ly exception theo cac layer (presentation/application/infrastructure) va interceptor.

### 1) Flow xu ly loi

1. Controller/handler throw Exception (Domain/Usecase/Infrastructure/ThirdParty...).
2. `TransformInterceptor`/`TransformUseSentryInterceptor` wrap response va log.
3. `ExceptionInterceptor` map error -> `ApiErrorResponse`, log va notify Telegram.

Trong `AppModule`:
- `TransformUseSentryInterceptor` duoc set o `APP_INTERCEPTOR` de dong bo logging + tracing.
- `ExceptionInterceptor` chiu trach nhiem chuyen doi exception ra response.

### 2) ExceptionInterceptor

`ExceptionInterceptor` map error -> handler tuong ung:
- `UsecaseException` -> `UsecaseExceptionHandler`
- `InfrastructureException` -> `ExceptionInfrastructureHandler`
- `DomainException` -> `ExceptionDomainHandler`
- `ThirdPartyException`, `OmsException`, `SfaException`, `EkycException`
- `I18nValidationException` -> `I18nValidationExceptionHandler`
- fallback: `ExceptionHandler`

Sau khi map:
- bo stack trong production hoac `ThirdPartyException`.
- log loi + notify Telegram qua `Subject`.

### 3) Transform Interceptors

`TransformInterceptor`:
- wrap response vao `ApiResponseData`
- log request/response
- pass through errors

`TransformUseSentryInterceptor`:
- them tracing + span attributes
- capture exception vao Sentry
- log request/response/error

Neu route bi ignore (logger rule), `TransformUseSentryInterceptor` fallback ve `TransformInterceptor`.

### 4) RPC layer adapters (Kafka/RabbitMQ)

#### Kafka
`KafkaClientProxyAdapter.send()`:
- wrap timeout -> `InfrastructureException` voi code `TIMEOUT`
- giu nguyen exception khac

#### RabbitMQ
`RabbitMQClientProxyAdapter.send()`:
- validate expire (Date/number), sai -> `InfrastructureBadRequestException`
- timeout => reject `InfrastructureException` voi `statusCode` tu meta
- log loi voi `RequestContextStorage`

### 5) Quy uoc theo layer

- Domain layer: chi throw `DomainException` (khong phu thuoc infra).
- Application layer: throw `UsecaseException` cho flow nghiep vu.
- Infrastructure layer: wrap loi external/DB/RPC -> `InfrastructureException`.
- Presentation layer: khong xu ly loi, de interceptor map va format.

### 6) Ghi nho khi implement

- Luon dung exception class tu `libs/src/common/exceptions`.
- Khi call RPC, uu tien adapter (`KafkaClientProxyAdapter`, `RabbitMQClientProxyAdapter`) de timeout va error mapping nhat quan.
- Log stack chi o non-prod, tranh leak thong tin.
