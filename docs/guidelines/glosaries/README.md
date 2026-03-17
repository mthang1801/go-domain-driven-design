# 📚 Glossary — Bảng Thuật ngữ Phần mềm & Go Concurrency

> **Mục đích**: Tập trung tất cả thuật ngữ quan trọng trong software engineering và Go concurrency patterns. Mỗi thuật ngữ có file detail riêng với cấu trúc ① DEFINE → ② GRAPH → ③ CODE.

---

## 📑 Mục lục

### I. Software Engineering — Tài liệu & Quy trình

| #  | Thuật ngữ | Viết tắt | Mô tả ngắn | Detail |
|----|-----------|----------|-------------|--------|
| 1  | Software Requirements Specification | **SRS** | Đặc tả yêu cầu phần mềm | [→ SRS.md](./SRS.md) |
| 2  | Business Requirements Specification | **BRS** | Đặc tả yêu cầu kinh doanh | [→ BRS.md](./BRS.md) |
| 3  | Functional Requirements Specification | **FRS** | Đặc tả yêu cầu chức năng | [→ FRS.md](./FRS.md) |
| 4  | Non-Functional Requirements Specification | **NFRS** | Đặc tả yêu cầu phi chức năng | [→ NFRS.md](./NFRS.md) |
| 5  | Product Requirements Document | **PRD** | Tài liệu yêu cầu sản phẩm | [→ PRD.md](./PRD.md) |

### II. Thiết kế & Kiến trúc

| #  | Thuật ngữ | Viết tắt | Mô tả ngắn | Detail |
|----|-----------|----------|-------------|--------|
| 6  | High-Level Design | **HLD** | Thiết kế cấp cao (kiến trúc tổng quan) | [→ HLD.md](./HLD.md) |
| 7  | Low-Level Design | **LLD** | Thiết kế cấp thấp (class, method, schema) | [→ LLD.md](./LLD.md) |
| 8  | Entity-Relationship Diagram | **ERD** | Sơ đồ quan hệ thực thể | [→ ERD.md](./ERD.md) |
| 9  | Unified Modeling Language | **UML** | Ngôn ngữ mô hình hóa thống nhất | [→ UML.md](./UML.md) |

### III. Quy trình & Phương pháp

| #  | Thuật ngữ | Viết tắt | Mô tả ngắn | Detail |
|----|-----------|----------|-------------|--------|
| 10 | Agile Software Development | **Agile** | Phát triển phần mềm linh hoạt | [→ Agile.md](./Agile.md) |
| 11 | Continuous Integration / Continuous Delivery | **CI/CD** | Tích hợp & triển khai liên tục | [→ CICD.md](./CICD.md) |
| 12 | Development + Operations | **DevOps** | Tích hợp phát triển và vận hành | [→ DevOps.md](./DevOps.md) |
| 13 | Test-Driven Development | **TDD** | Phát triển hướng kiểm thử | [→ TDD.md](./TDD.md) |

### IV. Kiểm thử & Chất lượng

| #  | Thuật ngữ | Viết tắt | Mô tả ngắn | Detail |
|----|-----------|----------|-------------|--------|
| 14 | Quality Assurance | **QA** | Đảm bảo chất lượng | [→ QA.md](./QA.md) |
| 15 | User Acceptance Testing | **UAT** | Kiểm thử chấp nhận người dùng | [→ QA.md](./QA.md) |
| 16 | Behavior-Driven Development | **BDD** | Phát triển hướng hành vi | [→ TDD.md](./TDD.md) |

### V. Nguyên tắc thiết kế

| #  | Thuật ngữ | Viết tắt | Mô tả ngắn | Detail |
|----|-----------|----------|-------------|--------|
| 17 | SOLID Principles | **SOLID** | 5 nguyên tắc OOP | [→ SOLID.md](./SOLID.md) |
| 18 | Don't Repeat Yourself | **DRY** | Tránh lặp code | [→ DRY-KISS-YAGNI.md](./DRY-KISS-YAGNI.md) |
| 19 | Keep It Simple, Stupid | **KISS** | Giữ mọi thứ đơn giản | [→ DRY-KISS-YAGNI.md](./DRY-KISS-YAGNI.md) |
| 20 | You Aren't Gonna Need It | **YAGNI** | Đừng thêm tính năng chưa cần | [→ DRY-KISS-YAGNI.md](./DRY-KISS-YAGNI.md) |

---

## 🔗 Quy ước Format cho Detail Files

Mỗi file detail tuân theo cấu trúc chuẩn:

```
① DEFINE   — Định nghĩa, phân biệt, use cases, actors, invariants, failure modes
② GRAPH    — Diagram minh hoạ (ASCII / Mermaid)
③ CODE     — Code example với annotated comments
④ PITFALLS — Các lỗi thường gặp và cách tránh
⑤ REF      — Tham khảo (docs, blog, source code)
```

---

> **Chú ý**: Các thuật ngữ chưa có cột Detail sẽ được bổ sung khi cần, theo cùng format chuẩn ở trên.