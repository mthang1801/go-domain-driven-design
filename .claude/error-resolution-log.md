# 🚨 Báo Cáo Phân Tích & Giải Quyết Lỗi (Error Resolution Log)

**Người vận hành:** Agentic Team
**Mục đích:** Ghi nhận lỗi phát sinh khi setup layer Presentation & Infrastructure của Data Builder module, nguyên nhân gốc rễ, và cách khắc phục theo đúng Architect / Domain-Driven Design (DDD) chuẩn để team tuân thủ.

---

## 1. Các Lỗi Đã Gây Ra & Nguyên Nhân

### Lỗi 1: Sai quy ước Import Path (Alias resolution)

- **Log lỗi:** `Cannot find module '../../../../application/...'` trong file `data-builder.module.ts`.
- **Nguyên nhân:** Không tuân thủ cấu hình Alias trong `tsconfig.json`. File `data-builder.module.ts` nằm ngay sát `controllers` nhưng lại import tương đối quá dài (`../../..`), hoặc sai thư mục, dẫn tới mất kết nối module.
- **Tại sao tái diễn:** Agent đã bỏ sót bước rà soát file `tsconfig.json` khi viết import ở Module layer.

### Lỗi 2: Import sai namespace Mapper (`@shared` thay vì `@modules-shared`)

- **Log lỗi:** `Cannot find module '@shared/mappers/table-metadata.mapper'` trong Repository.
- **Nguyên nhân:** Chưa đọc kỹ file `.claude/EXAMPLES.md` (dòng 340). Namespace `@shared/*` được `tsconfig.json` trỏ tới `libs/src/shared/*` nhưng Mappers của Module cụ thể nằm trong `src/shared/*` tương ứng với biến alias `@modules-shared/*` (xem `tsconfig.json`).

### Lỗi 3: Lỗi Typescript Không Thể Export Lớp (Return Type Cannot Be Named - `TS4053`)

- **Log lỗi:** `Return type of public method from exported class has or is using name '...' from external module... but cannot be named.` (Gặp ở tất cả các controllers).
- **Nguyên nhân:** File Controller gọi một Promise từ `useCase.execute()` / `useCase.query()` mà bản thân Interface của UseCase trả về (ví dụ `GetLogsResult`, `ExecuteSqlResponse`) lại chỉ define qua dạng `interface` cục bộ (chưa có chữ `export`). Do cấu hình `declaration: true` ở `compilerOptions` bắt buộc xuất type, TSC sẽ báo lỗi.

### Lỗi 4: Lỗi Thiếu Getters trong Domain Entity

- **Log lỗi:** `TS2339: Property 'createdAt' does not exist on type 'SqlSnippet'.` (trong Mapper)
- **Nguyên nhân:** Các props như `createdAt` và `updatedAt` vẫn tồn tại ở dạng protected của Aggregate root nhưng Agent quên cung cấp hàm `get` xuất ra ngoài. DDD Mapper vì thế không lấy được value.

### Lỗi 5: Sai sót tên module ở Global (`LibTypeOrmModule`)

- **Nguyên nhân:** Tên bị đánh sai chính tả (chữ "Orm" hoa thành "orm" thường) khi gọi `@core/database`. Phải là `LibTypeormModule` mới đúng chuẩn NestJS core module của repository.

### Lỗi 6: Lỗi Dependency Injection (DI) do khai báo UseCase mà quên Implement Repository

- **Log lỗi:** `Nest can't resolve dependencies of the GetProjectSettingsUseCase ... Please make sure that the argument Symbol(IProjectSettingRepository) is available...`
- **Nguyên nhân:** Layer API (Controller -> UseCase) tiến hành chạy nhưng phía Infrastructure chưa chịu implement chi tiết `ProjectSettingRepository` (chỉ mới comment `// TODO` trong `TypeOrmInfrastructureModule`).
- **Cách khắc phục:** Lập trình đủ combo `ProjectSettingMapper` + `ProjectSettingRepository` bằng `BaseRepositoryTypeORM`, sau đó khai báo `provide: IProjectSettingRepository` vào export array của `TypeOrmInfrastructureModule`.

