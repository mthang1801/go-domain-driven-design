# Tracing — Real-World Examples

> Ví dụ thực tế từ codebase, minh họa cách sử dụng tracing và logging.

---

## 1. @LogExecution — Use-Case Level Tracing

**Pattern**: Mọi use-case execute() đều gắn `@LogExecution()` để tạo child span.

```typescript
import { LogExecution } from '@common/decorators';

@Injectable()
export class UpsertFormUsecase implements IBaseExecuteUsecase<CreateFormDto, Form> {
    constructor(@Inject(IFormRepository) private readonly formRepository: IFormRepository) {}

    @LogExecution()
    public async execute(input: CreateFormDto): Promise<Form> {
        // ... business logic ...
        return await this.formRepository.persistData(formEntity, { ... });
    }
}
```

**Kết quả trên Sentry:**

```
Transaction: POST /api/forms
  └── Controller.upsertForm (controller.execution)
        └── UpsertFormUsecase.execute (method.execution) ← @LogExecution tạo span này
```

---

## 2. @LogExecution — Repository với Sentry Trace

**Pattern**: Repository methods quan trọng gắn `enableSentryTrace: true` (default) để trace query performance.

```typescript
import { LogExecution } from '@common/decorators';

@Injectable()
export class FormFieldRepository extends BaseRepository<FormField, FormFieldOrm> {
    @LogExecution({ enableSentryTrace: true })
    public async findAllRelationsByFormId(formId: number): Promise<{
        formFieldRelations: FormFieldRelation[];
        formFieldCloneRelations: FormFieldCloneRelation[];
    }> {
        // ... parallel queries ...
        const [formFieldRelations, formFieldCloneRelations] = await Promise.all([
            formFieldRelationsPromise,
            formFieldCloneRelationsPromise,
        ]);
        return { formFieldRelations, formFieldCloneRelations };
    }
}
```

**Sentry Span kết quả:**

```
FormFieldRepository.findAllRelationsByFormId (method.execution)
  attributes:
    method.class: FormFieldRepository
    method.name: findAllRelationsByFormId
    method.args: [123]
    duration_ms: 45.2
```

---

## 3. TransformUseSentryInterceptor — Automatic Request Tracing

**Cấu hình**: Đăng ký global interceptor trong `main.ts` hoặc module.

```typescript
// main.ts
import { TransformUseSentryInterceptor } from '@common/transform';

app.useGlobalInterceptors(new TransformUseSentryInterceptor());
```

**Không cần thêm code trong Controller** — interceptor tự động:

- Tạo Sentry transaction với tên `controllerClass.methodName`
- Inject sessionId vào AsyncLocalStorage
- Set HTTP attributes (method, url, route, user-agent)
- Capture errors with scope tags

---

## 4. Cross-Service Trace Propagation — RabbitMQ/Kafka

### Gửi message (producer)

```typescript
import { SentryUtil } from '@core/trace-monitoring';

// Inject trace headers vào message
const traceHeaders = SentryUtil.getTraceParentMetadata();
await this.rabbitMQClient.emit('order.created', {
    data: orderPayload,
    headers: {
        'sentry-trace': traceHeaders.sentryTrace,
        baggage: traceHeaders.baggage,
    },
});
```

### Nhận message (consumer)

```typescript
import { SentryUtil } from '@core/trace-monitoring';

@MessagePattern('order.created')
async handleOrderCreated(@Payload() data, @Ctx() context) {
    const sentryTrace = context.getMessage().properties.headers['sentry-trace'];
    // Sentry auto-correlates via amqplibIntegration()
    // Child spans in this handler will link to the parent trace
}
```

---

## 5. Winston Logger — Auto-enrichment với SessionId

**cấu hình**: Winston logger tự động inject `sessionId` từ `RequestContextStorage`.

```typescript
// winston.core.ts — format context tự động
private addFormatContext(info: winston.Logform.TransformableInfo) {
    info.label = this.appName;
    info.sessionId = RequestContextStorage.sessionId ?? '';
    return info;
}
```

**Log output format:**

```
[data-visualizer] [PID:1234] [2026-03-08 07:00:00] [abc-session-id] [INFO] [MyService#execute.START] {input args}
[data-visualizer] [PID:1234] [2026-03-08 07:00:00] [abc-session-id] [INFO] [MyService#execute.END] Executed in 42.123ms
```

**→ Tất cả logs trong cùng 1 request đều có chung `sessionId`, giúp trace dễ dàng trên log aggregator.**

---

## 6. Custom Span Creation — Manual Tracing

Khi cần tạo span tùy chỉnh (không qua decorator):

```typescript
import { RequestContextStorage } from '@core/async-local-storage';

@Injectable()
export class ComplexService {
    async processWithCustomSpans(data: any) {
        // Auto-managed span (tự close khi callback return)
        return RequestContextStorage.createChildSpan(
            'ComplexService.processWithCustomSpans',
            'custom.processing',
            (span) => {
                span.setAttributes({
                    'data.count': data.items.length,
                    'data.type': data.type,
                });
                // ... xử lý ...
                return result;
            },
        );
    }

    async processWithManualEnd(data: any) {
        // Manual span (phải gọi finish() để close)
        return RequestContextStorage.startSpanManual(
            'ComplexService.processWithManualEnd',
            'manual.processing',
            (span, finish) => {
                try {
                    // ... xử lý lâu ...
                    return result;
                } finally {
                    finish(); // PHẢI gọi để close span
                }
            },
        );
    }
}
```

---

## Tổng hợp: Khi nào dùng gì?

| Tình huống                        | Giải pháp                                     | Ghi chú                    |
| --------------------------------- | --------------------------------------------- | -------------------------- |
| Use-case execute()                | `@LogExecution()`                             | Mặc định cho mọi use-case  |
| Repository query quan trọng       | `@LogExecution({ enableSentryTrace: true })`  | Trace DB query performance |
| Utility/mapper nhẹ                | `@LogExecution({ enableSentryTrace: false })` | Log only, không tạo span   |
| HTTP request tracking             | `TransformUseSentryInterceptor` (global)      | Auto — không cần thêm code |
| Gọi service khác (RabbitMQ/Kafka) | `SentryUtil.getTraceParentMetadata()`         | Propagate trace context    |
| Logic phức tạp cần span tùy chỉnh | `RequestContextStorage.createChildSpan()`     | Manual span creation       |
| Debug log correlation             | Tự động qua `sessionId`                       | Winston auto-inject        |
