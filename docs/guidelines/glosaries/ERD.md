# ERD — Entity-Relationship Diagram

> **Viết tắt**: ERD · **Tương đương**: Data Model Diagram  
> **Ngữ cảnh**: Thuộc LLD — mô hình hóa dữ liệu của hệ thống

---

## ① DEFINE

### Định nghĩa

**ERD (Entity-Relationship Diagram)** là sơ đồ biểu diễn **các thực thể (entities)**, **thuộc tính (attributes)**, và **mối quan hệ (relationships)** giữa chúng trong database. ERD là nền tảng cho database schema design.

### Các thành phần ERD

| Thành phần | Ký hiệu | Ví dụ |
|------------|---------|-------|
| **Entity** | Hình chữ nhật | `User`, `Order`, `Product` |
| **Attribute** | Oval / cột | `id`, `email`, `created_at` |
| **Relationship** | Hình thoi / đường nối | `User — places → Order` |
| **Cardinality** | 1:1, 1:N, N:M | `User 1──N Order` |
| **Primary Key (PK)** | Gạch chân | `id` |
| **Foreign Key (FK)** | Mũi tên | `order.user_id → user.id` |

### Các loại Cardinality

| Ký hiệu | Nghĩa | Ví dụ |
|----------|-------|-------|
| `1 ── 1` | One-to-One | User ── UserProfile |
| `1 ── N` | One-to-Many | User ── Orders |
| `N ── M` | Many-to-Many | Student ── Courses (qua junction table) |

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| Thiếu normalization | Dữ liệu trùng lặp, inconsistent | Đạt ít nhất 3NF |
| Quên indexes | Query chậm khi data lớn | Phân tích query patterns |
| N:M không có junction table | Không thể model relationship | Tạo bảng trung gian |

---

## ② GRAPH

### Ví dụ: ERD cho FoodApp

```
┌──────────────┐     1    N    ┌──────────────┐
│    users     │──────────────▶│   orders     │
├──────────────┤               ├──────────────┤
│ PK id        │               │ PK id        │
│    email     │               │ FK user_id   │
│    phone     │               │ FK restaurant│
│    password  │               │    status    │
│    status    │               │    total     │
│    created_at│               │    created_at│
└──────────────┘               └───────┬──────┘
                                       │ 1
                                       │
                                       │ N
                               ┌───────▼──────┐
                               │ order_items  │
                               ├──────────────┤
                               │ PK id        │
                               │ FK order_id  │
                               │ FK product_id│
                               │    quantity  │
                               │    price     │
                               └───────┬──────┘
                                       │ N
                                       │
                                       │ 1
┌──────────────┐               ┌───────▼──────┐
│ categories   │ 1          N  │  products    │
├──────────────┤──────────────▶├──────────────┤
│ PK id        │               │ PK id        │
│    name      │               │ FK category  │
│    slug      │               │    name      │
└──────────────┘               │    price     │
                               │    image_url │
                               └──────────────┘
```

### Cardinality Notation (Crow's Foot)

```
  1:1     ──────────── (one to one)
  1:N     ────────────< (one to many)
  N:M     >───────────< (many to many → cần junction table)
  0..1    ──────○───── (zero or one — optional)
  0..N    ──────○────< (zero or many — optional)
```

---

## ③ CODE

### SQL từ ERD

```sql
CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email      VARCHAR(255) UNIQUE NOT NULL,
    phone      VARCHAR(15) NOT NULL,
    password   VARCHAR(255) NOT NULL,
    status     VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE orders (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL,
    status        VARCHAR(20) DEFAULT 'pending',
    total         DECIMAL(12,2) NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE order_items (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id   UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity   INT NOT NULL CHECK (quantity > 0),
    price      DECIMAL(12,2) NOT NULL
);

-- N:M example — junction table
CREATE TABLE student_courses (
    student_id UUID REFERENCES students(id),
    course_id  UUID REFERENCES courses(id),
    enrolled_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (student_id, course_id)
);
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Thiếu ON DELETE strategy | Chọn CASCADE / SET NULL / RESTRICT |
| 2 | Dùng INT PK cho distributed | Dùng UUID hoặc ULID |
| 3 | Quên CHECK constraints | Thêm: `CHECK (quantity > 0)` |
| 4 | N:M không có junction table | Tạo bảng trung gian với composite PK |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| dbdiagram.io (ERD tool) | https://dbdiagram.io/ |
| PostgreSQL CREATE TABLE | https://www.postgresql.org/docs/current/sql-createtable.html |
| Database Normalization | https://en.wikipedia.org/wiki/Database_normalization |
