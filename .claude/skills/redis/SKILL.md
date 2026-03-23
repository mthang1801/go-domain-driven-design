---
name: redis
description: 'Redis Cache, Distributed Lock, và Short-term Data — Hướng dẫn sử dụng @RedisCache và @RedisLock decorators.'
---

# Redis — Cache, Lock & Short-term Data

## Tổng quan

Module `@core/redis` cung cấp 2 decorator chính:

| Decorator     | Mục đích                                                       | Import                                      |
| ------------- | -------------------------------------------------------------- | ------------------------------------------- |
| `@RedisCache` | Cache-aside (GET) + Write-through invalidation (SET)           | `import { RedisCache } from '@core/redis';` |
| `@RedisLock`  | Distributed lock — đảm bảo chỉ 1 instance chạy tại 1 thời điểm | `import { RedisLock } from '@core/redis';`  |

Ngoài ra, `RedisClientProxy` cung cấp API trực tiếp (get/set/del/setnx/incr...) khi decorator không phù hợp.

---

## 1. @RedisCache — Cache Decorator

### Options

```typescript
interface UseCacheOptions {
    ttl?: number; // Seconds, default: 3600
    mode?: 'GET' | 'SET'; // default: 'GET'
    pattern?: string; // Key pattern, hỗ trợ ${placeholder}
    parameters?: Record<string, string>; // Map placeholder → arg path
    keyGenerator?: (args: any[]) => string | string[]; // Custom key function
    relatedPatterns?: Array<RedisKeyOptions>; // Danh sách pattern cần clear khi mode=SET
    alg?: 'MD5' | 'None'; // Hash algorithm cho key, default: None
    prefix?: string; // Override prefix (default: Redis client prefix)
    delimiter?: string; // default: ':'
    connection?: RedisProviderOptions; // Chọn Redis connection cụ thể
}
```

### Mode: GET (Cache-Aside)

Flow: **Check cache → Hit? Return cache : Execute method → Store result → Return result**

```typescript
@RedisCache({
    pattern: 'MASTER_DATA:BUSINESS_TYPE',
    ttl: 24 * 60, // 24 phút
})
async query(query: FilterDto): Promise<any> {
    return this.repository.findAllAndCount(query);
}
```

### Mode: SET (Write-Through + Cache Invalidation)

Flow: **Execute method → Clear related cache keys → Return result**

```typescript
@RedisCache({
    mode: 'SET',
    relatedPatterns: [
        {
            pattern: 'FORM:{formTemplateId}:{formId}',
            parameters: {
                formTemplateId: 'args[0].formTemplateId',
                formId: 'args[0].formId',
            },
        },
        { pattern: 'FORM:*' }, // Wildcard — clear all FORM cache
    ],
})
async execute(input: CreateFormDto): Promise<Form> {
    return this.formRepository.persistData(input);
}
```

### Cache Key Generation

#### Parameters (recommended)

```typescript
@RedisCache({
    pattern: 'FIND_ONE:{formId}:{groupId}:{fieldId}',
    parameters: {
        formId: 'args[0].formId',      // lấy từ argument[0].formId
        groupId: 'args[0].groupId',
        fieldId: 'args[0].id',
    },
    ttl: 3600,
})
async findByInput(input: FormFieldRequestDto): Promise<FormField> { ... }
```

#### KeyGenerator (khi logic phức tạp)

```typescript
@RedisCache({
    keyGenerator: (args) => `USER:${args[0].id}:${args[0].type}`,
})
async getUser(filter: UserFilter): Promise<User> { ... }
```

#### Placeholder Formats (cả 3 đều hợp lệ)

- `${placeholder}` — **Recommended**
- `{placeholder}` — Tương thích
- `{{placeholder}}` — Tương thích

### Invalidation-Only Pattern

Dùng khi chỉ cần clear cache mà không cần cache result:

```typescript
@RedisCache({
    mode: 'SET',
    relatedPatterns: [{ pattern: 'FORM:*' }],
})
private async invalidateCache(): Promise<void> {}
```

---

## 2. @RedisLock — Distributed Lock

Đảm bảo chỉ **1 instance** (1 pod) chạy đoạn code tại 1 thời điểm.

### Options

```typescript
interface RedisLockOptions {
    pattern?: string; // Lock key, default: 'LOCK:'
    ttl?: number; // Lock TTL seconds, default: 30
    maxRetries?: number; // Số lần retry nếu lock bị chiếm, default: 0 (không retry)
    retryDelay?: number; // Delay giữa các retry (ms), default: 5000
    parameters?: Record<string, string>;
    keyGenerator?: (args: any[]) => string;
    connection?: RedisProviderOptions;
}
```

