---
name: dv-refactor-specialist
description: Safe refactoring guidelines for Data Visualizer. Use when restructuring code without changing behavior.
---

# Safe Refactoring Specialist — Data Visualizer

> **GOLDEN RULE**: Tái cấu trúc = thay đổi cấu trúc bên trong mà **TUYỆT ĐỐI KHÔNG LÀM THAY ĐỔI** hành vi bên ngoài.
> Mọi refactor step phải verifiable bằng existing tests. Không có test → không refactor.

## Triggers

Sử dụng skill này khi:

- Code có smells (large functions, deep nesting, duplicates)
- Cần migrate từ pattern cũ sang pattern mới (e.g., shortcut repo → explicit mapper flow)
- Dead code cleanup sau khi feature xong
- Module restructuring để đúng layer boundaries
- Import path migration (relative → alias)
- "Refactor X", "Clean up X", "Optimize X structure"

---

## 1. Quy Trình Refactor (4 bước)

### Bước 1: Đọc Context Trước Khi Chạm Code

```bash
# 1a. Đọc CHANGELOG để biết tech debt đã biết
cat changelogs/CHANGELOG.md

# 1b. Đọc file mục tiêu đầy đủ
# Identify: what does this code do? Thuộc layer nào? Module nào?

# 1c. Xác định test coverage
pnpm test -- --testPathPattern=<module>
```

> ⚠️ Nếu **không có test nào cover** file mục tiêu → **STOP**. Yêu cầu user viết test trước (dùng `test-generator` skill).

### Bước 2: Phân Loại — Chọn Refactor Category

Xác định loại refactor và áp dụng strategy tương ứng:

| #   | Category           | SOLID     | Trigger                                       | Strategy                                     |
| --- | ------------------ | --------- | --------------------------------------------- | -------------------------------------------- |
| A   | Layer Violation    | DIP       | Domain import Infrastructure                  | Move dependency, inject via Port             |
| B   | Module Wiring      | DIP + SRP | Presentation import InfraModule               | Re-wire qua ApplicationModule                |
| C   | Repository Pattern | SRP + OCP | `findOneBy()` shortcut                        | Explicit `findOne()` + `mapper.toDomain()`   |
| D   | Large Function     | SRP       | >50 lines hoặc >3 indent levels               | Extract Method + Early Return                |
| E   | Large File         | SRP       | >400 lines (component) / >800 lines (service) | Split by responsibility                      |
| F   | Duplicate Code     | DRY       | 3+ occurrences                                | Extract shared utility/base class            |
| G   | Type Safety        | —         | `any` type                                    | Define proper Interface/DTO                  |
| H   | Import Paths       | —         | `../../../../` relative path                  | Convert to `@domain/`, `@application/` alias |
| I   | Dead Code          | YAGNI     | Unused exports, commented code                | Remove safely                                |
| J   | React Component    | SRP       | JSX >100 lines, mixed concerns                | Tách sub-component + custom hook             |

### Bước 3: Thực Hiện Refactor

