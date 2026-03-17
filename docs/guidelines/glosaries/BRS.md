# BRS — Business Requirements Specification

> **Viết tắt**: BRS · **Tương đương**: BRD (Business Requirements Document)  
> **Ngữ cảnh**: Giai đoạn đầu tiên — trước khi viết SRS

---

## ① DEFINE

### Định nghĩa

**BRS (Business Requirements Specification)** là tài liệu mô tả **mục tiêu kinh doanh**, **lợi ích kỳ vọng**, và **phạm vi ở mức business** mà dự án phần mềm phải đạt được. BRS trả lời câu hỏi **"TẠI SAO xây dựng hệ thống này?"** — khác với SRS trả lời **"HỆ THỐNG phải làm GÌ?"**.

### Phân biệt BRS vs SRS

| Tiêu chí | BRS | SRS |
|----------|-----|-----|
| **Góc nhìn** | Business / Stakeholder | Technical / Development |
| **Câu hỏi** | Tại sao? Để đạt gì? | Hệ thống phải làm gì? |
| **Đối tượng đọc** | CEO, PM, investor, sponsor | Developer, QA, Architect |
| **Mức chi tiết** | High-level, trừu tượng | Chi tiết, cụ thể, đo lường |
| **Ví dụ** | "Tăng doanh thu 20% qua online" | "API checkout ≤ 2s, 10K concurrent" |
| **Thứ tự** | Viết TRƯỚC | Viết SAU, dựa trên BRS |

### Actors

| Actor | Vai trò |
|-------|---------|
| **Business Analyst (BA)** | Viết và duy trì BRS |
| **Product Owner** | Cung cấp vision, approve BRS |
| **Stakeholder / Sponsor** | Xác nhận mục tiêu kinh doanh |
| **PM** | Dùng BRS để lên kế hoạch dự án |

### Invariants

- Mỗi business requirement phải **trace được** đến mục tiêu kinh doanh cụ thể
- BRS **không chứa** chi tiết kỹ thuật (database, API, framework…)
- Mỗi requirement phải có **KPI đo lường** được
- BRS phải được **approve bởi stakeholder** trước khi chuyển sang SRS

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| Không có BRS, nhảy thẳng vào SRS | Xây hệ thống không ai cần | Luôn bắt đầu từ business goals |
| BRS quá kỹ thuật | Stakeholder không hiểu, approve sai | Dùng ngôn ngữ business, không dùng jargon |
| Thiếu KPI | Không biết dự án thành công hay thất bại | Mỗi goal kèm metric cụ thể |

---

## ② GRAPH

### Vị trí BRS trong quy trình

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Business │     │   BRS    │     │   SRS    │     │  Design  │
│  Vision  │────▶│(Tại sao? │────▶│(Làm gì? │────▶│(Làm thế  │
│          │     │ Mục tiêu)│     │ Chi tiết)│     │  nào?)   │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
     │                │                │
     │     ┌──────────┘                │
     │     ▼                           │
     │  Stakeholder                    ▼
     │  Approve?               Developer đọc
     │  ✅ → tiếp                và implement
     │  ❌ → sửa BRS
```

### Cấu trúc BRS

```
BRS Document
├── 1. Executive Summary
│   └── Tóm tắt mục tiêu kinh doanh (1-2 trang)
├── 2. Business Objectives
│   ├── Obj-01: Tăng doanh thu online 20%
│   ├── Obj-02: Giảm thời gian xử lý đơn hàng 50%
│   └── Obj-03: Mở rộng 3 thành phố mới
├── 3. Stakeholders
│   ├── Internal: CEO, VP Sales, CS team
│   └── External: Khách hàng, Đối tác nhà hàng
├── 4. Business Requirements
│   ├── BR-001 ── trace → Obj-01
│   ├── BR-002 ── trace → Obj-02
│   └── BR-NNN ── trace → Obj-NN
├── 5. Success Metrics (KPIs)
│   ├── Revenue growth ≥ 20%
│   ├── Order processing time ≤ 5 phút
│   └── Customer satisfaction ≥ 4.5/5
├── 6. Constraints & Assumptions
│   ├── Budget: ≤ 500M VND
│   ├── Timeline: 6 tháng
│   └── Giả định: Thị trường online food tăng 30%/năm
└── 7. Risks
    ├── Đối thủ release trước
    └── Thay đổi quy định pháp luật
```

---

## ③ CODE

### Ví dụ: BRS cho FoodApp

```yaml
# BRS — FoodApp v1.0
# Người viết: BA Team | Ngày: 2026-03-17

executive_summary: >
  FoodApp là nền tảng đặt đồ ăn online nhằm chiếm 10% thị phần
  food delivery tại TP.HCM trong 12 tháng đầu tiên.

business_objectives:
  - id: OBJ-01
    goal: "Tăng doanh thu kênh online lên 20% so với Q4/2025"
    kpi: "Monthly recurring revenue ≥ 2 tỷ VND"

  - id: OBJ-02
    goal: "Giảm thời gian từ đặt hàng → giao hàng xuống ≤ 30 phút"
    kpi: "p90 delivery time ≤ 30 phút"

  - id: OBJ-03
    goal: "Đạt 50.000 active users/tháng sau 6 tháng"
    kpi: "MAU ≥ 50.000"

business_requirements:
  - id: BR-001
    traces_to: OBJ-01
    description: >
      Hệ thống PHẢI cho phép khách hàng đặt hàng và thanh toán online
      (COD, ví điện tử, thẻ ngân hàng).

  - id: BR-002
    traces_to: OBJ-02
    description: >
      Hệ thống PHẢI tự động thông báo cho nhà hàng trong vòng 30 giây
      khi có đơn hàng mới.

  - id: BR-003
    traces_to: OBJ-03
    description: >
      Hệ thống PHẢI hỗ trợ chương trình khuyến mãi, mã giảm giá
      để thu hút người dùng mới.

constraints:
  budget: "≤ 500 triệu VND"
  timeline: "6 tháng (Q2-Q3/2026)"
  team: "5 developers, 1 BA, 1 QA, 1 PM"

risks:
  - risk: "Đối thủ cạnh tranh (GrabFood, ShopeeFood) giảm giá mạnh"
    impact: High
    mitigation: "Tập trung niche market — đồ ăn healthy"
```

---

## ④ PITFALLS

| # | Lỗi | Ví dụ | Fix |
|---|------|-------|-----|
| 1 | **Trộn lẫn BRS và SRS** | BRS viết "dùng PostgreSQL, REST API" | BRS chỉ nói business goal, không nói tech |
| 2 | **KPI không đo được** | "Hệ thống phải tốt" | Thay bằng: "Customer satisfaction ≥ 4.5/5" |
| 3 | **Thiếu trace** | BR không link đến business objective | Mỗi BR phải có `traces_to: OBJ-XX` |
| 4 | **Không review với stakeholder** | BA tự viết, không hỏi business | Workshop với stakeholder trước khi viết |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| IIBA BABOK Guide | https://www.iiba.org/business-analysis-body-of-knowledge/ |
| IEEE 29148:2018 | https://www.iso.org/standard/72089.html |
| BRD Template (Atlassian) | https://www.atlassian.com/work-management/project-management/business-requirements-document |
