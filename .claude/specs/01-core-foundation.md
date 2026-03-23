# 01 - Core Foundation

> **Priority:** High | **Complexity:** Medium
> **Estimated Time:** 2-3 days

## Summary | Tóm tắt

**EN:** Setup the core module structure for Data Visualizer in NestJS using Domain-Driven Design (DDD). Define base entities, repository interfaces, and basic controller setups.

**VI:** Thiết lập cấu trúc module cốt lõi cho Data Visualizer trong NestJS sử dụng Domain-Driven Design (DDD). Định nghĩa các entities cơ sở, repository interfaces và cài đặt controller cơ bản.

---

## Proposed Changes | Các thay đổi đề xuất

### 1.1 Module Initialization

**File:** `src/presentation/portal/data-builder/data-builder.module.ts`

**EN:**

- Create the main NestJS module for Data Visualizer.
- Register CQRS components (CommandBus, QueryBus).
- Setup TypeORM entity imports.

**VI:**

- Tạo NestJS module chính cho Data Visualizer.
- Đăng ký các thành phần CQRS (CommandBus, QueryBus).
- Thiết lập imports cho TypeORM entities.

---

### 1.2 Domain Entities

**Files:** `src/domain/data-builder/entities/*`

**EN:**

- Create `DashboardViewEntity` (ID, Name, Slug, BaseTable, Permissions).
- Create `ViewColumnEntity` for selected fields and aliases.
- Create `ViewFilterEntity` for logical conditions.
- Implement business validation inside entities.

**VI:**

- Tạo `DashboardViewEntity` (ID, Tên, Slug, Bảng gốc, Quyền).
- Tạo `ViewColumnEntity` cho các trường đã chọn và bí danh.
- Tạo `ViewFilterEntity` cho các điều kiện logic.
- Thực hiện logic nghiệp vụ xác thực bên trong entities.

---

### 1.3 Repository Interfaces

**Files:** `src/domain/data-builder/repositories/*`

**EN:**

- Define `IDashboardViewRepository` with standard CRUD and query operations.
- Ensure tight coupling with Domain Entities only, not infrastructure.

**VI:**

- Định nghĩa `IDashboardViewRepository` với các thao tác CRUD và truy vấn chuẩn.
- Đảm bảo chỉ liên kết chặt chẽ với Domain Entities, không phụ thuộc hạ tầng.

---

## Files to Create | Các file cần tạo

```text
data-visualizer/src/
├── presentation/
│   └── portal/
│       └── data-builder/
│           ├── controllers/
│           └── data-builder.module.ts
├── application/
│   └── data-builder/
│       ├── use-cases/
│       └── queries/
├── domain/
│   └── data-builder/
│       ├── entities/
│       │   ├── dashboard-view.entity.ts
│       │   ├── view-column.entity.ts
│       │   └── view-filter.entity.ts
│       └── repositories/
│           └── i-dashboard-view.repository.ts
└── infrastructure/
    └── persistence/
        ├── typeorm/
        └── exporters/
```

---

## Verification | Xác minh

### Automated Tests

- Module initializes properly without cyclical dependencies.
- Domain Entities pass unit tests for internal invariants.

### Manual Tests

1. Start application (`npm run start:dev`) → No startup errors.
2. Verify TypeORM correctly synchronizes tables if configure allows.
