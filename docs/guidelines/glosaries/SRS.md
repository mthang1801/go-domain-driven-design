# SRS — Software Requirements Specification

> **Viết tắt**: SRS · **Tiêu chuẩn**: IEEE 29148 / ISO/IEC/IEEE 29148  
> **Ngữ cảnh**: Giai đoạn Requirements Analysis trong SDLC

---

## ① DEFINE

### Định nghĩa

**SRS (Software Requirements Specification)** là tài liệu đặc tả chi tiết toàn bộ **yêu cầu chức năng** (Functional Requirements) và **yêu cầu phi chức năng** (Non-Functional Requirements) của một hệ thống phần mềm. Đây là "hợp đồng kỹ thuật" giữa stakeholders và development team.

### Actors (Các bên liên quan)

| Actor | Vai trò trong SRS |
|-------|-------------------|
| **Product Owner / BA** | Viết và duy trì SRS |
| **Developer** | Đọc SRS để hiểu yêu cầu, implement đúng spec |
| **QA / Tester** | Dùng SRS làm cơ sở viết test cases |
| **Stakeholder / Client** | Review và approve SRS |
| **Architect** | Dựa vào SRS để thiết kế HLD/LLD |

### Invariants (Nguyên tắc bất biến)

- Mỗi yêu cầu **phải có ID duy nhất** (`REQ-001`, `REQ-002`…)
- Mỗi yêu cầu **phải đo lường được** — tránh mơ hồ ("nhanh" → "≤ 2 giây")
- Mỗi yêu cầu **phải trace được** đến business goal cụ thể
- SRS **phải version-controlled** — mọi thay đổi phải có changelog

### Use Cases

| Use Case | Mô tả |
|----------|-------|
| **Hệ thống mới** | SRS là bản đặc tả full từ đầu |
| **Tính năng bổ sung** | SRS Addendum — bổ sung vào SRS gốc |
| **Outsource / Vendor** | SRS là tài liệu pháp lý ràng buộc scope |
| **Audit / Compliance** | SRS chứng minh hệ thống đáp ứng quy định |

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| SRS mơ hồ, không rõ ràng | Dev hiểu sai → rework | Dùng câu "hệ thống **phải**…", kèm số liệu cụ thể |
| Thiếu NFR (Non-Functional) | Hệ thống chậm, không scale | Luôn bao gồm: Performance, Security, Reliability |
| Không update SRS khi thay đổi yêu cầu | SRS outdated, không ai đọc | Gắn SRS vào Git, review khi sprint planning |
| Quá dài, quá chi tiết | Không ai đọc hết | Tách thành modules, dùng cross-reference |

---

## ② GRAPH

### Vị trí SRS trong SDLC

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Business   │     │    SRS      │     │   Design    │     │   Develop   │
│  Analysis    │────▶│  (Đặc tả   │────▶│  (HLD/LLD)  │────▶│  (Code)     │
│  (BRS/PRD)   │     │   yêu cầu) │     │             │     │             │
└─────────────┘     └──────┬──────┘     └─────────────┘     └──────┬──────┘
                           │                                       │
                           │           ┌─────────────┐             │
                           └──────────▶│   Testing    │◀────────────┘
                                       │  (QA dùng    │
                                       │   SRS làm    │
                                       │   test base) │
                                       └─────────────┘
```

### Cấu trúc SRS (IEEE 29148)

```
SRS Document
├── 1. Introduction
│   ├── 1.1 Purpose
│   ├── 1.2 Scope
│   ├── 1.3 Definitions, Acronyms, Abbreviations
│   ├── 1.4 References
│   └── 1.5 Overview
├── 2. Overall Description
│   ├── 2.1 Product Perspective
│   ├── 2.2 Product Functions
│   ├── 2.3 User Classes and Characteristics
│   ├── 2.4 Operating Environment
│   ├── 2.5 Design and Implementation Constraints
│   └── 2.6 Assumptions and Dependencies
├── 3. System Features (Functional Requirements)
│   ├── Feature 3.1 ── REQ-001, REQ-002...
│   ├── Feature 3.2 ── REQ-010, REQ-011...
│   └── Feature 3.N ── REQ-NNN...
├── 4. External Interface Requirements
│   ├── User Interfaces
│   ├── Hardware Interfaces
│   ├── Software Interfaces
│   └── Communication Interfaces
├── 5. Non-Functional Requirements
│   ├── Performance
│   ├── Security
│   ├── Usability
│   ├── Reliability
│   └── Maintainability
└── 6. Other Requirements
```

### Traceability Matrix (Ma trận truy vết)

```
┌──────────┬──────────────────┬──────────────────┬──────────────────┐
│ REQ ID   │ Business Goal    │ Design Component │ Test Case        │
├──────────┼──────────────────┼──────────────────┼──────────────────┤
│ REQ-001  │ BG-01: User Auth │ Auth Module      │ TC-001, TC-002   │
│ REQ-010  │ BG-02: Search    │ Search Service   │ TC-010, TC-011   │
│ REQ-020  │ BG-03: Order     │ Order Module     │ TC-020, TC-021   │
│ REQ-030  │ BG-04: Realtime  │ WebSocket Layer  │ TC-030           │
└──────────┴──────────────────┴──────────────────┴──────────────────┘
```

---

## ③ CODE

### Ví dụ: Cách viết Requirement đúng chuẩn

```yaml
# ❌ SAI — Mơ hồ, không đo lường được
REQ-001: Hệ thống phải nhanh.
REQ-002: Hệ thống phải bảo mật.

