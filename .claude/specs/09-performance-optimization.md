# 09 - Performance Optimization

> **Priority:** Medium | **Complexity:** Medium
> **Estimated Time:** 2-3 days

## Summary | Tóm tắt

**EN:** Configure and enforce caching strategies via Redis and Database indexing to ensure that heavily generated SQL views execute efficiently and repetitively without causing unnecessary infrastructure load.

**VI:** Cấu hình và ràng buộc chiến lược caching của Redis cũng như các cơ chế index trong database nhằm mục đích đảm bảo các View bị chạy đi chạy lại vẫn hoạt động nhanh và không quá tải server.

---

## Proposed Changes | Các thay đổi đề xuất

### 9.1 Redis Cache Decorator implementation

**File:** `src/presentation/portal/data-builder/controllers/views.controller.ts`

**EN:**

- Integrate the internal `@CacheAPI()` decorators for GET queries related to the visualizer runtime execution.
- Create automated invalidation hooks triggered by webhooks or CRON if the underlying reporting data has shifted greatly.

**VI:**

- Tích hợp `@CacheAPI()` (có sẵn ở libs) cho các requests từ client xuống runtime engine.
- Tự động xóa cache (Invalidation hooks) nếu dữ liệu báo cáo nền bị thay đổi lớn.

### 9.2 TypeORM Performance Interfaces

**File:** `src/infrastructure/persistence/typeorm/repositories/*`

**EN:**

- Ensure the underlying TypeORM mapping entities utilize composite indexes extensively on the generated configuration metadata for rapid retrieval during query compilation.
- Limit query generation sizes during testing and pagination to 2,000 entities max per request slice.

**VI:**

- Tổ chức lại bảng TypeORM metadata để thêm Composite Indexes.
- Limit output mặc định trong pagination ở TypeORM trả về không quá 2,000 rows cho mỗi yêu cầu.

## Verification | Xác minh

- Database queries executed back-to-back respond in <200ms utilizing Redis.
