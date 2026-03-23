# Redis — Real-World Examples

> Các ví dụ thực tế từ codebase: lending-evf, dynamic-form, data-visualizer.

---

## 1. @RedisCache GET — Master Data (ít thay đổi, TTL dài)

**File**: `lending-evf/application/business-type/use-cases/get-list-business-type.use-case.ts`

```typescript
import { RedisCache } from '@core/redis';

@Injectable()
export class GetListBusinessTypeUsecase implements IBaseQueryUsecase<FilterBusinessTypeDto, any> {
    constructor(
        @Inject(IBusinessTypeRepository)
        private readonly businessTypeRepository: IBusinessTypeRepository,
    ) {}

    @RedisCache({
        pattern: 'MASTER_DATA:BUSINESS_TYPE',
        ttl: 24 * 60, // 24 phút — data ít thay đổi
    })
    public async query(query: FilterBusinessTypeDto): Promise<any> {
        const [data, count] = await this.businessTypeRepository.findAllAndCount(query);
        return { data, count };
    }
}
```

**Giải thích:**

- Key: `prefix:MASTER_DATA:BUSINESS_TYPE`
- Không cần `parameters` vì data là toàn bộ list (không phụ thuộc vào input)
- TTL 24 phút — master data thay đổi hiếm, nhưng vẫn auto-refresh

---

## 2. @RedisCache GET — Repository Query (cache by composite key)

**File**: `dynamic-form/infrastructure/form-field/repositories/form-field-repository.ts`

```typescript
import { RedisCache } from '@core/redis';

@Injectable()
export class FormFieldRepository
    extends BaseRepository<FormField, FormFieldOrm>
    implements IFormFieldRepository
{
    @RedisCache({
        pattern: 'FIND_ONE_BY_FORM_FIELD_INPUT:{formId}:{groupId}:{fieldMasterDataId}',
        parameters: {
            formId: 'args[0].formId',
            groupId: 'args[0].groupId',
            fieldMasterDataId: 'args[0].id',
        },
        ttl: 60 * 60, // 1 giờ
    })
    public async findOneByFormFieldInput(input: FormFieldRequestDto): Promise<FormField> {
        return this.repository
            .$createQueryBuilder('ff')
            .$andWhere([
                { formId: input.formId, groupId: input.groupId, fieldMasterDataId: input.id },
                { id: input.formFieldId },
            ])
            .getOne()
            .then((res) => this.transformToDomain(res));
    }
}
```

**Giải thích:**

- Key: `prefix:FIND_ONE_BY_FORM_FIELD_INPUT:123:456:789`
- 3 parameters tạo composite key — mỗi tổ hợp `formId:groupId:fieldId` có cache riêng
- TTL 1 giờ — query result có thể thay đổi nhưng không thường xuyên

---

## 3. @RedisCache SET — Write-Through + Selective Invalidation

**File**: `dynamic-form/application/form/use-cases/upsert-form.usecase.ts`

```typescript
import { RedisCache } from '@core/redis';

@Injectable()
export class UpsertFormUsecase implements IBaseExecuteUsecase<CreateFormDto, Form> {
    constructor(@Inject(IFormRepository) private readonly formRepository: IFormRepository) {}

    @RedisCache({
        relatedPatterns: [
            {
                pattern: 'FORM:{formTemplateId}:{formId}',
                parameters: {
                    formTemplateId: 'args[0].formTemplateId',
                    formId: 'args[0].formId',
                },
            },
            {
                pattern: 'FIND_ONE_BY_FORM_FIELD_INPUT:{formId}:{groupId}:*',
                parameters: {
                    formId: 'args[0].formId',
                    groupId: 'args[0].groupId',
                },
            },
        ],
        mode: 'SET',
    })
    public async execute(input: CreateFormDto): Promise<Form> {
        // ... business logic ...
        return await this.formRepository.persistData(formEntity, { ... });
    }
}
```

**Giải thích:**

- Sau khi upsert xong → clear 2 loại cache:
    1. Cache form cụ thể: `FORM:tmpl123:form456`
    2. Cache form field inputs (wildcard): `FIND_ONE_BY_FORM_FIELD_INPUT:form456:group789:*`
