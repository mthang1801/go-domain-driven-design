---
name: tracing
description: 'Sentry tracing, distributed logging, and AsyncLocalStorage request context for NestJS. Covers @LogExecution decorator, TransformUseSentryInterceptor, RequestContextStorage, SentryWinstonTransport, SentryUtil for cross-service trace propagation, and span creation patterns. Use this skill whenever adding logging, tracing, monitoring, observability, performance tracking, error reporting to Sentry, correlating logs across services, or debugging distributed request flows.'
---

# Tracing & Observability — Sentry + Winston + AsyncLocalStorage

## Architecture Overview

```
Request → TransformUseSentryInterceptor → AsyncLocalStorage (session context)
                    │
                    ├── Sentry Transaction (root span)
                    │       └── Controller Span
                    │               └── @LogExecution child spans
                    │
                    └── Winston Logger (console + file + Sentry transport)
                            └── sessionId injected from ALS
```

### Core Components

| Component                       | Path                                                                  | Purpose                                                                    |
| ------------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| `TransformUseSentryInterceptor` | `libs/src/common/transform/sentry-transform.interceptor.ts`           | HTTP interceptor: creates Sentry transaction + controller span per request |
| `@LogExecution` decorator       | `libs/src/common/decorators/log.decorator.ts`                         | Method/class decorator: log timing + create Sentry child span              |
| `RequestContextStorage`         | `libs/src/core/async-local-storage/request-context.service.ts`        | AsyncLocalStorage singleton: stores sessionId, userId, IP per request      |
| `SentryWinstonTransport`        | `libs/src/core/logger/winston/transports/winston-sentry.transport.ts` | Winston transport: forwards error/warn to Sentry, adds breadcrumbs         |
| `SentryUtil`                    | `libs/src/core/trace-monitoring/sentry/utils/sentry.util.ts`          | Utility: extract/parse trace headers for cross-service propagation         |
| Sentry Adapters                 | `libs/src/core/trace-monitoring/sentry/adapters/`                     | RabbitMQ + Kafka trace context propagation                                 |

---

## 1. @LogExecution — Method/Class Decorator

### Import

```typescript
import { LogExecution } from '@common/decorators';
```

### Usage

```typescript
// Class-level: wraps ALL methods (except constructor)
@Injectable()
@LogExecution()
export class GetListBusinessTypeUsecase {
    async query(filter: FilterDto): Promise<any> { ... }
}

// Method-level: wraps a single method
@Injectable()
export class MyService {
    @LogExecution({ enableSentryTrace: true })
    async processData(input: InputDto): Promise<Result> { ... }
}
```

### Options

```typescript
interface LogOptions {
    space?: number; // JSON.stringify indent (default: 0)
    enableLogResponse?: boolean; // Log return value (default: false)
    isDebug?: boolean; // Debug mode (default: env IS_DEBUG)
    enableSentryTrace?: boolean; // Create Sentry child span (default: true)
}
```

### Behavior

1. Logs `START` with method name and arguments
2. If `enableSentryTrace: true` → creates a Sentry child span via `RequestContextStorage.createChildSpan()`
3. Measures execution time
4. Logs `END` with duration in ms
5. On error: logs `ERROR`, records exception to span, re-throws

### Output Format

```
[MyService#processData.START]  {...args}
[MyService#processData.END]    Executed in 42.123ms
```

---

## 2. TransformUseSentryInterceptor — HTTP Request Tracing

### How it works

Applied globally via NestJS interceptors. For each HTTP request:

1. `RequestContextStorage.runWithSentry()` — creates AsyncLocalStorage context + Sentry transaction
2. Creates a `controller.execution` span with HTTP attributes
3. On success: sets `http.status_code`, `method.success: true`
4. On error: records exception, sets error context, captures to Sentry with scope tags

### Span Attributes (auto-set)

| Attribute           | Source                 |
| ------------------- | ---------------------- |
| `method.class`      | Controller class name  |
| `method.name`       | Controller method name |
| `request.sessionId` | From AsyncLocalStorage |
| `http.method`       | GET / POST / etc       |
| `http.url`          | Full URL               |
| `http.route`        | Route pattern          |
| `http.user_agent`   | User-Agent header      |
| `duration_ms`       | Measured               |

---

## 3. RequestContextStorage — AsyncLocalStorage

A singleton (`RequestContextStorage`) that stores per-request context using Node.js `AsyncLocalStorage`.

### API

