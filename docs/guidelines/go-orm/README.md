# 🗄️ GORM — Go ORM Library

> **Mục đích**: Hướng dẫn toàn diện sử dụng GORM trong Go, từ cơ bản đến nâng cao.  
> **Cấu trúc**: Mỗi topic có file detail riêng theo format ① DEFINE → ② GRAPH → ③ CODE → ④ PITFALLS → ⑤ REF.

---

## GORM là gì?

**GORM** là ORM (Object-Relational Mapping) library phổ biến nhất cho Go. Map Go structs sang database tables, cung cấp API cho CRUD, associations, transactions, hooks, migrations.

```
go get -u gorm.io/gorm
go get -u gorm.io/driver/postgres  # hoặc sqlite, mysql, sqlserver
```

---

## 📑 Mục lục

### Nền tảng

| # | Topic | Mô tả ngắn | Detail |
|---|-------|-------------|--------|
| 1 | **Models & Connection** | Khai báo models, kết nối DB, conventions, gorm.Model | [→ 01-models-and-connection.md](./01-models-and-connection.md) |
| 2 | **CRUD Operations** | Create, Read, Update, Delete — Traditional + Generics API | [→ 02-crud.md](./02-crud.md) |
| 3 | **Querying** | Where, conditions, select, order, limit, joins, preload | [→ 03-querying.md](./03-querying.md) |

### Nâng cao

| # | Topic | Mô tả ngắn | Detail |
|---|-------|-------------|--------|
| 4 | **Associations** | Has One, Has Many, Belongs To, Many2Many, Preload, Joins | [→ 04-associations.md](./04-associations.md) |
| 5 | **Transactions & Hooks** | Transaction, nested tx, savepoint, hooks (Before/After) | [→ 05-transactions-and-hooks.md](./05-transactions-and-hooks.md) |
| 6 | **Migration & Advanced** | AutoMigrate, scopes, raw SQL, performance, connection pool | [→ 06-migration-and-advanced.md](./06-migration-and-advanced.md) |

---

## 🗺️ Thứ tự học

```
① Models & Connection ──▶ ② CRUD ──▶ ③ Querying
                                          │
                                          ▼
              ④ Associations ──▶ ⑤ Transactions & Hooks ──▶ ⑥ Advanced
```

---

## Supported Databases

| Database | Driver | Install |
|----------|--------|---------|
| PostgreSQL | `gorm.io/driver/postgres` | `go get -u gorm.io/driver/postgres` |
| MySQL | `gorm.io/driver/mysql` | `go get -u gorm.io/driver/mysql` |
| SQLite | `gorm.io/driver/sqlite` | `go get -u gorm.io/driver/sqlite` |
| SQL Server | `gorm.io/driver/sqlserver` | `go get -u gorm.io/driver/sqlserver` |
