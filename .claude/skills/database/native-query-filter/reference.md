# Native Query Filter – Reference

## Config schema (schema.yaml)

```yaml
entity:
  table: string      # required
  alias: string      # optional, default 't'

select:              # optional, empty → alias.*
  - field: string    # required
    alias: string    # optional
    from_join: string # optional – join alias

joins:               # optional
  - table: string
    alias: string
    type: LEFT | INNER | RIGHT
    on: string       # e.g. "a.entity_id = j.id"

filters:             # DTO key → config
  <dto_key>:
    column: string   # optional, default = dto_key (snake_case)
    op: eq | ne | ilike | like | gt | gte | lt | lte | is_null | is_not_null | between
    from_join: string # optional
    logic: AND | OR | NOT  # default AND

where_tree:          # optional – overrides flat filters when present
  logic: AND | OR | NOT
  conditions: []     # Leaf or Branch nodes

between_pairs:       # optional
  - from_key: string
    to_key: string
    column: string
    from_join: string # optional

order_by:
  field: string
  direction: ASC | DESC
```

## Operators

| op | SQL | Notes |
|----|-----|-------|
| `eq` | `= value` | Default |
| `ne` | `!= value` | |
| `ilike` | `ILIKE '%value%'` | Case-insensitive |
| `like` | `LIKE '%value%'` | Case-sensitive |
| `gt` | `> value` | |
| `gte` | `>= value` | |
| `lt` | `< value` | |
| `lte` | `<= value` | |
| `is_null` | `IS NULL` | Key in p_filters, value ignored |
| `is_not_null` | `IS NOT NULL` | Key in p_filters, value ignored |
| `between` | `BETWEEN a AND b` | Via between_pairs config |

## where_tree structure

**Leaf** (điều kiện đơn):

```yaml
filter: status   # key in p_filters, must exist in filters
op: eq           # operator
```

**Branch** (nhóm logic):

```yaml
logic: OR        # AND | OR | NOT
conditions:      # array of Leaf or Branch
  - filter: status
    op: is_null
  - logic: AND
    conditions:
      - filter: amount
        op: gt
```

Ví dụ biểu thức: `(status IS NULL AND amount > 0) OR NOT(status = 'ACTIVE')`  
→ Xem `config/templates/agreement-with-where-tree.yaml.example`.

## FilteredListBuilder

**Path**: `libs/src/core/database/typeorm/builder/filtered-list.builder.ts`

- `fromConfigPath(path)` / `fromConfig(config)` – khởi tạo, config cache tự động
- `withFilters(dto)` – truyền filters từ DTO
- `deny(...keys)` – loại trừ key (override allowlist)
- `withPagination(page, limit)` – pagination
- `toQueryParams()` – `[configJson, filtersJson, paginationJson]` cho get_filtered_list

Allowed keys mặc định = keys từ `config.filters` + `from_key`/`to_key` từ `between_pairs`.

## Function signature

```sql
get_filtered_list(
  p_config     JSONB,   -- Config từ YAML/JSON
  p_filters    JSONB,   -- {"status":"ACTIVE","name":"Hương"}
  p_pagination JSONB,   -- {"page":1,"limit":20}
  p_raw_filters JSONB   -- reserved, default '[]'
) RETURNS TABLE (data JSONB, total_count BIGINT)
```

## Templates

- `config/templates/schema.yaml` – Schema definition
- `config/templates/bank.yaml` – Flat mode example
- `config/templates/agreement.yaml` – Flat mode with between_pairs
- `config/templates/agreement-with-where-tree.yaml.example` – where_tree nested logic
- `config/templates/customer.yaml` – Customer entity

## SQL load order

1. `sql/helpers/` – fn_sanitize_identifier, fn_validate_filter_key, fn_filter_operator, fn_build_where_tree
2. `sql/functions/` – get_filtered_list

TypeORM module loads `CORE_SQL_PATH` first; app paths after.
