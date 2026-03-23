# 02 - Schema Discovery & Whitelisting

> **Priority:** High | **Complexity:** Medium
> **Estimated Time:** 2 days

## Summary | Tóm tắt

**EN:** Implement a robust mechanism to discover the database schema, read table structures securely, and expose whitelisted tables/relationships for the Visual Query Builder.

**VI:** Triển khai cơ chế mạnh mẽ để khám phá lược đồ cơ sở dữ liệu, đọc cấu trúc bảng một cách an toàn và cung cấp các bảng/mối quan hệ trong whitelist (danh sách trắng) cho Trình thiết kế truy vấn (Visual Query Builder).

---

## Proposed Changes | Các thay đổi đề xuất

### 2.1 Whitelisting System

**File:** `config/data-builder.config.ts`

**EN:**

- Define a strict configuration array of allowed tables (e.g., `tblclients`, `tblinvoices`, `tblprojects`).
- Block access to sensitive tables containing authentication data.

**VI:**

- Định nghĩa mảng cấu hình nghiêm ngặt cho các bảng được phép truy cập (vd: `tblclients`, `tblinvoices`, `tblprojects`).
- Chặn quyền truy cập vào các bảng nhạy cảm chứa dữ liệu xác thực.

### 2.2 Schema Discovery Service

**File:** `src/application/data-builder/services/schema-discovery.service.ts`

**EN:**

- Use TypeORM metadata or raw database queries (`INFORMATION_SCHEMA`) to fetch columns for allowed tables.
- Return column data types (string, integer, date) to inform UI input types.
- Auto-detect Foreign Keys to propose smart JOIN conditions.

**VI:**

- Sử dụng metadata của TypeORM hoặc truy vấn SQL thuần (`INFORMATION_SCHEMA`) để lấy danh sách các cột của bảng được phép.
- Trả về kiểu dữ liệu của cột để quyết định loại input hiển thị trên UI.
- Tự động phát hiện Khóa ngoại (Foreign Keys) để đề xuất điều kiện JOIN thông minh.

### 2.3 API Interface

**File:** `src/presentation/portal/data-builder/controllers/schema.controller.ts`

**EN:**

- GET `/api/v1/data-builder/schema/tables` - List whitelisted tables
- GET `/api/v1/data-builder/schema/tables/:tableName/columns` - Get columns and types

**VI:**

- GET `/api/v1/data-builder/schema/tables` - Liệt kê bảng trong whitelist
- GET `/api/v1/data-builder/schema/tables/:tableName/columns` - Lấy cột và kiểu dữ liệu

## Verification | Xác minh

- Schema Discovery Service correctly denies requests for non-whitelisted tables.
- Foreign Key relationships are correctly mapped to JSON format.
