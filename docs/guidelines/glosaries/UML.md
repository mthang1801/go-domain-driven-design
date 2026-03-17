# UML — Unified Modeling Language

> **Viết tắt**: UML · **Version hiện tại**: UML 2.5  
> **Ngữ cảnh**: Ngôn ngữ mô hình hóa chuẩn cho thiết kế phần mềm

---

## ① DEFINE

### Định nghĩa

**UML (Unified Modeling Language)** là ngôn ngữ mô hình hóa trực quan chuẩn hóa, dùng để **đặc tả, trực quan hóa, và tài liệu hóa** kiến trúc phần mềm. UML gồm 14 loại diagram, chia thành 2 nhóm: **Structure** (tĩnh) và **Behavior** (động).

### 14 Loại Diagram UML

| Nhóm | Diagram | Dùng khi |
|------|---------|---------|
| **Structure** | Class Diagram | Thiết kế classes + relationships |
| | Component Diagram | Module decomposition |
| | Deployment Diagram | Infra + deployment |
| | Object Diagram | Snapshot trạng thái objects |
| | Package Diagram | Tổ chức packages/modules |
| | Composite Structure | Internal structure |
| | Profile Diagram | Extend UML |
| **Behavior** | Use Case Diagram | Actor + chức năng |
| | Activity Diagram | Flow / workflow |
| | Sequence Diagram | Thứ tự tương tác |
| | State Machine | Trạng thái object |
| | Communication Diagram | Tương tác giữa objects |
| | Timing Diagram | Thời gian |
| | Interaction Overview | Tổng quan interactions |

### 5 Diagram hay dùng nhất

| # | Diagram | Giai đoạn | Trả lời |
|---|---------|-----------|---------|
| 1 | **Use Case** | BRS/SRS | Hệ thống có những chức năng gì? |
| 2 | **Class** | LLD | Code được tổ chức thế nào? |
| 3 | **Sequence** | LLD | Các object tương tác ra sao? |
| 4 | **Activity** | FRS | Quy trình chạy thế nào? |
| 5 | **Deployment** | HLD | Deploy trên infra thế nào? |

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| Vẽ quá nhiều diagram | Mất thời gian, không ai đọc | Chỉ vẽ 3-5 diagrams cần thiết |
| Diagram không match code | UML outdated sau vài sprint | Auto-generate hoặc update mỗi sprint |
| Quá chi tiết | Diagram 100 classes, rối | Chia theo module, mỗi diagram ≤ 10 entities |

---

## ② GRAPH

### Use Case Diagram

```
┌─────────────────────────────────────────┐
│              FoodApp System             │
│                                         │
│  ┌─────────────────┐                    │
│  │ Đăng ký/Đăng nhập│◄──── Customer     │
│  └─────────────────┘       (Actor)      │
│  ┌─────────────────┐          │         │
│  │  Tìm kiếm món   │◄─────────┤         │
│  └─────────────────┘          │         │
│  ┌─────────────────┐          │         │
│  │   Đặt hàng      │◄─────────┘         │
│  └─────────────────┘                    │
│  ┌─────────────────┐                    │
│  │  Quản lý menu   │◄──── Restaurant    │
│  └─────────────────┘       (Actor)      │
│  ┌─────────────────┐                    │
│  │  Quản lý users  │◄──── Admin         │
│  └─────────────────┘       (Actor)      │
└─────────────────────────────────────────┘
```

### Class Diagram (simplified)

```
┌──────────────────┐       ┌──────────────────┐
│     <<class>>    │       │     <<class>>    │
│       User       │       │      Order       │
├──────────────────┤  1  N ├──────────────────┤
│ - id: UUID       │──────▶│ - id: UUID       │
│ - email: string  │       │ - userId: UUID   │
│ - password: hash │       │ - status: enum   │
├──────────────────┤       │ - total: decimal │
│ + register()     │       ├──────────────────┤
│ + login()        │       │ + create()       │
│ + verify()       │       │ + cancel()       │
└──────────────────┘       │ + updateStatus() │
                           └──────────────────┘
```

### State Machine — Order Status

```
                    ┌─────────┐
     create()──────▶│ PENDING │
                    └────┬────┘
                         │ restaurant.accept()
                    ┌────▼────┐
                    │ACCEPTED │
                    └────┬────┘
                         │ start.cooking()
                    ┌────▼────┐
                    │PREPARING│
                    └────┬────┘
                         │ driver.pickup()
                    ┌────▼────┐
                    │DELIVERING│
                    └────┬────┘
                         │ driver.delivered()
                    ┌────▼────┐
                    │COMPLETED│
                    └─────────┘

  Bất kỳ state nào (trừ COMPLETED) ──cancel()──▶ CANCELLED
```

---

## ③ CODE

### Mermaid (render trong Markdown)

```
classDiagram
    class User {
        +UUID id
        +String email
        +String password
        +register()
        +login()
    }
    class Order {
        +UUID id
        +UUID userId
        +String status
        +Decimal total
        +create()
        +cancel()
    }
    User "1" --> "*" Order : places
```

### PlantUML (sequence diagram)

```
@startuml
actor User
participant "API Gateway" as GW
participant "Auth Service" as Auth
database "PostgreSQL" as DB

User -> GW: POST /auth/login
GW -> Auth: validate credentials
Auth -> DB: SELECT * FROM users WHERE email=?
DB --> Auth: user record
Auth --> GW: JWT token
GW --> User: 200 OK {token}
@enduml
```

---

## ④ PITFALLS

| # | Lỗi | Fix |
|---|------|-----|
| 1 | Vẽ ALL 14 diagrams | Chỉ 3-5 diagrams cần thiết |
| 2 | UML outdated | Auto-generate từ code hoặc update mỗi sprint |
| 3 | Quá chi tiết | Mỗi diagram ≤ 10 entities |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| UML 2.5 Spec | https://www.omg.org/spec/UML/2.5 |
| PlantUML | https://plantuml.com/ |
| Mermaid | https://mermaid.js.org/ |
| draw.io | https://app.diagrams.net/ |
