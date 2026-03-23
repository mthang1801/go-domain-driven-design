# SOLID Rule

## 1. S – Single Responsibility Principle

**Mỗi class/module chỉ nên có một lý do để thay đổi.**

### Trong Topup-Orchestrator (Clean Architecture + DDD core):

#### `start-topup.use-case.ts` (BaseCommand):

* Chi lo orchestrate luong start topup (goi Saga, kiem tra idempotent, init transaction)
* **Không** validate DTO, không gọi trực tiếp HTTP đến Wallet, không truy cập DB

#### `topup.saga.ts`:

* Chi lo quan ly lifecycle cua Saga (step hien tai, next step, compensation)
* **Không** chứa logic tính phí hay gọi wallet

#### `routing.service.ts`:

* Chi lo tim route & connector dua tren cau hinh
* **Không** chứa logic reserve ví hay mapping DTO sang third-party

#### `wallet.client.ts`:

* Chi lo call Wallet-Service + mapping request/response
* **Không** quyết định business state của TopupTransaction

### ✅ Check nhanh:

Nếu bạn thấy một class mà vừa validate vừa call 3 service vừa lưu DB → chắc chắn đang vi phạm  **S** , nên tách.

---

## 2. O – Open/Closed Principle

**Mở rộng được nhưng hạn chế sửa code cũ.**

### Trong bối cảnh topup:

#### Thêm nhà mạng / connector mới:

* **Không** sửa domain core, chỉ:
  * Thêm config routing
  * Thêm adapter mới: `XYZConnectorClient` implement `ConnectorPort`

#### Thêm step mới cho Saga (ví dụ: Risk-Check):

* **Không** rewrite `topup.saga.ts`, mà:
  * Thêm một step mới (implement `SagaStep` interface)
  * Thêm vào pipeline/DSL phần config Saga

### Clean Architecture + Port/Adapter ho tro O:

**WalletPort, ConnectorPort, RulePort:**

* Domain chỉ biết port (interface)
* Muốn đổi HTTP → gRPC, hay đổi lib HTTP → không cần sửa domain, chỉ đổi adapter

### ✅ Tiêu chí review:

> "Khi add connector mới, bao nhiêu file core phải sửa? Nếu bạn chạm vào domain nhiều → đang trái O."

---

## 3. L – Liskov Substitution Principle

**Subclass / implementation có thể thay thế cho base class/interface mà không làm hỏng logic.**

### Trong kien truc cua ban, L ap dung chu yeu cho:

#### Cac Port trong domain:

**ConnectorPort** có thể có nhiều implement:

* `TelcoConnectorClient`
* `BankConnectorClient`
* `CardConnectorClient`
* ...

Saga không cần biết cụ thể loại nào, miễn thằng nào implement port thì hành vi phải đúng kỳ vọng (không throw những thứ "lạ lùng", không nuốt lỗi im lặng).

#### WalletPort:

Dù sau này bạn tách thành nhiều loại ví (consumer, merchant, agent) thì mỗi implement vẫn phải "hành xử" như 1 WalletPort chuẩn:

* `reserve`
* `confirm`
* `reverse`
* Lỗi trả về đúng kiểu domain error (không tự ý deviate)

### ⚠️ Y nghia thuc te:

Đừng làm kiểu "implement ConnectorPort nhưng lại throw NotSupported cho các method mà Saga trông chờ luôn luôn có".

Nếu một implementation không support một số behavior → nên tách port nhỏ lại (gắn với  **I – Interface Segregation** ).

---

## 4. I – Interface Segregation Principle

**Tot hon la nhieu interface nho, moi interface phuc vu dung 1 nhom client, hon la 1 interface "God Interface".**

### Trong Topup-Orchestrator:

#### ❌ Thay vi:

```typescript
interface ExternalServicesPort {
  callWallet(...)
  callRule(...)
  callPromotion(...)
  callConnector(...)
  callAppService(...)
}
```

