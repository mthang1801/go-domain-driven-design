---
name: stream-pipeline
description: Stream pipeline and async generator for big data processing. Use when handling large datasets, export reports, or processing data that would cause memory issues. Avoids loading entire datasets into memory.
---

# Big Data Stream Pipeline

Xử lý big data bằng **stream pipeline** hoặc **async generator** để tối ưu memory và hiệu suất. Không load toàn bộ dataset vào RAM.

## Khi nào dùng

| Tình huống               | Cách xử lý                        |
| ------------------------ | --------------------------------- |
| Dataset > 10k records    | Stream pipeline / Async generator |
| Export CSV/Excel lớn     | Stream qua Report module          |
| Query cursor-based từ DB | Stream thay vì `find()`           |
| Heap out of memory       | Giảm batch, tăng threshold commit |

## Stream Pipeline Module

**Path**: `libs/src/common/modules/stream-pipeline`

### AsyncGeneratorPipelineBuilder

Chain các operation trên async iterable (map, filter, batch, flatMap, skip, take). Tối ưu memory vì xử lý từng item/ batch.

```typescript
import { StreamPipelineService } from '@common/modules/stream-pipeline';
import { Readable } from 'node:stream';

// Từ Readable stream (vd: DB cursor stream)
const builder = this.streamPipelineService.createAsyncGeneratorBuilder<T>(readable);

builder
    .map((item) => transform(item))
    .filter((item) => isValid(item))
    .batch(1000)
    .pipe(destination);
```

### Các method chính

| Method                           | Mục đích                       |
| -------------------------------- | ------------------------------ |
| `map(mapper)`                    | Transform từng item            |
| `filter(predicate)`              | Lọc item                       |
| `batch(size)`                    | Nhóm thành batch (giảm I/O)    |
| `flatMap(mapper)`                | Flatten kết quả                |
| `skip(n)` / `take(n)`            | Pagination                     |
| `toReadable(objectMode)`         | Chuyển sang Node Readable      |
| `pipe(destination)`              | Pipe tới Writable              |
| `toCsv(columns, filename, res)`  | Export stream → CSV response   |
| `toXlsx(columns, filename, res)` | Export stream → Excel response |

### createStreamPipelineBuilderSafe

Tự động transform input (object, array, stream) thành stream phù hợp:

```typescript
const builder = this.streamPipelineService.createStreamPipelineBuilderSafe(input, {
    objectMode: true,
});
const stream = await builder.getStream();
```

## Transforms có sẵn

- `BatchTransform`, `CsvParserTransform`, `CsvStringifyTransform`
- `ExcelRowTransform`, `FilterTransform`, `MapTransform`
- `ThrottleTransform`, `JsonParserTransform`, `JsonStringifyTransform`

## Nguyên tắc

1. **Không `await array` cho big data** – dùng cursor/stream.
2. **Batch processing** – xử lý theo chunk (vd: 1000 records).
3. **Generator / async iterator** – yield từng item thay vì build array.
4. **Pipe trực tiếp** – stream → transform → writable (file, response).

## Tài liệu chi tiết

- `libs/src/common/modules/stream-pipeline/` – interfaces, services, transforms
- `libs/src/common/modules/report/docs/stream-optimization.md`
- `libs/src/common/modules/report/docs/memory-optimization.md`
