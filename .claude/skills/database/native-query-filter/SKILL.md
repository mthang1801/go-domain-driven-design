---
name: native-query-filter
description: Integrates TypeORM and native PL/pgSQL get_filtered_list for dynamic list APIs. Use when building list endpoints with filters, pagination, joins; optimizing slow queries with raw SQL; or adding new entity config templates for dynamic query building.
---

# Native PL/pgSQL Dynamic Query Filter

Kết hợp **TypeORM** (`@core/database/typeorm`) và **native SQL** (`get_filtered_list`) cho list API với filter động, pagination, joins. Config tĩnh (YAML) + runtime filters (DTO).

## Khi nào dùng gì

| Use case | Chọn |
|----------|------|
| List đơn giản, ít filter | TypeORM Builder (`query.guide.md`) |
| List phức tạp, nhiều filter/join, cần tối ưu | Native `get_filtered_list` |
| Transaction, persist, domain mapping | TypeORM Repository (`persistence.guide.md`) |
| Slow query, cần giảm ORM overhead | Native `get_filtered_list` |

## Kiến trúc tổng quan

```
Config (YAML/JSON) – template tĩnh, load 1 lần
    ↓
p_filters (DTO) – key-value động từ request
    ↓
get_filtered_list(p_config, p_filters, p_pagination)
    ↓
RETURNS TABLE (data JSONB, total_count BIGINT)
```

**Config** định nghĩa: entity, select, joins, filters (key → column + op), between_pairs, order_by.  
**p_filters** là key-value từ request: `{ status: "ACTIVE", name: "Hương", createdFrom: "2026-01-01" }`.  
Mỗi key trong p_filters phải có config trong filters (whitelist → bảo mật).

## File locations

| Thành phần | Path |
|------------|------|
| TypeORM module | `libs/src/core/database/typeorm/typeorm.module.ts` |
| Core SQL path | `libs/src/core/database/typeorm/sql/` |
| Helpers | `sql/helpers/` (fn_build_where_tree, fn_filter_operator, fn_validate_filter_key, fn_sanitize_identifier) |
| Core function | `sql/functions/get_filtered_list.function.sql` |
| Config templates | `config/templates/` (bank.yaml, agreement.yaml, customer.yaml, schema.yaml) |
| Constant | `constants/typeorm.constant.ts` → `CORE_SQL_PATH` |

## Workflow: Thêm entity config mới

1. Copy template có sẵn (vd: `config/templates/bank.yaml`).
2. Sửa `entity.table`, `select`, `joins`, `filters`, `between_pairs`, `order_by`.
3. Load YAML → JSON tại runtime: `yaml.load(content)` hoặc `JSON.parse(JSON.stringify(...))`.
4. Truyền vào `get_filtered_list(p_config, p_filters, p_pagination)`.

Chi tiết schema config: [reference.md](reference.md).

## Workflow: Gọi get_filtered_list từ NestJS

Dùng **FilteredListBuilder** (config load 1 lần, cache; DTO sanitize theo allow/deny):

```typescript
import { FilteredListBuilder } from '@core/database/typeorm';
import { DataSource } from 'typeorm';

const [configJson, filtersJson, paginationJson] = FilteredListBuilder
    .fromConfigPath(configPath)
    .withFilters(filters)
    .deny('propKhongMongMuon')   // optional – loại trừ key cụ thể
    .withPagination(page, limit)
    .toQueryParams();

const rows = await this.dataSource.query(
    `SELECT * FROM get_filtered_list($1::jsonb, $2::jsonb, $3::jsonb)`,
    [configJson, filtersJson, paginationJson],
);
```

- **Allowed keys**: Tự lấy từ config (`filters` + `between_pairs` from_key/to_key)
- **deny(...keys)**: Loại trừ key không mong muốn
- Config được cache (không load lại mỗi request)

## DTO → SQL mapping (flat mode)

| DTO pattern | Config | SQL |
|-------------|--------|-----|
| `{ status: "ACTIVE" }` | `status: { op: eq }` | `WHERE status = 'ACTIVE'` |
| `{ name: "Hương" }` | `name: { op: ilike }` | `WHERE name ILIKE '%Hương%'` |
| `{ fromDate, toDate }` | `between_pairs: [{ from_key: createdFrom, to_key: createdTo, column: created_at }]` | `BETWEEN $1 AND $2` |
| `{ keyword: "x" }` | `keyword: { op: ilike, column: name }` | Search trong cột khác |
| `{ ids: [1,2,3] }` | `ids: { op: in }` (nếu hỗ trợ) | `WHERE id = ANY($1)` |

Config là whitelist: key không có trong config → bỏ qua (không inject SQL).

## Bảo mật

- **Whitelist**: Chỉ các key có trong `filters` mới được xử lý. Tên bảng/cột lấy từ config, không từ input.
- **Parameterized**: Giá trị truyền qua `USING` / `$1`, `$2`. Không nối chuỗi giá trị vào SQL.
- **fn_sanitize_identifier**: Validate/escape identifier trong PL/pgSQL.

## Luồng xử lý trong get_filtered_list

1. Load config (entity.table, alias).
2. Validate: `fn_validate_filter_key` cho từng key trong p_filters.
3. Build SELECT từ config.select.
4. Build JOIN từ config.joins.
5. Build WHERE: với mỗi (key, value) trong p_filters, tra config → column + op → SQL fragment; kết hợp với `between_pairs`, `where_tree` nếu có.
6. EXECUTE dynamic SQL với USING.
7. RETURN data, total_count.

## Hai chế độ filter

- **Flat mode** (mặc định): Mỗi key trong p_filters có config trong filters → thêm điều kiện WHERE. `logic`: AND | OR | NOT.
- **where_tree mode**: Cấu trúc cây đệ quy Leaf/Branch. Dùng khi cần logic phức tạp `(A AND B) OR NOT(C)`. Xem [reference.md](reference.md).

## Pagination

`p_pagination`: `{ page: 1, limit: 20 }`. Limit tối đa 100.

## Tài liệu chi tiết

- [reference.md](reference.md) – Schema config, bảng operators, where_tree, ví dụ.
- `libs/src/core/database/typeorm/sql/README.md` – Chi tiết function, thứ tự load script.
- `libs/src/core/database/typeorm/config/README.md` – Cách dùng template.
- [query.guide.md](../query.guide.md) – TypeORM builder cho list đơn giản.
- [transaction-guide.md](../transaction-guide.md) – Transaction boundaries and persistence concerns.
