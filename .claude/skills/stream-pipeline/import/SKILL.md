---
name: import-engine
description: >
    Import Engine SDK — stream-based CSV/Excel import with BullMQ queue, progress tracking via Report module,
    and local saga compensation (all-or-nothing rollback). Use when building any file-import feature.
    Core lib at libs/src/common/modules/import-engine; strategy registration in application layer.
---

# Import Engine Skill

## Khi nào dùng

| Tình huống                                  | Dùng skill này          |
| ------------------------------------------- | ----------------------- |
| Import CSV/Excel lớn (> 1 k rows)           | ✅                      |
| Cần rollback toàn bộ nếu có row lỗi         | ✅                      |
| Cần theo dõi tiến trình realtime (SSE)      | ✅                      |
| Import cho một module mới (Product, Order…) | ✅                      |
| Đơn giản insert 1 record                    | ❌ dùng use-case thường |

---

## Architecture Overview

```
Controller (UploadFile)
    └── ImportService.submit()           ← lib: @common/modules/import-engine
            └── BullMQ queue
                    └── ImportWorker.process()
                            └── ImportModuleProcessorFactory.create(module)
                                    └── XxxImportStrategy.process(command)
                                            └── XxxImportSaga.execute(command)
                                                    ├── runPipeline()    ← stream CSV → validate → persist
                                                    └── compensate()     ← deleteByIds() on any failure
```

---

## Core Library Contracts (`@common/modules/import-engine`)

### 1. `ImportEngineModule`

```typescript
// Trong AppModule hoặc ImportApplicationModule
ImportEngineModule.forRootAsync();
```

Registers: `ImportWorker`, `ImportService`, `ImportStreamPipelineBuilder`, `StreamingCsvParser`, progress tracking.

### 2. `ImportService` — submit job

```typescript
import { ImportService } from '@common/modules/import-engine';

// Inject vào Controller:
@Inject(ImportService) private readonly importService: ImportService

// Submit:
await this.importService.submit({
    correlationId,
    module: 'customer',       // phải match ImportModuleType
    filePath,
    fileName,
    author,
    parentCorrelationId?,     // optional: dùng cho multi-sheet import
});
```

### 3. `ImportModuleProcessor` interface

Mỗi module phải implement:

```typescript
export interface ImportModuleStrategy {
    readonly moduleType: string; // must match ImportModuleType constant
    process(command: ImportProcessCommand): Promise<ImportProcessResult>;
}

export interface ImportProcessCommand {
    correlationId: string;
    module: string;
    filePath: string;
    fileName: string;
    onProgress: (processedRows: number, totalRows: number) => Promise<void>;
}

export interface ImportProcessResult {
    totalRows: number;
    importedRows: number;
    failedRows: number;
    errors: Array<{ rowNumber: number; message: string }>;
}
```

### 4. `ImportStreamPipelineBuilder` — parse CSV

```typescript
import { ImportStreamPipelineBuilder, ImportFactory } from '@common/modules/import-engine';

// Build template
const worksheet = ImportFactory.createImportCsvWorksheet()
    .setSourceFilePath(filePath)
    .setColumn([
        { header: 'name', key: 'name', type: 'string', required: true },
        { header: 'price', key: 'price', type: 'number' },
        {
            header: 'status',
            key: 'status',
            type: 'string',
            mapping: { 'Hoạt động': 'ACTIVE', 'Không hoạt động': 'INACTIVE' },
        },
        { header: 'createdAt', key: 'createdAt', type: 'date' },
    ]);

const template = ImportFactory.createImportCsvTemplate({ name: 'my-module' });
template.addContent(worksheet);

// Parse thành async iterable
const [pipeline] = this.pipelineBuilder.buildCsvPipeline<MyRowType>(template);
const batched = pipeline.batch(100);

for await (const batch of batched.source as AsyncIterable<MyRowType[]>) {
    for (const row of batch) {
        /* validate + persist */
    }
}
```

Column type values: `'string'` | `'number'` | `'date'` | `'boolean'`

---

## Module Wiring Pattern

### `ImportApplicationModule` (application layer)

```typescript
// src/application/import/import.module.ts
const IMPORT_STRATEGIES = [CustomerImportStrategy, ProductImportStrategy] as const;

@Global()
@Module({
    imports: [TypeOrmInfrastructureModule, ImportEngineModule.forRootAsync()],
    providers: [
        // Saga (business logic + compensation)
        CustomerImportSaga,

        // Strategy (thin delegator)
        ...IMPORT_STRATEGIES,

        // Repository
        { provide: ICustomerRepository, useClass: CustomerRepository },

        // Factory — scans all strategies by moduleType
        {
            provide: ImportModuleProcessorFactory,
            useFactory: (...strategies: ImportModuleProcessor[]) => ({
                create: (module: string) => strategies.find((s) => s.moduleType === module),
            }),
            inject: [...IMPORT_STRATEGIES],
        },
    ],
    exports: [ImportModuleProcessorFactory],
})
export class ImportApplicationModule {}
```

> **Thêm module mới** → thêm 1 dòng trong `IMPORT_STRATEGIES` array. Factory tự pick up.

---

## Local Saga Compensation Pattern

Sử dụng **plain `@Injectable()`** (không extend `SagaDefinition`) vì compensation cần được trigger bởi local exception, không phải Kafka reply.

```
execute()
  ├── try { runPipeline() }
  │       → persist row → track id in state.persistedIds[]
  │       → soft fail (validate/duplicate) → accumulate state.errors[]
  └── after runPipeline:
        if (state.failedRows > 0)  → compensate() → deleteByIds(persistedIds)
        if (exception thrown)      → catch → compensate() → re-throw
```

> **Rule**: `SagaDefinition` + `SagaManager` từ `libs/src/ddd/saga` dùng cho **Kafka-based distributed saga** (multi-service). Không dùng cho single-service import rollback — dùng pattern try/catch trực tiếp.

---

## Checklist khi tạo module import mới

- [ ] Tạo `XxxImportSaga` (`@Injectable`, có `execute()` + `compensate()`)
- [ ] Tạo `XxxImportStrategy` (implement `ImportModuleStrategy`, delegate to saga)
- [ ] Thêm `XxxImportSaga` và `XxxImportStrategy` vào `IMPORT_STRATEGIES` const
- [ ] Inject `IXxxRepository` vào saga
- [ ] Thêm `deleteByIds(ids: string[]): Promise<void>` vào repository interface + TypeORM impl
- [ ] `createWithRelations()` phải return `Promise<string>` (ID của record đã create)
- [ ] Validate format + DB uniqueness trước khi persist
- [ ] `onProgress` callback được gọi sau mỗi row thành công

## Tài liệu liên quan

- **Flow chi tiết**: `@.claude/skills/stream-pipeline/import/FLOW.md`
- **Example code đầy đủ**: `@.claude/skills/stream-pipeline/import/EXAMPLE.md`
- **Stream pipeline base**: `@.claude/skills/stream-pipeline/SKILL.md`
- **Source**: `libs/src/common/modules/import-engine/`
- **Reference impl**: `src/application/import/` (customer module)