---

## 2. Quá Trình Khắc Phục (Resolution)

1.  **Khắc phục Lỗi 1 & 2 (Đường Dẫn):**
    - Đổi toàn bộ hệ thống import của UseCases sang dạng Alias chuẩn: `@application/data-builder/use-cases/...`
    - Đổi import Mapper ở Entity Repositories thành đúng namespace: `@modules-shared/mappers/...`
2.  **Khắc phục Lỗi 3 (Typescript Return Type Inferrence):**
    - Đã chèn thêm keyword `export` vào tất cả 10 interface kết quả của 10 UseCase layer.
    - Định nghĩa kiểu explicit (tường minh) cho các hàm public REST API trong mọi Controllers: `async methodName(...): Promise<XxxResult>`.

3.  **Khắc phục Lỗi 4, 5 & 6 (Entity Getters & Typo & DI Repository):**
    - Mở File Entity (`SqlSnippet`, `TableMetadata`) và bổ sung `get createdAt()` và `get updatedAt()`.
    - Sửa từ `LibTypeOrmModule` thành `LibTypeormModule` đúng theo core logic của repo.
    - Hiện thực hoá class `ProjectSettingRepository`, `ProjectSettingMapper` và cấu hình Provider `IProjectSettingRepository` đúng chuẩn.

> **Kết quả:** Kiểm tra bởi `npx tsc --noEmit` trả về mã lỗi `0` (Sạch sẽ hoàn toàn).

---

## 3. Checklist Ngăn Ngừa Tái Phạm (Prevention Guide)

Để tất cả các sub-agent (đặc biệt là Code Generator) không lặp lại lỗi này trong tương lai cần tuân thủ triệt để:

- [ ] **Checklist 1:** Nếu cần tham chiếu Typescript file từ ngoài src thư mục đang làm việc, **Bắt Buộc** dùng alias của `tsconfig.json` (`@domain/...`, `@application/...`, `@infrastructure/...`, `@presentation/...`, `@modules-shared/...`).
- [ ] **Checklist 2:** Mọi Result / Response interface định nghĩa bên trong UseCase đều **Bắt Buộc** phải có chữ `export interface ...`.
- [ ] **Checklist 3:** Các public REST router trong `@Controller` **Bắt Buộc** phải declare explicit return type (`Promise<Type>`).
- [ ] **Checklist 4:** Đối với Mapper Mapping, Props nào cần persist trong Database thì Aggregate Root **Bắt Buộc** phải mở Getter (ví dụ `createdAt`, `updatedAt`).
- [ ] **Checklist 5:** Mapper Layer của một microservice/module cụ thể nằm trong `src/shared/mappers` và đường dẫn import của nó là `@modules-shared/...` (Không nhầm lẫn với Library Shared (`@shared/`)).
- [ ] **Checklist 6:** Khi thêm một Port (như `IProjectSettingRepository`) vào UseCase, **Bắt Buộc** phải cung cấp Adapter / Repository implementation và cấu hình Export ở Infrastructure level (`typeorm.module.ts`), nếu không NestJS App sẽ sập lúc bootstrap vì lỗi DI Container.

---

## 4. Lỗi Kiến Trúc Repository (Lần 2 - 28/02/2026 19:16)

### Lỗi 7: Repository không tuân thủ Pattern chuẩn từ EXAMPLES.md (Domain Data Persistence Flow)

- **Vấn đề phát hiện:** Repository ở Infrastructure layer không thực sự "persist data" đúng flow DDD. Cụ thể, các Repository được Agent tạo ra trước đó (SqlSnippetRepository, TableMetadataRepository, ProjectSettingRepository) sử dụng shortcut method từ `BaseRepositoryTypeORM` (`this.findOneBy()`, `this.find()`) thay vì tuân thủ pattern rõ ràng trong `EXAMPLES.md` (dòng 334-415).