- Wildcard `*` clear toàn bộ field cache thuộc form + group đó

---

## 4. @RedisCache SET — Invalidation-Only (empty method)

**File**: `dynamic-form/application/form-template/use-cases/update-form-template.usecase.ts`

```typescript
@Injectable()
export class UpdateFormTemplateUsecase {
    async execute(id: number, payload: UpdateFormTemplateDto): Promise<void> {
        // ... validation + update logic ...
        await this.formTemplateRepository.update(id, formTemplateEntityUpdated);
        await this.invalidateFormTemplateCache(); // gọi method helper
    }

    @RedisCache({
        mode: 'SET',
        relatedPatterns: [{ pattern: 'FORM:*' }],
    })
    private async invalidateFormTemplateCache(): Promise<void> {}
}
```

**Giải thích:**

- Method rỗng — chỉ dùng decorator để trigger cache invalidation
- `FORM:*` clear toàn bộ cache có prefix `FORM:`
- Pattern hữu ích khi cần clear cache từ nhiều nơi khác nhau

---

## 5. @RedisLock — Cronjob Distributed Lock

**File**: `lending-evf/infrastructure/cron/modules/marital-status.cronjob.ts`

```typescript
import { RedisLock } from '@core/redis';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class MaritalStatusCronjobService {
    constructor(private readonly syncDataMaritalStatusUsecase: SyncDataMaritalStatusUsecase) {}

    @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
    @RedisLock({
        pattern: 'LENDING_EVF:LOCK:MARITAL_STATUS_CRONJOB_EVERY_DAY_AT_MIDNIGHT',
        ttl: 10, // Lock giữ tối đa 10 giây
        maxRetries: 0, // KHÔNG retry — nếu pod khác đang chạy thì skip
    })
    public async execute() {
        await this.syncDataMaritalStatusUsecase.execute();
    }
}
```

**Giải thích:**

- Khi deploy multi-pod: cron trigger trên **tất cả** pods cùng lúc
- `@RedisLock` đảm bảo chỉ **1 pod** acquire lock và chạy
- `maxRetries: 0` → các pod khác skip ngay, không chờ
- `ttl: 10` → nếu pod crash, lock tự release sau 10s (tránh deadlock)

---

## 6. RedisClientProxy — Idempotency Key (Direct API)

**File**: `libs/common/modules/auth/interceptors/idempotency.interceptor.ts`

```typescript
import { InjectRedis } from '@core/redis/decorator/inject.decorator';
import { RedisClientProxy } from '@core/redis/redis-client.proxy';

@Injectable()
export class IdempotencyInterceptor implements NestInterceptor {
    constructor(@InjectRedis() private readonly redisClient: RedisClientProxy) {}

    intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
        const idempotencyKey = request.headers?.['x-idempotency-key'];
        const cacheKey = `IDEMPOTENCY:${idempotencyKey}`;

        // Check if response already cached
        const cached = await this.redisClient.get(cacheKey);
        if (cached) return of(cached);

        // Execute and cache
        return next.handle().pipe(
            tap((response) => {
                this.redisClient.set(cacheKey, response, { EX: 60 });
            }),
        );
    }
}
```

**Giải thích:**

- Decorator không phù hợp vì logic nằm trong interceptor (không phải method decorator)
- Dùng `RedisClientProxy.get/set` trực tiếp
- TTL 60s — idempotency key hết hạn sau 1 phút
- Graceful fallback nếu Redis down: proceed without cache

---

## Tổng hợp Pattern

| Pattern           | Decorator          | Mode | TTL             | Use Case                      |
| ----------------- | ------------------ | ---- | --------------- | ----------------------------- |
| Static key        | `@RedisCache`      | GET  | Dài (24h)       | Master data, enum list        |
| Composite key     | `@RedisCache`      | GET  | Trung bình (1h) | Repository findBy             |
| Write + Clear     | `@RedisCache`      | SET  | —               | Create/Update entity          |
| Invalidation-only | `@RedisCache`      | SET  | —               | Batch clear cache             |
| Distributed lock  | `@RedisLock`       | —    | Ngắn (10–30s)   | Cronjob, one-time task        |
| Custom logic      | `RedisClientProxy` | —    | Tùy             | Idempotency, counter, session |
