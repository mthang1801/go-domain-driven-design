# LLD — Low-Level Design

> **Viết tắt**: LLD  
> **Ngữ cảnh**: Sau HLD — thiết kế chi tiết cấp code để developer implement

---

## ① DEFINE

### Định nghĩa

**LLD (Low-Level Design)** là tài liệu thiết kế **chi tiết ở mức code**: class diagrams, database schema, algorithms, API contracts, và sequence diagrams. LLD trả lời **"Code được VIẾT thế nào?"**.

### Phân biệt LLD vs HLD

| Tiêu chí | LLD | HLD |
|----------|-----|-----|
| **Mức độ** | Code-level, chi tiết | Bird's eye view |
| **Nội dung** | Class, method, schema, algorithm | Module, service, tech choice |
| **Đối tượng** | Developer | Architect, PM |
| **Output** | Code template có thể implement ngay | Architecture diagram |

### Actors

| Actor | Vai trò |
|-------|---------|
| **Senior Developer** | Viết LLD |
| **Tech Lead** | Review LLD |
| **Developer** | Implement theo LLD |
| **QA** | Dùng LLD để viết unit tests |

### Invariants

- LLD phải **map 1:1** với HLD modules
- Mỗi class/interface phải có **responsibility rõ ràng** (Single Responsibility)
- Database schema phải **normalized** (hoặc có lý do denormalize)
- API contracts phải có **request/response schema** cụ thể

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| LLD quá rigid | Dev không thể adapt khi requirement thay đổi | Thiết kế interfaces, không concrete |
| Thiếu error handling | Code chỉ handle happy path | Mô tả error cases trong LLD |
| Schema không có index | Queries chậm khi data lớn | Kèm index strategy trong LLD |

---

## ② GRAPH

### Cấu trúc LLD

```
LLD Document
├── 1. Class Diagrams
│   ├── User class (fields, methods)
│   ├── Order class
│   └── Interfaces & Abstractions
├── 2. Database Schema
│   ├── ERD
│   ├── Table definitions + indexes
│   └── Migration strategy
├── 3. API Contracts
│   ├── Request/Response schemas
│   ├── Error codes
│   └── Authentication flow
├── 4. Sequence Diagrams
│   └── Key flows (login, place order, payment)
├── 5. Algorithm Details
│   └── Search ranking, pricing, matching
└── 6. Error Handling Strategy
    └── Error codes, retry, fallback
```

### Ví dụ: Sequence Diagram — Place Order

```
User          API Gateway    Order Service    Payment       DB
 │                │              │               │          │
 │── POST /order─▶│              │               │          │
 │                │── validate ─▶│               │          │
 │                │              │── check stock─────────▶ │
 │                │              │◀── ok ──────────────────│
 │                │              │── charge ────▶│          │
 │                │              │◀── success ──│          │
 │                │              │── save order─────────▶  │
 │                │              │◀── ok ──────────────────│
 │◀── 201 Created─│◀─────────── │               │          │
```

---

## ③ CODE

### Ví dụ: Database Schema (PostgreSQL)

```sql
-- LLD: Users table
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       VARCHAR(255) NOT NULL UNIQUE,
    phone       VARCHAR(15) NOT NULL,
    password    VARCHAR(255) NOT NULL,  -- bcrypt hash
    status      VARCHAR(20) DEFAULT 'pending', -- pending | active | blocked
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);

-- LLD: Orders table
CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    restaurant_id   UUID NOT NULL,
    status          VARCHAR(20) DEFAULT 'pending',
    total_amount    DECIMAL(12,2) NOT NULL,
    delivery_fee    DECIMAL(12,2) DEFAULT 0,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
```

### Ví dụ: Go Interface Design

```go
// LLD: Repository interface — dependency inversion
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    FindByEmail(ctx context.Context, email string) (*User, error)
    FindByID(ctx context.Context, id uuid.UUID) (*User, error)
    Update(ctx context.Context, user *User) error
}

// LLD: Service layer
type AuthService struct {
    userRepo UserRepository
    hasher   PasswordHasher
    jwt      JWTManager
}

func (s *AuthService) Register(ctx context.Context, req RegisterRequest) (*User, error) {
    // 1. Validate input
    // 2. Check email uniqueness
    // 3. Hash password
    // 4. Save user
    // 5. Send OTP
}
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Schema không có indexes | Phân tích query patterns, thêm index |
| 2 | Thiếu error handling design | Mỗi API phải có error response schema |
| 3 | God class (class quá lớn) | Áp dụng SOLID, tách responsibility |
| 4 | Hardcode business rules | Extract thành config hoặc strategy pattern |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Clean Architecture (Uncle Bob) | https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html |
| Domain-Driven Design (Eric Evans) | https://www.domainlanguage.com/ddd/ |
| Database Design for Mere Mortals | ISBN: 978-0321884497 |
