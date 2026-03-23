# 06 - Data Import Pipeline

> **Priority:** High | **Complexity:** High
> **Estimated Time:** 5-7 days

## Summary | Tóm tắt

**EN:** Establish a resilient, stream-based data import pipeline utilizing BullMQ for async processing and local Saga pattern for "all-or-nothing" rollback if rows fail validation. This ensures large CSV/Excel files don't crash the server.

**VI:** Thiết lập luồng import dữ liệu mạnh mẽ, dựa trên stream thông qua BullMQ để xử lý bất đồng bộ và sử dụng Local Saga pattern để rollback lại tất cả trạng thái nếu có lỗi xảy ra. Giúp files CSV/Excel lớn không làm sập server.

---

## Proposed Changes | Các thay đổi đề xuất

### 6.1 Application Module Setup

**File:** `src/application/data-builder/data-builder-application.module.ts`

**EN:**

- Import `ImportEngineModule.forRootAsync()` to register the streaming SDK.
- Create an array of `IMPORT_STRATEGIES` targeting the Visual Builder module.
- Register factories as instructed by `stream-pipeline/import/SKILL.md`.

**VI:**

- Gọi `ImportEngineModule.forRootAsync()` để đăng ký pipeline SDK xử lý stream.
- Tạo một mảng `IMPORT_STRATEGIES` cho module Visual Builder.
- Khai báo factories như trong chỉ dẫn `stream-pipeline/import/SKILL.md`.

### 6.2 Implementation of Local Saga

**Files:** `src/application/data-builder/sagas/data-builder-import.saga.ts`

**EN:**

- Create an `@Injectable()` Saga (do not use `SagaDefinition` since this is a local bounded-context transaction).
- Implement `execute(command: ImportProcessCommand)` to iterate through chunks.
- Store IDs of successfully persisted records in memory `state.persistedIds`.
- Implement `compensate()` to call `deleteByIds(state.persistedIds)` if ANY validation or database errors arise.

**VI:**

- Tạo một Saga `@Injectable()` (không dùng `SagaManager` vì ở đây là giao dịch nội bộ).
- Khai báo logic `execute(...)` để xử lý stream theo từng chunk nhỏ.
- Lưu trữ ID các record tạo thành công vào `state.persistedIds`.
- Khai báo `compensate()` để tiến hành xoá `deleteByIds` khi gặp lỗi bất ngờ.

### 6.3 Import Strategy

**File:** `src/application/data-builder/strategies/data-builder-import.strategy.ts`

**EN:**

- Implement `ImportModuleStrategy` interface.
- Set `moduleType` correctly so the Factory can pick it up.
- Delegate raw import commands into the `DataBuilderImportSaga`.

**VI:**

- Tuân thủ interface `ImportModuleStrategy`.
- Set đúng `moduleType` để ImportModuleProcessorFactory hiểu đăng kí.
- Bàn giao các command từ controller đến `DataBuilderImportSaga`.

## Verification | Xác minh

- Attempt importing a CSV file with 5,000 correctly formatted rows and 1 invalid row at the end. All 5,000 rows must be cleanly removed by the `compensate()` function.
- Process does not load more than configured stream chunk limits (e.g. 100 rows per batch) into memory.