```typescript
import { IRequestContext, RequestContextStorage } from '@core/async-local-storage';

// Read context
RequestContextStorage.sessionId    // string
RequestContextStorage.ip           // string | null
RequestContextStorage.authorization // string | null
RequestContextStorage.context      // Full IRequestContextOptions

// Run with context
RequestContextStorage.run(session, () => { ... });

// Sentry integration
RequestContextStorage.runWithSentry(session, transactionName, (finish) => {
    // finish() must be called to end the transaction
});

RequestContextStorage.createChildSpan('spanName', 'op.type', (span) => {
    span.setAttributes({ key: 'value' });
    return result;
});

RequestContextStorage.startSpanManual('spanName', 'op.type', (span, finish) => {
    // Must call finish() manually
});

// Metadata storage
RequestContextStorage.setMetadata('key', value);
RequestContextStorage.getMetadata('key');
```

---

## 4. SentryWinstonTransport — Log → Sentry Bridge

Winston transport that automatically forwards logs to Sentry:

| Log Level    | Sentry Action                                        |
| ------------ | ---------------------------------------------------- |
| `error`      | `Sentry.captureException()` with stack trace         |
| `warn`       | `Sentry.captureMessage()` with severity `warning`    |
| `info/debug` | `Sentry.addBreadcrumb()` (filtered by skip patterns) |

### Skip Patterns (noise filter)

`Health check`, `Heartbeat`, `Polling`, `[START]`, `[END]` — these patterns are skipped from breadcrumbs to avoid noise.

### Auto-enrichment via `beforeSend`

- `sessionId` tag from `RequestContextStorage`
- `user.id`, `user.ip` from request context
- `requestMetadata` as extra data

---

## 5. Cross-Service Trace Propagation

### SentryUtil

```typescript
import { SentryUtil } from '@core/trace-monitoring';

// Get trace headers for outgoing requests
const { sentryTrace, baggage } = SentryUtil.getTraceParentMetadata();

// Parse incoming trace header
const { traceId, spanId, flags } = SentryUtil.parseSentryTraceHeader(sentryTraceHeader);
```

### Microservice Adapters

| Adapter                 | Path                                         | Purpose                                           |
| ----------------------- | -------------------------------------------- | ------------------------------------------------- |
| `SentryRabbitMQAdapter` | `sentry/adapters/sentry-rabbitmq.adapter.ts` | Inject/extract trace context in RabbitMQ messages |
| `SentryKafkaAdapter`    | `sentry/adapters/sentry-kafka.adapter.ts`    | Inject/extract trace context in Kafka headers     |

### Built-in Integrations (auto-configured in SentryWinstonTransport)

- `Sentry.httpIntegration()` — auto-trace outgoing/incoming HTTP
- `Sentry.amqplibIntegration()` — auto-trace RabbitMQ
- `Sentry.kafkaIntegration()` — auto-trace Kafka
- `Sentry.expressIntegration()` — auto-trace Express middleware
- `nodeProfilingIntegration()` — CPU profiling

---

## Best Practices

1. **Dùng `@LogExecution()` cho mọi use-case và service method quan trọng** — tạo waterfall tracing tự động trên Sentry
2. **`enableSentryTrace: true` (default)** — luôn bật trừ khi method quá nhẹ (getter, mapper)
3. **`enableSentryTrace: false`** — hiếm khi dùng, chỉ khi không muốn tạo span (hot path, utility)
4. **Không gọi `Sentry.captureException()` trực tiếp** — để `SentryWinstonTransport` và interceptor xử lý
5. **Thêm `span.setAttributes()`** khi cần enrichment (business context, query params)
6. **Propagate trace headers** khi gọi service khác — dùng `SentryUtil.getTraceParentMetadata()`

---

## Environment Variables

```bash
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
SENTRY_ENVIRONMENT=development
SENTRY_RELEASE=1.0.0
SENTRY_TRACES_SAMPLE_RATE=1.0
SENTRY_PROFILES_SAMPLE_RATE=1.0
IS_DEBUG=true  # Enable debug logs in @LogExecution
```

---

## Troubleshooting

| Triệu chứng                      | Nguyên nhân                                          | Giải pháp                                     |
| -------------------------------- | ---------------------------------------------------- | --------------------------------------------- |
| Span không xuất hiện trên Sentry | `enableSentryTrace: false` hoặc SENTRY_DSN trống     | Kiểm tra env và LogOptions                    |
| sessionId null trong logs        | Request không qua interceptor (health check, static) | Đúng behavior — skip patterns                 |
| Trace bị đứt giữa services       | Thiếu trace header propagation                       | Dùng `SentryUtil.getTraceParentMetadata()`    |
| Breadcrumb quá nhiều             | Noisy logs không bị filter                           | Thêm vào `skipPatterns`                       |
| Log level sai trên Sentry        | Winston → Sentry level mapping                       | Kiểm tra `NestWinstonLogLevelMappingStrategy` |
