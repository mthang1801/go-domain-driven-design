# 04 - Runtime Engine & Export

> **Priority:** Critical | **Complexity:** High
> **Estimated Time:** 5-7 days

## Summary | Tóm tắt

**EN:** Develop the core algorithmic engine responsible for taking a View Configuration from the database, compiling it into a secure SQL QueryBuilder representation, and executing it efficiently with pagination and export capabilities.

**VI:** Xây dựng engine thuật toán lõi chịu trách nhiệm lấy Cấu hình View từ cơ sở dữ liệu, biên dịch nó thành một QueryBuilder SQL an toàn, và thực thi hiệu quả cùng tính năng phân trang cũng như xuất dữ liệu.

---

## Proposed Changes | Các thay đổi đề xuất

### 4.1 SQL Compilation Engine

**File:** `src/application/data-builder/services/query-compiler.service.ts`

**EN:**

- Translate `ViewEntity` into a TypeORM `SelectQueryBuilder` or raw Knex query.
- Process `joins` dynamically (`LEFT JOIN`, `INNER JOIN`).
- Apply `where` filters securely using parameterized queries to prevent SQL Injection.
- Append aliases accurately to the SELECT statement.

**VI:**

- Dịch `ViewEntity` thành `SelectQueryBuilder` của TypeORM hoặc truy vấn Knex thô.
- Xử lý mảng `joins` một cách động.
- Áp dụng bộ lọc `where` an toàn sử dụng tham số hóa dòng lệnh (parameterized queries) để chống SQL Injection.
- Gắn thêm bí danh chính xác vào lệnh SELECT.

### 4.2 Data Execution & Pagination

**File:** `src/application/data-builder/use-cases/execute-view.use-case.ts`

**EN:**

- Execute the compiled query.
- Append `LIMIT` and `OFFSET` based on incoming pagination requests.
- Return a standardized paginated response `[data, totalItems]`.

**VI:**

- Thực thi truy vấn đã biên dịch.
- Gắn thêm `LIMIT` và `OFFSET` dựa trên yêu cầu phân trang từ client.
- Trả về phản hồi phân trang chuẩn hóa `[data, totalItems]`.

### 4.3 Secure Evaluation Context

**EN:**

- Inject runtime contexts variables into filters. For example, replacing a filter `userid = {CURRENT_USER}` dynamically before query execution.

**VI:**

- Bơm biến ngữ cảnh lúc runtime vào bộ lọc. Ví dụ: thay thế bộ lọc `userid = {CURRENT_USER}` một cách tự động trước khi chạy truy vấn.

### 4.4 Data Export (Stream Pipeline)

**Files:** `src/infrastructure/exporters/`

**EN:**

- Integrate with `skill:stream-pipeline` to support large dataset exports (Excel/CSV).
- Iterate database cursors rather than loading everything into RAM.

**VI:**

- Tích hợp với `skill:stream-pipeline` để hỗ trợ xuất tập dữ liệu lớn (Excel/CSV).
- Lặp qua cơ sở dữ liệu (cursor) thay vì nạp tất cả bảng vào RAM.

## Verification | Xác minh

- Engine completely rejects raw SQL to ensure absolute protection against SQL Injection.
- 100,000+ row tables exported without breaking Node.js heap limit.
