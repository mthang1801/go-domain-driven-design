# FRS — Functional Requirements Specification

> **Viết tắt**: FRS · **Tương đương**: FSD (Functional Specification Document)  
> **Ngữ cảnh**: Sau BRS, trước hoặc cùng lúc SRS — tập trung vào **chức năng**

---

## ① DEFINE

### Định nghĩa

**FRS (Functional Requirements Specification)** là tài liệu đặc tả chi tiết **các chức năng** mà hệ thống phải thực hiện. FRS trả lời câu hỏi **"HỆ THỐNG phải LÀM GÌ?"** — mô tả hành vi (behavior) của hệ thống đối với từng input/output cụ thể.

### Phân biệt FRS vs SRS vs NFRS

| Tiêu chí | FRS | NFRS | SRS |
|----------|-----|------|-----|
| **Nội dung** | Chức năng (cái hệ thống LÀM) | Ràng buộc (hệ thống làm TỐT thế nào) | Cả hai + context |
| **Ví dụ** | "User đăng nhập bằng email" | "Login ≤ 2s, uptime 99.9%" | FRS + NFRS + intro + interfaces |
| **Câu hỏi** | Hệ thống làm gì? | Làm tốt thế nào? | Tất cả về hệ thống |

### Actors

| Actor | Vai trò |
|-------|---------|
| **BA / System Analyst** | Viết FRS dựa trên BRS |
| **Developer** | Implement đúng theo FRS |
| **QA** | Viết test cases từ FRS |
| **UX Designer** | Thiết kế UI dựa trên FRS flows |

### Invariants

- Mỗi functional requirement có **ID duy nhất** (`FR-001`)
- Mỗi FR phải mô tả rõ **input → process → output**
- Mỗi FR phải **trace ngược** về BRS/BRD
- FR dùng câu khẳng định: "Hệ thống **PHẢI**…" hoặc "Hệ thống **NÊN**…"

### Failure Modes

| Failure | Hậu quả | Cách tránh |
|---------|---------|------------|
| FR mơ hồ, thiếu edge cases | Dev tự đoán → bug | Mô tả cả happy path + error path |
| Thiếu validation rules | Dữ liệu bẩn vào hệ thống | Mỗi input phải có validation criteria |
| FR conflict nhau | Module A vs Module B mâu thuẫn | Review cross-module trước khi approve |

---

## ② GRAPH

### Cấu trúc FRS

```
FRS Document
├── 1. Use Case Overview
│   └── Use Case Diagram (tổng quan actors + functions)
├── 2. Functional Requirements
│   ├── Module: Authentication
│   │   ├── FR-001: Đăng ký tài khoản
│   │   │   ├── Input: email, password, phone
│   │   │   ├── Process: validate → hash → save
│   │   │   ├── Output: success / error message
│   │   │   ├── Validation: email format, password ≥ 8 chars
│   │   │   └── Error Cases: email đã tồn tại, OTP hết hạn
│   │   └── FR-002: Đăng nhập
│   ├── Module: Order Management
│   │   ├── FR-010: Tạo đơn hàng
│   │   └── FR-011: Hủy đơn hàng
│   └── Module: Payment
│       ├── FR-020: Thanh toán COD
│       └── FR-021: Thanh toán ví điện tử
├── 3. Business Rules
│   ├── Rule-01: Đơn tối thiểu 30.000 VND
│   └── Rule-02: Miễn phí ship đơn ≥ 100.000 VND
└── 4. Data Requirements
    ├── Entity: User (id, email, phone, …)
    └── Entity: Order (id, user_id, items, total, …)
```

### Flow: FR-001 Đăng ký tài khoản

```
User                              System                          Database
 │                                  │                                │
 │── POST /register ───────────────▶│                                │
 │   {email, password, phone}       │                                │
 │                                  │── Validate input ──────────────│
 │                                  │   ├── email format? ✅/❌       │
 │                                  │   ├── password ≥ 8 chars? ✅/❌ │
 │                                  │   └── phone format? ✅/❌       │
 │                                  │                                │
 │                                  │── Check email exists? ────────▶│
 │                                  │◀── No ─────────────────────────│
 │                                  │                                │
 │                                  │── Hash password (bcrypt) ──────│
 │                                  │── Save user ──────────────────▶│
 │                                  │◀── OK ─────────────────────────│
 │                                  │                                │
 │                                  │── Send OTP to phone ───────────│
 │◀── 201 Created ─────────────────│                                │
 │    {user_id, message}            │                                │
```

---

## ③ CODE

### Ví dụ: FRS dạng Structured

```yaml
module: Authentication

functional_requirements:
  - id: FR-001
    name: "Đăng ký tài khoản"
    priority: Must-Have
    traces_to: BR-001
    description: >
      Hệ thống PHẢI cho phép user đăng ký tài khoản mới
      bằng email + mật khẩu + số điện thoại.

    input:
      - field: email
        type: string
        validation: "RFC 5322 email format"
        required: true
      - field: password
        type: string
        validation: "≥ 8 ký tự, ≥ 1 chữ hoa, ≥ 1 số, ≥ 1 ký tự đặc biệt"
        required: true
      - field: phone
        type: string
        validation: "10-11 chữ số, bắt đầu bằng 0"
        required: true

    process:
      - step: 1
        action: "Validate tất cả input fields"
      - step: 2
        action: "Kiểm tra email đã tồn tại chưa"
      - step: 3
        action: "Hash password bằng bcrypt (cost ≥ 12)"
      - step: 4
        action: "Lưu user vào database"
      - step: 5
        action: "Gửi OTP đến số điện thoại (hết hạn 90s)"

    output:
      success:
        status: 201
        body: "{user_id, message: 'Đăng ký thành công, vui lòng xác thực OTP'}"
      error:
        - condition: "Email đã tồn tại"
          status: 409
          body: "{error: 'Email already registered'}"
        - condition: "Validation fail"
          status: 400
          body: "{error: 'Invalid input', details: [...]}"

    business_rules:
      - "Tối đa 5 lần gửi OTP/ngày/số điện thoại"
      - "OTP gồm 6 chữ số ngẫu nhiên"
      - "User chưa verified không thể đặt hàng"
```

---

## ④ PITFALLS

| # | Lỗi | Ví dụ | Fix |
|---|------|-------|-----|
| 1 | **Chỉ mô tả happy path** | FR chỉ nói "user đăng ký thành công" | Phải mô tả cả error cases |
| 2 | **Thiếu validation rules** | "User nhập email" — không nói format | Kèm regex hoặc format cụ thể |
| 3 | **Không phân biệt PHẢI vs NÊN** | Tất cả đều "Must-Have" | Dùng MoSCoW: Must / Should / Could / Won't |
| 4 | **Trộn lẫn NFR vào FRS** | FR nói "API phải nhanh ≤ 2s" | Tách NFR ra file NFRS riêng |

---

## ⑤ REF

| Nguồn | Link |
|-------|------|
| IEEE 29148:2018 | https://www.iso.org/standard/72089.html |
| Use Case Modeling (Alistair Cockburn) | https://alistair.cockburn.us/writing-effective-use-cases/ |
| User Story Mapping (Jeff Patton) | https://www.jpattonassociates.com/user-story-mapping/ |