Chi tiết từng Category xem [Section 2](#2-refactor-patterns-chi-tiết).

### Bước 4: Verification (BẮT BUỘC sau mỗi thay đổi)

```bash
npx tsc --noEmit    # Không lỗi TypeScript mới
pnpm lint           # Không vi phạm lint mới
pnpm test           # Tất cả tests vẫn pass
```

> Nếu bất kỳ command nào fail → **REVERT** thay đổi vừa làm, debug, rồi thử lại.

---

## 2. Refactor Patterns Chi Tiết

### Category A: Layer Violation Fix

Dự án DV tuân thủ **Clean Architecture** — dependency direction chỉ đi **từ ngoài vào trong**:

```
Presentation → Application → Domain ← Infrastructure
```

**Quy tắc cứng:**

- Domain **KHÔNG** import từ Application, Infrastructure, hoặc Presentation
- Application **KHÔNG** import từ Presentation hoặc Infrastructure (trừ qua Port interface)
- Presentation **KHÔNG** import từ Infrastructure (chỉ qua ApplicationModule)

```typescript
// ❌ SAI: Domain import Infrastructure
import { TypeOrmModule } from '@nestjs/typeorm'; // Framework dependency trong Domain

// ✅ ĐÚNG: Domain chỉ định nghĩa Port interface
export abstract class IOrderRepository {
    abstract findById(id: string): Promise<Order | null>;
    abstract save(order: Order): Promise<void>;
}
```

### Category B: Module Wiring (DV-Specific — CRITICAL)

Đây là lỗi phổ biến nhất trong DV project. Từ CHANGELOG lessons learned:

```text
ĐÚNG:
InfraModule (provide concrete → export Port token)
    ↓ imported by
ApplicationModule (import InfraModule → provide Use-cases → export Use-cases)
    ↓ imported by
PresentationModule (import ApplicationModule → chỉ khai báo Controllers)

SAI:
PresentationModule import InfraModule trực tiếp
PresentationModule tự khai báo Use-case providers
```

```typescript
// ❌ SAI: Presentation import Infrastructure trực tiếp
@Module({
    imports: [DashboardInfraModule],
    controllers: [DashboardQueryController],
    providers: [GetDashboardOverviewUseCase], // ← SAI: tự register use-case
})
export class DashboardPresentationModule {}

// ✅ ĐÚNG: Presentation chỉ import Application
@Module({
    imports: [DashboardApplicationModule], // ← Application handles wiring
    controllers: [DashboardQueryController],
    // KHÔNG có providers — controllers inject từ ApplicationModule exports
})
export class DashboardPresentationModule {}
```

### Category C: Repository Pattern

```typescript
// ❌ SAI: Shortcut — trả thẳng ORM entity, không qua Mapper
async findById(id: string): Promise<MyEntity | null> {
    return this.findOneBy({ id }); // TypeORM convenience method
}

// ✅ ĐÚNG: Explicit flow qua Mapper
async findById(id: string): Promise<MyEntity | null> {
    const orm = await this.repository.findOne({
        where: { id },
        relations: ['items'],
    });
    if (!orm) return null;
    return this.mapper.toDomain(orm);
}
```

**Mapper initialization:**

```typescript
// ❌ SAI: new Mapper()
constructor(dataSource: DataSource) {
    super(MyEntityOrm, dataSource, new MyEntityMapper());
}

// ✅ ĐÚNG: Mapper.create() (factory method)
constructor(dataSource: DataSource) {
    super(MyEntityOrm, dataSource, MyEntityMapper.create());
}
```

### Category D: Large Function → Extract Method

```typescript
// ❌ SAI: 60+ line function, 3 trách nhiệm trộn lẫn
async processOrder(input: CreateOrderInput): Promise<OrderResult> {
    // 15 lines: validate input
    // 25 lines: calculate pricing with discounts
    // 20 lines: persist to database and publish events
}

// ✅ ĐÚNG: Mỗi method có single responsibility rõ ràng
async processOrder(input: CreateOrderInput): Promise<OrderResult> {
    const validated = this.validateOrderInput(input);
    const priced = this.calculatePricing(validated);
    return this.persistAndPublish(priced);
}

private validateOrderInput(input: CreateOrderInput): ValidatedOrder { ... }
private calculatePricing(order: ValidatedOrder): PricedOrder { ... }
private async persistAndPublish(order: PricedOrder): Promise<OrderResult> { ... }
```

**Deep nesting → Early return (Guard Clauses):**

```typescript
// ❌ SAI: 5 levels of nesting
if (user) {
    if (user.isActive) {
        if (order) {
            if (order.canCancel()) {
                // actual logic buried deep
            }
        }
    }
}

// ✅ ĐÚNG: Flat structure with guard clauses
if (!user) throw new UserNotFoundException();
if (!user.isActive) throw new InactiveUserException();
if (!order) throw new OrderNotFoundException();
if (!order.canCancel()) throw new OrderNotCancellableException();

// actual logic at top level — easy to read
```

### Category E: Large File → Split by Responsibility

Khi file vượt ngưỡng:

| File Type        | Ngưỡng     | Strategy                            |
| ---------------- | ---------- | ----------------------------------- |
| Service/Use-case | >800 lines | Tách thành multiple use-cases       |
| Controller       | >400 lines | Tách Command vs Query controller    |
| React Component  | >400 lines | Tách sub-components + hooks         |
| Test file        | >600 lines | Tách theo test suite/describe block |

### Category F: Duplicate Code → Extract Shared

```typescript
// ❌ SAI: Copy-paste logic xuất hiện 3+ lần
// File 1: order.repository.ts
const orm = await this.repository.findOne({ where: { id } });
if (!orm) throw new NotFoundException(`Order ${id} not found`);

// File 2: product.repository.ts  (gần giống)
const orm = await this.repository.findOne({ where: { id } });
if (!orm) throw new NotFoundException(`Product ${id} not found`);

// ✅ ĐÚNG: Base repository đã có method findOneOrFail
// Kế thừa từ BaseRepositoryTypeORM trong libs/src/ddd
async findByIdOrFail(id: string): Promise<TDomain> {
    const orm = await this.repository.findOne({ where: { id } });
    if (!orm) throw new NotFoundException(`${this.entityName} ${id} not found`);
    return this.mapper.toDomain(orm);
}
```

### Category G: Type Safety

```typescript
// ❌ SAI: any ở mọi nơi
async execute(req: any): Promise<any> { ... }
const data: any = await this.fetch();

// ✅ ĐÚNG: Explicit types
async execute(req: CreateOrderRequest): Promise<CreateOrderResponse> { ... }
const data: OrderDto = await this.fetch();
```

### Category H: Import Path Migration

```typescript
// ❌ SAI: Relative paths dài (fragile, khó đọc)
import { Order } from '../../../../domain/order/entities/order.entity';
import { Money } from '../../../../domain/order/value-objects/money.vo';

// ✅ ĐÚNG: tsconfig alias paths (robust, clear)
import { Order } from '@domain/order/entities/order.entity';
import { Money } from '@domain/order/value-objects/money.vo';
```

> ⚠️ **Ngoại lệ**: Files trong sub-project (ví dụ `libs/`) giữ relative imports nội bộ — không convert.

### Category I: Dead Code Removal

Xóa an toàn:

- Functions/classes không có reference (kiểm tra bằng `grep -r "functionName" src/`)
- `// TODO` comments quá 30 ngày không ai xử lý
- Commented-out code blocks (>5 lines)
- Unused imports (ESLint auto-fix: `pnpm lint --fix`)

### Category J: React Component Refactor

```tsx
// ❌ SAI: Component quá lớn, trộn lẫn data fetching + UI + logic
function TableEditor() {
    // 30 lines: hooks and state
    // 40 lines: data fetching and transformation
    // 80 lines: JSX with nested conditionals
}

// ✅ ĐÚNG: Tách concerns
function TableEditor() {
    const { data, isLoading, error } = useTableData(tableId);
    const { columns, handleSort } = useColumnConfig(data);

    if (isLoading) return <TableSkeleton />;
    if (error) return <ErrorBanner error={error} />;

    return <TableGrid data={data} columns={columns} onSort={handleSort} />;
}

// Custom hook chứa data logic
function useTableData(tableId: string) { ... }

// Sub-component chứa UI logic
function TableGrid({ data, columns, onSort }: TableGridProps) { ... }
```

---

## 3. Import Grouping Rules

Sau khi refactor imports, đảm bảo thứ tự:

```typescript
// Group 1: Node.js built-ins
import { join } from 'path';

// Group 2: NestJS / Framework
import { Injectable, Inject } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

// Group 3: Third-party libraries
import { DataSource } from 'typeorm';

// Group 4: Internal aliases — theo thứ tự layer
import { Order } from '@domain/order/entities/order.entity';
import { CreateOrderUseCase } from '@application/order/use-cases/create-order.use-case';
import { OrderRepository } from '@infrastructure/modules/order/repositories/order.repository';

// Group 5: Relative imports (cùng module)
import { CreateOrderDto } from './dtos/create-order.dto';
```

---

## 4. Ranh Giới Tuyệt Đối (What NOT to Refactor)

| Không chạm                                 | Lý do                       | Agent thay thế        |
| ------------------------------------------ | --------------------------- | --------------------- |
| Database schema / ORM Entity fields        | Cần migration               | `dv-db-optimizer`     |
| API endpoint paths, params, response shape | Breaking change cho FE      | Cần PR + version bump |
| Test files                                 | Trừ khi test code sai logic | `test-generator`      |
| Generated files (ORM auto-gen)             | Sẽ bị overwrite             | —                     |
| `libs/` internal code                      | Sub-project riêng           | —                     |
| Config files (`.env`, `tsconfig`)          | Side effect rộng            | Cần review user       |

---

## 5. DV-Specific Tech Debt (Known Targets)

Từ `CHANGELOG.md` và `error-resolution-log.md`:

| #   | Target                  | Mô tả                                                               | Priority |
| --- | ----------------------- | ------------------------------------------------------------------- | -------- |
| 1   | Repository shortcuts    | `findOneBy()` → explicit `findOne()` + `mapper.toDomain()`          | P0       |
| 2   | Long relative imports   | `'../../../../'` → `@domain/`, `@application/`                      | P1       |
| 3   | Port interface location | Ports nằm ở Application → move sang Domain                          | P0       |
| 4   | Module wiring violation | Presentation import InfraModule → re-wire qua ApplicationModule     | P0       |
| 5   | Missing exports         | Add `export` to all Result/Response interfaces                      | P2       |
| 6   | Missing getters         | Add `get createdAt()`, `get updatedAt()` to Aggregates              | P2       |
| 7   | Stale TODO comments     | Xóa TODOs đã resolved hoặc convert thành issue                      | P3       |
| 8   | In-memory stubs         | Storage upload + Data Models repo dùng in-memory → swap Postgres/S3 | P1       |

---

## 6. Refactor Checklist (Trước Khi Hoàn Tất)

- [ ] Đọc file mục tiêu đầy đủ trước khi sửa
- [ ] Xác nhận có tests cover code đang refactor
- [ ] Không thay đổi public API (function names, return types, params)
- [ ] Mỗi extracted function/component có rõ single responsibility
- [ ] `npx tsc --noEmit` pass
- [ ] `pnpm lint` pass
- [ ] `pnpm test` pass
- [ ] Không introduce new dependencies
- [ ] Import aliases đúng namespace sau migration
- [ ] Module wiring tuân thủ: Infra → Application → Presentation
- [ ] Cập nhật `changelogs/CHANGELOG.md` ghi nhận tech debt đã giải quyết
