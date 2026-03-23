---
name: report-stream-export
description: >-
    Stream-based report export SDK (CSV, Excel, PDF) kết hợp SSE progress notification.
    Dùng khi xây dựng tính năng export báo cáo với big data, push-to-file, hoặc stream-to-HTTP.
    Trigger: export report, stream CSV, stream Excel, download báo cáo, SSE progress, report pipeline.
---

# Report Stream Export + SSE Progress

SDK export dữ liệu dạng stream kết hợp SSE (Server-Sent Events) thông báo tiến trình real-time.
Hỗ trợ big data, tránh heap OOM, và cung cấp UX tốt cho người dùng qua progress bar.

> **Xem file EXAMPLE.md** cùng thư mục để có code mẫu đầy đủ, copy-paste được.

## Architecture Overview

```
┌─────────┐     ┌───────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Client  │────▶│Controller │────▶│    UseCase        │────▶│ ReportService   │
│ (HTTP)  │     │ @Get()    │     │ (Application)     │     │ .render()       │
└────┬────┘     └───────────┘     │                   │     │                 │
     │                            │ 1. Define template│     │ Plugin dispatch │
     │                            │ 2. Define columns │     │ CSV / ExcelJS   │
     │                            │ 3. Create stream  │     └────────┬────────┘
     │                            │ 4. Set stream     │              │
     │                            └───────────────────┘              │
     │                                                               ▼
     │          ┌────────────────┐     ┌──────────────────────────────────┐
     │◀─────────│ SSE Endpoint   │◀────│ ReportProgressProcessor          │
     │  (SSE)   │ @Sse()         │     │ (Redis Pub/Sub → Observable)     │
     │          └────────────────┘     └──────────────────────────────────┘
     │
     │◀──────── HTTP Response (stream file download)
```

## Luồng xử lý 5 bước

| #   | Bước                                                 | Ai xử lý                | Ghi chú                                                       |
| --- | ---------------------------------------------------- | ----------------------- | ------------------------------------------------------------- |
| 1   | Client gọi `GET /report/csv/stream`                  | Controller              | Delegate xuống UseCase                                        |
| 2   | UseCase define template + columns + stream           | Application             | Dùng `ReportFactory` + TypeORM `$stream()`                    |
| 3   | `reportService.render(template)`                     | ReportServiceImpl       | Chọn plugin theo `template.format`, gọi `plugin.initialize()` |
| 4   | Plugin stream data → transform → write file/response | Plugin                  | CSV: zip nếu multi-sheet, single file nếu 1 sheet             |
| 5   | SSE push progress real-time                          | ReportProgressProcessor | Redis pub/sub → `@Sse('report/progress/:reportId')`           |

## Các layer chính

### 1. Controller Layer

Controller chỉ delegate, **không xử lý logic**:

```typescript
@Get('report/csv/stream')
@SwaggerApiResponse({ summary: 'Report' })
async reportCsvStream(@Query() query: FindAllQueryFilterDto) {
    return await this.reportCsvStreamUserUsecase.execute(query);
}
```

### 2. UseCase Layer (Application)

Đây là nơi define **toàn bộ cấu hình export**. UseCase có các trách nhiệm:

1. **Define Template** — tên report, thư mục lưu, tác giả
2. **Define Worksheet(s)** — columns (header, key, width, mapping, style)
3. **Create DB Stream** — sử dụng TypeORM QueryBuilder + `$stream()`
4. **Set Stream vào Sheet** — gắn readable stream cho plugin xử lý
5. **Gọi `reportService.render(template)`** — trả về `ReportResult`

**Quy ước private methods:**

| Method                | Mục đích                                        |
| --------------------- | ----------------------------------------------- |
| `createXxxTemplate()` | Tạo report template (CSV/ExcelJS)               |
| `createXxxSheet1()`   | Define cột, mapping, style cho sheet 1          |
| `createXxxSheet2()`   | Define cột, mapping, style cho sheet 2 (nếu có) |