- **Pattern ĐÚNG theo EXAMPLES.md** (Order Repository example):

    ```
    Flow: Controller → UseCase → Repository.findById()
    Repository.findById():
      1. const orm = await this.repository.findOne({ where: { id }, relations: [...] });
      2. if (!orm) return null;
      3. return this.mapper.toDomain(orm);  // ← Chuyển ORM → Domain TƯỜNG MINH

    Repository.save(domain):
      1. const result = await super.saveOne(domain);  // ← BaseRepo tự gọi mapper.toOrm()
      2. await this.dispatchDomainEventsForAggregates(result);
      3. return result;  // ← Domain entity đã được mapper.toDomain() trong saveOne
    ```

- **Pattern SAI trước khi fix:**

    ```
    findById(id: string): Promise<Domain | null> {
        return this.findOneBy({ id });  // ← Dùng shortcut, KHÔNG rõ ràng mapper flow
    }
    ```

- **Lý do phải sửa:**
    1. Khi cần `relations` (eager loading), shortcut methods **không hỗ trợ** → phải dùng `this.repository.findOne()` trực tiếp.
    2. Code phải **tường minh** thể hiện flow: ORM query → mapper.toDomain() → return Domain entity.
    3. Nhất quán với EXAMPLES.md giúp Agent/Developer dễ tra cứu, dễ debug.

- **Lỗi phụ - Mapper Init:** Dùng `new ProjectSettingMapper()` thay vì `ProjectSettingMapper.create()`. `BaseMapper` cung cấp sẵn static `create()` method. Phải dùng factory method `XxxMapper.create()` để nhất quán.

### Khắc phục

Đã refactor toàn bộ 3 Repository (SqlSnippet, TableMetadata, ProjectSetting):

- Query methods: Dùng `this.repository.findOne()` / `this.repository.find()` → check null → `this.mapper.toDomain(orm)`.
- Save method: Giữ nguyên `super.saveOne(domain)` + `dispatchDomainEventsForAggregates()`.
- Constructor: Dùng `XxxMapper.create()` thay vì `new XxxMapper()`.

### Ghi chú về Customer Repository (Ngoại lệ)

`CustomerRepository` (persistence/modules/customer) là module **Import Engine** — không có Domain Entity / Aggregate Root đầy đủ. Interface `ICustomerRepository` chỉ định nghĩa utility methods (`existsByEmail`, `deleteByIds`, `createWithRelations`) phục vụ batch import CSV. Đây là ngoại lệ có chủ đích vì:

1. Không có class `Customer extends BaseAggregateRoot` ở domain layer.
2. Batch import cần performance, bypass DDD mapper layer.
3. Khi mở rộng Customer thành full DDD aggregate, cần refactor theo đúng pattern.

---

## 5. Checklist Bổ Sung (Repository Pattern)

- [ ] **Checklist 7:** Repository **BẮT BUỘC** tuân thủ pattern tường minh từ `EXAMPLES.md`:
    - Query methods: `this.repository.findOne(...)` → null check → `this.mapper.toDomain(orm)`.
    - List methods: `this.repository.find(...)` → `orms.map((orm) => this.mapper.toDomain(orm))`.
    - **KHÔNG** dùng shortcut `this.findOneBy()` / `this.find()` từ base class (trừ khi chắc chắn không cần relations và đã review base class).
- [ ] **Checklist 8:** Mapper khởi tạo trong Repository constructor **BẮT BUỘC** dùng `XxxMapper.create()` factory method (từ `BaseMapper.create()`), KHÔNG dùng `new XxxMapper()`.
- [ ] **Checklist 9:** Mọi Repository impl **PHẢI** extend `BaseRepositoryTypeORM<DomainEntity, OrmEntity>` và override `save()` với `super.saveOne()` + `dispatchDomainEventsForAggregates()`. Ngoại lệ chỉ áp dụng cho module utility không có Domain Aggregate (phải ghi comment giải thích lý do).

_Tài liệu này được lưu trữ để làm tham chiếu ngữ cảnh tránh lỗi cho vòng đời Agent LLMs phía sau hoạt động ổn định và chính xác hơn._