### Ví dụ: Cronjob chỉ chạy 1 lần trên 1 pod

```typescript
@Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
@RedisLock({
    pattern: 'LOCK:MARITAL_STATUS_SYNC',
    ttl: 10,         // Lock giữ tối đa 10s
    maxRetries: 0,    // Không retry — nếu pod khác đang chạy thì bỏ qua
})
async execute() {
    await this.syncService.execute();
}
```

### Lock Behavior

| maxRetries   | Behavior                                                            |
| ------------ | ------------------------------------------------------------------- |
| `0`          | **Fire-and-forget**: Nếu lock bị chiếm → skip silently              |
| `> 0`        | **Retry**: Chờ `retryDelay` ms rồi thử lại, tối đa `maxRetries` lần |
| Lock hết TTL | Lock tự động release (tránh deadlock)                               |

---

## 3. RedisClientProxy — Direct API

Khi decorator không phù hợp (ví dụ: idempotency, counter, custom logic):

```typescript
import { InjectRedis, RedisClientProxy } from '@core/redis';

@Injectable()
export class MyService {
    constructor(@InjectRedis() private readonly redis: RedisClientProxy) {}

    async example() {
        await this.redis.set('KEY', value, { EX: 60 });
        const data = await this.redis.get('KEY');
        await this.redis.del('KEY');
        const acquired = await this.redis.setnx('LOCK:X', 'locked', { EX: 30 });
        await this.redis.incr('COUNTER:VIEWS');
    }
}
```

---

## Khi nào nên dùng Redis?

### ✅ Nên dùng

| Tình huống                  | Decorator/API              | Ghi chú                                                     |
| --------------------------- | -------------------------- | ----------------------------------------------------------- |
| **Master data ít thay đổi** | `@RedisCache` GET, TTL dài | Business types, relation types, enums                       |
| **Query kết quả lặp lại**   | `@RedisCache` GET          | Repository findById, findByFilter                           |
| **Write → Clear cache**     | `@RedisCache` SET          | Khi update/create/delete cần invalidate GET cache tương ứng |
| **Cronjob multi-pod**       | `@RedisLock`               | Đảm bảo chỉ 1 pod chạy cronjob                              |
| **Idempotency key**         | `RedisClientProxy` set/get | Prevent duplicate requests                                  |
| **Rate limiting**           | `RedisClientProxy` incr+EX | Counter per user/IP                                         |
| **Short-term session data** | `RedisClientProxy` set     | Report progress, export status                              |

### ❌ Không nên dùng

- Data quá lớn (> 1MB per key) — cân nhắc stream hoặc S3
- Data thay đổi liên tục (< 1s) — cache không có ý nghĩa
- Data cần persist vĩnh viễn — dùng database
- Connection pool/registry nội bộ — giữ in-memory Map

---

## Best Practices

1. **Key naming convention**: `MODULE:ENTITY:${id}` hoặc `MODULE:ACTION:${params}`
2. **TTL hợp lý**: Master data → 24h+, session data → 5–60 min, idempotency → 60s
3. **Luôn define `relatedPatterns`** khi dùng mode `SET` — tránh stale cache
4. **Dùng `parameters` thay vì `keyGenerator`** khi có thể — dễ đọc và maintain
5. **`maxRetries: 0`** cho cronjob — skip nếu pod khác đang chạy, không chờ
6. **Graceful fallback** khi dùng `RedisClientProxy` trực tiếp — wrap try/catch, proceed nếu Redis down

---

## Troubleshooting

| Triệu chứng            | Nguyên nhân                      | Giải pháp                                        |
| ---------------------- | -------------------------------- | ------------------------------------------------ |
| Cache không tạo        | Redis connection chưa ready      | Kiểm tra `LibRedisModule` đã import trong module |
| Cache không clear      | `relatedPatterns` pattern sai    | Debug log `[CLEANUP] Patterns to clear:`         |
| Key sai format         | `parameters` path sai            | Kiểm tra `args[0].field` mapping                 |
| Lock không release     | Method throw error trước finally | `@RedisLock` có finally block tự release         |
| Lock conflict liên tục | TTL quá dài                      | Giảm TTL phù hợp với thời gian xử lý thực tế     |