**Column Definition API:**

```typescript
{
    header: 'Trạng thái',       // Tên cột hiển thị
    key: 'status',              // Key map với data từ DB
    width: 30,                  // Độ rộng cột (optional)
    mapping: {                  // Auto-map giá trị (optional)
        'ACTIVE': 'Hoạt động',
        'INACTIVE': 'Ngưng HĐ',
    },
    style: {                    // Number format (optional)
        numFmt: '#,##0.00'
    },
}
```

### 3. ReportService (Core libs)

**Path:** `libs/src/common/modules/report/services/report.service.ts`

`ReportServiceImpl.render()` là entry point. Nó:

1. Chọn plugin dựa trên `template.format` (CSV / ExcelJS / PDF)
2. Finalize temp files (nếu push-data mode)
3. Gọi `plugin.initialize(template)` → trả về `ReportResult[]`

### 4. SSE Progress Notification

**Cơ chế:** Redis Pub/Sub → `SseAdapterBase` → NestJS `@Sse()` endpoint

| Component                 | Vai trò                                           |
| ------------------------- | ------------------------------------------------- |
| `ReportProgressProcessor` | Extends `SseAdapterBase`, quản lý lifecycle SSE   |
| `ReportProgressService`   | In-memory progress map (processedCount, total)    |
| `ReportCommandService`    | Persist report entity vào DB (status, timestamps) |
| `ReportController @Sse()` | Expose SSE endpoint cho client subscribe          |

**SSE Endpoint:**

```
GET /v1/report/progress/:reportId
```

**Progress statuses:** `INIT` → `PROCESSING` → `SUCCESS` | `FAILED`

**Client subscribe ví dụ:**

```typescript
const eventSource = new EventSource(`/v1/report/progress/${correlationId}`);
eventSource.onmessage = (event) => {
    const progress = JSON.parse(event.data);
    // { status, processedCount, totalRecord, progressMsg, filePath }
    updateProgressBar((progress.processedCount / progress.totalRecord) * 100);
};
```

### 5. Factories

**Path:** `libs/src/common/modules/report/factories/report.factory.ts`

| Factory Method                                | Output                           |
| --------------------------------------------- | -------------------------------- |
| `ReportFactory.createReportCsvTemplate()`     | `ReportCsvTemplate`              |
| `ReportFactory.createReportCsvWorksheet()`    | `ReportCsvWorksheetTemplate`     |
| `ReportFactory.createReportExceljsTemplate()` | `ReportExceljsTemplate`          |
| `ReportFactory.createExceljsWorksheet()`      | `ReportExceljsWorksheetTemplate` |

## Hai chế độ data source

| Mode               | Khi nào                  | Cách hoạt động                                                   |
| ------------------ | ------------------------ | ---------------------------------------------------------------- |
| **Stream Mode**    | Data vừa đủ RAM          | `$stream({ usePgQueryStream: true })` → `setStream()`            |
| **Push-Data Mode** | Data quá lớn, phân trang | `pushDataToTempFile()` → temp NDJSON → `setStreamFromTempFile()` |

## Tối ưu memory (ExcelJS)

```typescript
{
    threshold: 500,      // Commit mỗi 500 rows
    batchSize: 100,      // Batch size khi đọc stream
    highWaterMark: 50,   // Backpressure control
    memoryLimit: 150,    // MB limit
    gcInterval: 1000,    // Force GC mỗi N rows
}
```

## Checklist khi tạo export mới

- [ ] Tạo UseCase extends pattern từ EXAMPLE.md
- [ ] Define columns với header/key/mapping/style
- [ ] Tạo DB stream bằng `$stream({ usePgQueryStream: true })`
- [ ] Set stream vào worksheet
- [ ] Gọi `reportService.render(template)`
- [ ] Thêm route mới vào Controller
- [ ] Test với dataset lớn (>10k records)
- [ ] Verify SSE progress hoạt động đúng
