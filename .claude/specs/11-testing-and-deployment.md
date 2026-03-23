# 11 - Testing & Deployment Strategy

> **Priority:** Required | **Complexity:** Medium
> **Estimated Time:** Ongoing

## Summary | Tóm tắt

**EN:** Align the new Data Builder features with internal testing and CI/CD pipelines as documented by the Universal Clean Architecture rules. Ensures test coverage guarantees stability for future modifications.

**VI:** Sắp xếp và tổ chức TDD (Test-Driven Development) cho tính năng Data Builder đảm bảo quy chuẩn chung được đề ra. Phủ sóng unit/e2e test giúp chống thoái hoá code cho team bảo trì.

---

## Proposed Changes | Các thay đổi đề xuất

### 11.1 Mocking Strategies

**Files:** `test/mocks/data-builder/*`

**EN:**

- Set up unit tests covering Domain object mutations without loading infrastructure implementations.
- Provide mock data files replicating parsed CSV streams to independently verify robust compensation behavior of local sagas.

**VI:**

- Cấu hình unit test thực thi trên Domain model, đảm bảo logic tách biệt 100% database.
- Tự tạo luồng mock data stream của file CSV để test chức năng rollback tự động cục bộ của Local Sagas một cách độc lập.

### 11.2 E2E Testing Boundaries

**Files:** `test/e2e/data-builder.e2e-spec.ts`

**EN:**

- Run end-to-end paths verifying an HTTP submission properly updates Postgres SQL DB states using Supertest.
- Target CQRS operations verifying `DataBuilderImportCommand` effectively creates views.

**VI:**

- Lập kịch bản e2e chạy xuyên lục địa (từ API tới Database) qua Supertest.
- Chọc trực tiếp vào các Endpoint nhận JSON (Commands) và verify metadata có mặt trong DB ảo (in-memory SQLite hoặc PG TestContainer).

## Verification | Xác minh

- Output of `npm run test` executes seamlessly.
- Output of `npm run test:e2e` maintains >85% critical path coverage on new modules.
