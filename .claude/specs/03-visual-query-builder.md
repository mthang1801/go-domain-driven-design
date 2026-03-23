# 03 - Visual Query Builder Interface

> **Priority:** High | **Complexity:** High
> **Estimated Time:** 4-5 days

## Summary | Tóm tắt

**EN:** Establish the data models, API endpoints, and configuration structure for designing custom views using the Visual Query Builder. This builder acts as an auxiliary tool seamlessly integrated alongside the **Table Editor** and **SQL Editor** modules, facilitating drag-and-drop query generation.

**VI:** Thiết lập mô hình dữ liệu, các API endpoints và cấu trúc cho phép thiết kế view tuỳ chỉnh bằng Visual Query Builder. Công cụ kéo-thả này hoạt động song song và bổ trợ cho **Table Editor** cũng như **SQL Editor** trong bộ 7 Core Modules.

---

## Proposed Changes | Các thay đổi đề xuất

### 3.1 Create View Use Cases

**Files:** `src/application/data-builder/use-cases/create-view.use-case.ts`

**EN:**

- Create `CreateViewCommand` enforcing validation over the JSON payload containing the view design (Tables, Columns, Aliases, Filters, Joins).
- Map nested JSON payload into Domain entities (`ViewColumnEntity`, `ViewFilterEntity`, `ViewJoinEntity`).

**VI:**

- Tạo `CreateViewCommand` thực thi quá trình kiểm tra (validation) trên dữ liệu JSON chứa cấu hình views (Bảng, Cột, Bí danh, Bộ lọc, Joins).
- Chuyển đổi payload JSON lồng ghép thành các Domain entities tương ứng.

### 3.2 View Configuration JSON Structure

**EN:**
The frontend will send a unified JSON payload representing the query design:

```json
{
    "name": "High Value Clients",
    "baseTable": "tblclients",
    "columns": [
        { "table": "tblclients", "column": "company", "alias": "Company Name" },
        { "table": "tblinvoices", "column": "total", "alias": "Invoice Amount" }
    ],
    "joins": [
        {
            "type": "LEFT",
            "targetTable": "tblinvoices",
            "condition": "tblclients.userid = tblinvoices.clientid"
        }
    ],
    "filters": [
        {
            "table": "tblinvoices",
            "column": "total",
            "operator": ">",
            "value": "1000",
            "logic": "AND"
        }
    ]
}
```

### 3.3 CRUD APIs

**Files:** `src/presentation/portal/data-builder/controllers/views.controller.ts`

**EN:**

- Endpoints to Create, Read, Update, and Delete view configurations.
- API validation using `class-validator` to ensure fields selected exist in the whitelist.

**VI:**

- Các endpoints để Thêm, Đọc, Cập nhật, Xóa cấu hình view.
- API validation bằng `class-validator` để đảm bảo các trường được chọn nằm trong whitelist.

## Verification | Xác minh

- Payload validation strictly fails if an unsupported table or operator is submitted.
- Successfully saves complex multi-join view configurations to the database.
