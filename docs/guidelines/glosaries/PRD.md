# PRD — Product Requirements Document

> **Viết tắt**: PRD  
> **Ngữ cảnh**: Product-led companies (startups, tech companies) — thay thế/bổ sung cho BRS + SRS

---

## ① DEFINE

### Định nghĩa

**PRD (Product Requirements Document)** là tài liệu mô tả **sản phẩm cần xây dựng** từ góc nhìn **product management** — kết hợp giữa business goals, user needs, và scope kỹ thuật. PRD phổ biến trong các công ty product-led (startup, tech companies), thường **thay thế** cặp BRS + SRS truyền thống.

### Phân biệt PRD vs BRS vs SRS

| Tiêu chí | PRD | BRS | SRS |
|----------|-----|-----|-----|
| **Ai viết** | Product Manager | Business Analyst | System Analyst |
| **Góc nhìn** | Product + User | Business | Technical |
| **Ngữ cảnh** | Startup, Agile, product-led | Enterprise, outsource | Enterprise, waterfall |
| **User Stories** | ✅ Có | ❌ Không | ❌ Không |
| **Prototypes** | ✅ Wireframes/Mockups | ❌ Không | Có thể |
| **Độ formal** | Vừa phải | Cao | Rất cao |

### Actors

| Actor | Vai trò |
|-------|---------|
| **Product Manager (PM)** | Viết và own PRD |
| **UX Designer** | Cung cấp wireframes, user research |
| **Engineering Lead** | Review feasibility, estimate effort |
| **Stakeholder** | Approve scope và priority |

### Invariants

- PRD **phải** bắt đầu từ **user problem**, không phải solution
- Mỗi feature phải liên kết đến **user persona** cụ thể
- PRD **phải có** success metrics (OKR / KPI)
- PRD là **living document** — update liên tục qua sprints

---

## ② GRAPH

### Cấu trúc PRD

```
PRD Document
├── 1. Problem Statement
│   └── User pain point là gì? Tại sao cần giải quyết?
├── 2. Target Users (Personas)
│   ├── Persona 1: Khách hàng Gen-Z (18-25, mobile-first)
│   └── Persona 2: Chủ nhà hàng nhỏ (ít tech-savvy)
├── 3. Goals & Success Metrics
│   ├── Goal 1 → OKR / KPI
│   └── Goal 2 → OKR / KPI
├── 4. User Stories & Requirements
│   ├── Epic 1: Onboarding
│   │   ├── US-001: "As a customer, I want to..."
│   │   └── US-002: "As a restaurant owner, I want to..."
│   └── Epic 2: Ordering
│       ├── US-010: ...
│       └── US-011: ...
├── 5. Wireframes / Mockups
│   └── (link to Figma / sketches)
├── 6. Out of Scope
│   └── Những gì KHÔNG làm trong version này
├── 7. Technical Considerations
│   └── Dependencies, constraints, risks
└── 8. Timeline & Milestones
    ├── MVP: 4 tuần
    └── V1.0: 8 tuần
```

### PRD trong Agile Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  User    │     │   PRD    │     │ Sprint   │     │  Ship &  │
│ Research │────▶│  (PM     │────▶│ Planning │────▶│ Measure  │
│ + Data   │     │  viết)   │     │ (Dev     │     │ (KPIs)   │
└──────────┘     └────┬─────┘     │  break   │     └────┬─────┘
                      │           │  down)   │          │
                      │           └──────────┘          │
                      │                                 │
                      └────── Iterate ◀─────────────────┘
```

---

## ③ CODE

### Ví dụ: PRD cho Feature "Đặt hàng nhanh"

```yaml
# PRD — Quick Order Feature
# Author: PM Team | Last Updated: 2026-03-17

problem_statement: >
  Khảo sát cho thấy 40% users bỏ giỏ hàng vì quy trình đặt hàng quá nhiều bước
  (trung bình 7 bước). Cần giảm xuống ≤ 3 bước để tăng conversion rate.

target_users:
  - persona: "Busy Professional"
    age: 25-35
    behavior: "Đặt đồ ăn lúc trưa, muốn nhanh nhất có thể"
    pain_point: "Quá nhiều bước, phải chọn lại địa chỉ + thanh toán mỗi lần"

goals:
  - goal: "Tăng order conversion rate từ 60% → 80%"
    metric: "Conversion rate (add-to-cart → order-placed)"
    target: "≥ 80% sau 4 tuần release"

  - goal: "Giảm thời gian đặt hàng từ 120s → 30s"
    metric: "Time to order completion"
    target: "p50 ≤ 30s"

user_stories:
  - id: US-050
    story: >
      As a returning customer,
      I want to re-order my last order with 1 tap,
      so that I can save time during lunch break.
    acceptance_criteria:
      - "Hiển thị nút 'Đặt lại' cho 3 đơn hàng gần nhất"
      - "1 tap → confirm popup → đặt hàng (dùng địa chỉ + thanh toán mặc định)"
      - "Nếu nhà hàng đóng cửa, hiển thị thông báo + gợi ý nhà hàng tương tự"
    priority: Must-Have

  - id: US-051
    story: >
      As a customer,
      I want to save my favorite orders,
      so that I can quickly reorder them anytime.
    priority: Should-Have

out_of_scope:
  - "AI recommendation engine (V2)"
  - "Voice ordering (V3)"
  - "Scheduled ordering — đặt trước giờ giao (V2)"

timeline:
  mvp: "2 tuần — US-050 (re-order)"
  v1: "4 tuần — US-050 + US-051"
```

---

## ④ PITFALLS

| # | Lỗi | Ví dụ | Fix |
|---|------|-------|-----|
| 1 | **Bắt đầu từ solution** | "Cần thêm nút re-order" | Bắt đầu từ problem: "40% bỏ giỏ hàng" |
| 2 | **Thiếu success metrics** | Ship feature mà không biết thành công chưa | Định nghĩa KPI trước khi code |
| 3 | **PRD quá dài** | 50 trang — không ai đọc | Tối đa 5-10 trang cho 1 feature |
| 4 | **Không update PRD** | PRD viết 1 lần rồi quên | Living document — update mỗi sprint |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| Inspired (Marty Cagan) | https://www.svpg.com/inspired-how-to-create-products-customers-love/ |
| PRD Template (Notion) | https://www.notion.so/templates/product-requirements-document |
| Shape Up (Basecamp) | https://basecamp.com/shapeup |