# ✅ ĐÚNG — Cụ thể, đo lường được, có ràng buộc
REQ-001:
  title: "API Login Response Time"
  type: Non-Functional / Performance
  priority: Must-Have
  description: >
    Hệ thống PHẢI trả về response cho API đăng nhập
    trong thời gian ≤ 2 giây cho 95% requests,
    khi tải đồng thời ≤ 10.000 users.
  acceptance_criteria:
    - p95 latency ≤ 2000ms
    - p99 latency ≤ 5000ms
    - Error rate < 0.1%
  trace_to:
    business_goal: "BG-01: Trải nghiệm đăng nhập nhanh"
    test_cases: ["TC-001", "TC-002"]
    design_component: "Auth Service"
```

### Ví dụ: SRS cho Feature "Đăng nhập" (dạng structured)

```yaml
feature:
  id: "F-001"
  name: "Đăng nhập & Đăng ký"
  description: "Cho phép người dùng tạo tài khoản và đăng nhập vào hệ thống"

  requirements:
    - id: REQ-001
      type: Functional
      priority: Must-Have
      description: >
        Hệ thống PHẢI hỗ trợ đăng ký bằng số điện thoại + OTP.
        OTP hết hạn sau 90 giây. Tối đa 5 lần gửi OTP/ngày/số điện thoại.

    - id: REQ-002
      type: Functional
      priority: Should-Have
      description: >
        Hệ thống NÊN hỗ trợ đăng nhập bằng Google/Facebook qua OAuth 2.0.
        Nếu OAuth provider không khả dụng, hiển thị fallback form đăng nhập.

    - id: REQ-003
      type: Functional
      priority: Must-Have
      description: >
        Hệ thống PHẢI khóa tài khoản tạm thời sau 5 lần nhập sai mật khẩu.
        Thời gian khóa: 15 phút. Gửi email thông báo cho user.

    - id: REQ-004
      type: Non-Functional / Performance
      priority: Must-Have
      description: >
        API đăng nhập PHẢI phản hồi trong ≤ 2 giây (p95)
        khi tải 10.000 concurrent users.

    - id: REQ-005
      type: Non-Functional / Security
      priority: Must-Have
      description: >
        Mật khẩu PHẢI được lưu dưới dạng bcrypt hash (cost factor ≥ 12).
        KHÔNG BAO GIỜ lưu plaintext password.
```

---

## ④ PITFALLS

| # | Lỗi thường gặp | Ví dụ | Cách fix |
|---|-----------------|-------|----------|
| 1 | **Dùng từ mơ hồ** | "nhanh", "nhiều", "tốt" | Thay bằng số liệu cụ thể: "≤ 2s", "≥ 10K users" |
| 2 | **Thiếu priority** | Tất cả đều "Must-Have" | Dùng MoSCoW: Must / Should / Could / Won't |
| 3 | **Thiếu acceptance criteria** | REQ không có cách verify | Mỗi REQ phải kèm test conditions |
| 4 | **SRS quá dài, monolithic** | 200 trang 1 file | Tách theo module/feature, cross-reference |
| 5 | **Không version control** | SRS trên Google Docs, ai edit cũng được | Đưa vào Git, review qua PR |
| 6 | **Trộn lẫn Design vào SRS** | Viết "dùng PostgreSQL" trong SRS | SRS chỉ nói **what**, không nói **how** |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| IEEE 29148:2018 | [ISO/IEC/IEEE 29148](https://www.iso.org/standard/72089.html) |
| IEEE 830-1998 (cũ) | Phiên bản cũ của SRS standard |
| SWEBOK Guide | [IEEE SWEBOK](https://www.computer.org/education/bodies-of-knowledge/software-engineering) |
| Volere Template | [Template SRS phổ biến](https://www.volere.org/templates/volere-requirements-specification-template/) |