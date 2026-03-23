Dưới đây là nội dung được định dạng lại hoàn chỉnh dưới dạng **Markdown**:

# Topup-Orchestrator Scope

## 1. Phạm vi tổng thể

**Topup-Orchestrator** chịu trách nhiệm điều phối toàn bộ quy trình nạp tiền, bao gồm:

- Toàn bộ logic orchestration
- Saga workflow
- Kết nối với external services
- Đảm bảo tính nhất quán xuyên suốt quá trình giao dịch

Hệ thống được thiết kế theo **Hexagonal Architecture**, trong đó:

- Domain nằm ở trung tâm
- Mọi tương tác bên ngoài đi qua **Inbound/Outbound Ports**

## 2. In-Scope – Những gì Orchestrator xử lý

### 2.1 Inbound Request Handling

Nhận request topup từ các nguồn:

- REST API
- WebSocket
- Partner API (OpenAPI)
- Kafka callback (từ các connector hoặc wallets)

Thực hiện kiểm tra:

- Access token (SSO)
- Maintenance mode
- Rate limit
- Payload validation

### 2.2 Transaction Lifecycle

Orchestrator quản lý toàn bộ vòng đời giao dịch:

```
INITIATED → USER_CHECKED → FEE_CALCULATED → PROMO_APPLIED
          → WALLET_RESERVED → CONNECTOR_CALLED → CONFIRMED/REVERSED
          → SUCCESS / FAILED / PENDING
```

Các hành động chính:

- Khởi tạo giao dịch (idempotent)
- Cập nhật trạng thái theo từng bước Saga
- Ghi nhận error code, message, metadata

### 2.3 Business Eligibility Checking

- Kiểm tra user hợp lệ qua **App-Service** (tùy channel: merchant/consumer/agent…)
- Kiểm tra giới hạn giao dịch theo rule
- Kiểm tra điều kiện đầu vào (min/max amount…)

### 2.4 Fee & Promotion

- Gọi **Rule-Service**:
  - Tính phí
  - Tính commission/discount (nếu có)
- Gọi **Promotion-Service**:
  - Apply mã khuyến mãi
  - Ghi lại thông tin promotion áp dụng

### 2.5 Wallet Coordination (Reserve/Confirm/Reverse)

Gọi **Wallet-Service** để:

- Check ví hợp lệ (active, locked, KYC…)
- Reserve số tiền nạp
- Confirm khi giao dịch connector thành công
- Reverse khi thất bại hoặc timeout

### 2.6 Connector Routing & Integration

- Xác định connector thông qua bảng routing + rule
- Chuẩn hóa request gửi sang các connector
- Nhận kết quả từ connector:
  - SUCCESS
  - BUSINESS_ERROR
  - PENDING
- Xử lý polling nếu connector trả trạng thái pending lâu

### 2.7 Saga Orchestration

Điều phối theo **Nest-Convoy Saga**:

1. Step 1: Kiểm tra user
2. Step 2: Tính phí
3. Step 3: Apply promotion
4. Step 4: Reserve ví
5. Step 5: Gọi connector
6. Step 6: Confirm/Reverse ví

→ Tự động rollback (reverse funds) khi có lỗi

### 2.8 Message Publishing (Event-driven)

Phát các sự kiện ra Kafka:

- `topup.started`
- `topup.succeeded`
- `topup.failed`
- `topup.pending_manual`
- `topup.connector_timeout`

### 2.9 Observability

- OpenTelemetry tracing full chain
- Structured logging theo chuẩn FinViet
- Prometheus metrics per-step
- Audit log transaction

### 2.10 Fault-tolerance & Reliability

- Circuit breaker cho mọi external calls
- Timeout → auto rollback hoặc chuyển pending
- Retry policy theo cấu hình
- Outbox/Inbox đảm bảo không mất events
- Idempotency key cho mọi yêu cầu

## 3. Out-of-Scope – Những gì Orchestrator không xử lý

### 3.1 Không xử lý nghiệp vụ ví

- Không thay đổi số dư trực tiếp
- Không maintain ledger
- Không quyết định fee final (chỉ relay từ Rule-Service)

### 3.2 Không xử lý xác thực người dùng

- Token SSO được validate qua middleware hoặc AuthGuard

### 3.3 Không xử lý nghiệp vụ phía connector

- Không gọi trực tiếp bank/telco
- Không quản lý polling logic phức tạp của từng connector
  (connector-service sẽ tự xử lý và callback)

### 3.4 Không xử lý báo cáo BI/settlement

- Báo cáo được lấy từ Topup Tx DB và các topic events
- Không tổng hợp revenue, reconciliation

### 3.5 Không lưu cache routing/phí/phê duyệt ở local

- Cache routing được lưu Redis nhưng data gốc thuộc Masterdata/Config Service

## 4. Ranh giới giao tiếp với các hệ thống khác

| Hệ thống                 | Chức năng                           | Giao thức              |
| -------------------------- | ------------------------------------- | ----------------------- |
| App-Service                | Kiểm tra user hợp lệ               | HTTP                    |
| Rule-Service               | Tính phí/commission                 | HTTP                    |
| Promotion-Service          | Áp dụng promotion                   | HTTP                    |
| Wallet-Service             | Reserve/Confirm/Reverse               | HTTP                    |
| Wallet-Integration-Service | Trigger reserve ví                   | HTTP                    |
| Connector-Service          | Thực hiện giao dịch nhà cung cấp | HTTP / Kafka / Rabbitmq |
| Event Bus                  | Emit event topup.*                    | Kafka                   |
| Redis                      | Idempotency + cache routing           | Redis                   |

## 5. Deliverables của Orchestrator

- UseCase tổng hợp cho luồng topup
- Saga flow đầy đủ
- Transaction model + DB schema
- Quy chuẩn logging/tracing/metrics
- API REST/WS/Callback
- Bộ topic event-driven chuẩn hóa
- Bộ config routing/connector
- Backlog: **Epic → User Story → Sub-Tasks**

Hy vọng định dạng này rõ ràng và dễ theo dõi!