#### ✅ Tach ra:

* `WalletPort`
* `RulePort`
* `PromotionPort`
* `ConnectorPort`
* `AppServicePort`

### Trong domain:

Entity `TopupTransaction` không nên phụ thuộc vào một port "tổng hợp" mà nó không dùng hết.

### Ke ca voi inbound:

* Đừng tạo 1 controller khổng lồ với 20 endpoint / dto trong 1 file
* Tách `TopupController`, `StatusController`, `WebhookController` như trong cấu trúc hiện tại

### ✅ Tieu chi:

Nếu một adapter implement một interface nhưng chỉ dùng 20% method còn lại toàn throw `Error('NotImplemented')` → đang vi phạm  **I** , nên split interface.

---

## 5. D – Dependency Inversion Principle

**Cap cao (domain, application) khong phu thuoc truc tiep vao cap thap (HTTP, DB, Kafka), ma tat ca phu thuoc interface.**

### Trong kien truc cua ban, D la "linh hon" cua Clean Architecture + DDD:

#### Domain/Application layer:

* Phu thuoc `TopupTxRepositoryPort`, `WalletPort`, `ConnectorPort`, `RulePort`, `EventPort` (interface trong domain/ports)
* **Khong** import Prisma, khong import Axios, khong import Nest HttpService

#### Infrastructure layer:

Implement các port:

* `TopupTxRepository` (TypeORM/Mongoose) ke thua `BaseRepositoryTypeORM` neu dung TypeORM
* `WalletHttpClient`
* `ConnectorHttpClient`
* `RuleGrpcClient`
* `KafkaEventPublisher`

Những thằng này mới phụ thuộc cụ thể vào driver.

### Ket qua:

* Doi Postgres -> CockroachDB -> chi sua `TopupTxRepository`
* Doi Kafka -> NATS -> chi sua `KafkaEventPublisher` thanh `NatsEventPublisher`, domain khong dong toi

### ✅ Check nhanh:

Nếu trong `start-topup.usecase.ts` mà bạn thấy import như:

```typescript
import { HttpService } from '@nestjs/axios'
import { PrismaService } from '...'
```

→ thì đang vi phạm **D** và bỏ kiến trúc hexagonal.

---

## 6. Nhìn tổng thể: Pattern lớn + SOLID bổ trợ nhau

### Clean Architecture, DDD core, Saga, Outbox, Circuit breaker…:

-> thiet ke "cap service", "cap he thong"

### SOLID:

-> guideline "cap class/module", giup nhung pattern lon kia khong bi bien thanh "spaghetti"

### Trong Topup-Orchestrator:

* **Clean Architecture** = boundary (ports & adapters)
* **Saga** = orchestration (use cases / steps)
* **Outbox / Inbox** = reliability
* **SOLID** = chất lượng code bên trong mỗi layer

---

## 7. Gợi ý: SOLID Checklist cho Topup-Orchestrator

Bạn có thể đưa vào guideline review PR cho team (kiểu checklist):

### S (Single Responsibility):

* [ ] Mỗi class có đúng 1 nhiệm vụ rõ ràng?
* [ ] Controller mỏng, UseCase không chứa HTTP/DB logic?

### O (Open/Closed):

* [ ] Thêm connector mới / step mới, có cần sửa domain core nhiều không?

### L (Liskov Substitution):

* [ ] Mỗi implementation của Port có behave đúng expectation?
* [ ] Có throw NotImplemented vô tội vạ không?

### I (Interface Segregation):

* [ ] Có interface nào "béo phì" mà implementation không dùng hết?

### D (Dependency Inversion):

* [ ] Domain/Application có import bất kỳ thứ gì từ infrastructure hoặc framework-specific (Nest, Prisma, Axios, Kafka client) không?

---

**Áp dụng SOLID giúp code dễ maintain, test và mở rộng trong dài hạn! 🚀**
