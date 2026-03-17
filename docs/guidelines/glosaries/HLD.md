# HLD — High-Level Design

> **Viết tắt**: HLD  
> **Ngữ cảnh**: Sau SRS, trước LLD — thiết kế kiến trúc tổng quan

---

## ① DEFINE

### Định nghĩa

**HLD (High-Level Design)** là tài liệu thiết kế **kiến trúc tổng quan** của hệ thống: modules/services chính, cách giao tiếp, tech stack, và deployment. HLD trả lời **"Hệ thống được TỔ CHỨC thế nào?"** ở bird's eye view.

### Phân biệt HLD vs LLD

| Tiêu chí | HLD | LLD |
|----------|-----|-----|
| **Mức độ** | Bird's eye view | Chi tiết code-level |
| **Nội dung** | Modules, services, APIs, DB choice | Classes, methods, DB schema, algorithms |
| **Đối tượng** | Architect, PM, Tech Lead | Developer |
| **Ví dụ** | "Auth Service → PostgreSQL" | "class User { bcrypt hash, JWT }" |

### Actors

| Actor | Vai trò |
|-------|---------|
| **Solution Architect** | Viết HLD, chọn tech stack |
| **Tech Lead** | Review và approve |
| **DevOps** | Review deployment/infra |

### Invariants

- Phải bao phủ **tất cả modules** trong SRS
- Mỗi module phải có **interface rõ ràng**
- Phải nêu **tech choices + rationale**
- Bao gồm **deployment architecture**

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| Over-engineering | Microservices cho team 2 người | Bắt đầu Modular Monolith |
| Thiếu rationale | "Dùng MongoDB" mà không nói tại sao | Mỗi tech kèm lý do |
| Quên deployment | Chỉ có code architecture | Bao gồm infra, CI/CD, monitoring |

---

## ② GRAPH

### Cấu trúc HLD

```
HLD Document
├── 1. System Overview & Context Diagram
├── 2. Architecture Style (Monolith / Microservices / Event-Driven)
├── 3. Module Decomposition
│   ├── Module 1: Auth Service
│   ├── Module 2: Order Service
│   └── Module 3: Payment Service
├── 4. Data Architecture (DB choices, data flow)
├── 5. API Design (REST / gRPC / GraphQL)
├── 6. Technology Stack + Rationale
├── 7. Deployment Architecture
└── 8. Security Architecture
```

### Ví dụ: Microservices Architecture

```
                     ┌─────────────┐
                     │   Client    │
                     └──────┬──────┘
                            │ HTTPS
                     ┌──────▼──────┐
                     │ API Gateway │
                     └──┬───┬───┬──┘
           ┌────────────┘   │   └────────────┐
           ▼                ▼                 ▼
    ┌────────────┐  ┌────────────┐   ┌────────────┐
    │Auth Service│  │Order       │   │Payment     │
    │ • Login    │  │Service     │   │Service     │
    │ • Register │  │ • CRUD     │   │ • Charge   │
    └─────┬──────┘  └─────┬──────┘   └─────┬──────┘
          ▼               ▼                 ▼
    ┌──────────┐   ┌──────────┐      ┌──────────┐
    │PostgreSQL│   │PostgreSQL│      │  Stripe   │
    └──────────┘   └──────────┘      └──────────┘
```

---

## ③ CODE

```yaml
system_name: "FoodApp v1.0"
architecture_style: "Microservices + Event-Driven"

modules:
  - name: Auth Service
    technology: "Go (Fiber)"
    database: "PostgreSQL"
    api: ["POST /auth/register", "POST /auth/login"]

  - name: Order Service
    technology: "Go (Fiber)"
    database: "PostgreSQL"
    events_published: ["order.created", "order.completed"]

technology_stack:
  backend: "Go 1.22"
  database: "PostgreSQL 16, Redis 7"
  ci_cd: "GitHub Actions → Docker → K8s"
  monitoring: "Grafana + Prometheus"
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Over-engineering | Bắt đầu Modular Monolith, tách sau |
| 2 | Tech choices không có rationale | Mỗi choice kèm lý do + alternatives |
| 3 | Thiếu security architecture | Luôn bao gồm AuthN/AuthZ/Encryption |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| System Design Primer | https://github.com/donnemartin/system-design-primer |
| C4 Model | https://c4model.com/ |
