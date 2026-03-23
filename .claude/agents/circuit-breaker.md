# Circuit Breaker

## 1. Giới thiệu

Circuit Breaker là thành phần thuộc lớp Resilience Layer giúp bảo vệ Topup-Orchestrator và các Connector-X-Service khi các dependency bị lỗi/chậm như:

- Wallet-Service
- Rule-Service
- Promotion-Service
- App-Service
- Các Telco API / ví ngoài (Momo, ViettelPay, VNPT…)

Mục tiêu chính:

- Fail fast – không chờ những dependency đang “chết”
- Bảo vệ tài nguyên – tránh nghẽn event loop, tránh làm backlog saga phình to
- Ổn định hệ thống – ngăn lỗi lan truyền theo dây chuyền
- Tự động phục hồi – test nhẹ nhàng trong trạng thái HALF_OPEN

## 2. Mục tiêu của Circuit Breaker

Khi dependency bắt đầu có vấn đề → mở mạch (OPEN)
Mọi request sẽ reject ngay trong vài ms.

Sau một thời gian → mở mạch nửa (HALF_OPEN)
Chỉ cho phép một số ít request test.

Khi dependency ổn định lại → đóng mạch (CLOSED)
Hệ thống hoạt động bình thường.

Không tính lỗi business vào failure rate
Ví dụ: INSUFFICIENT_BALANCE từ Wallet không làm mở breaker.

## 3. Vị trí trong kiến trúc Hexagonal

Circuit Breaker nằm trong:

infrastructure/
  resilience/
    circuit-breaker.ts
    retry.strategy.ts
    timeout.executor.ts
    bulkhead.limiter.ts

Được dùng tại:
Outbound Adapter

wallet.http-client.ts
connector.http-client.ts
rule.http-client.ts
promotion.http-client.ts
app-service.http-client.ts

Không nằm trong domain/service layer.

Architecture Snapshot

*(Ghi chú: Phần này chứa diagram kiến trúc. Trong PDF gốc, có hình ảnh snapshot.)*

## 4. Các thành phần & Class Design

### 4.1. Danh sách class chính

- CircuitBreakerPolicy – Chính sách per dependency key
- CircuitBreakerSnapshot – Trạng thái runtime
- CircuitBreakerMetrics – Ghi nhận thống kê
- CircuitBreaker (interface) – API chung
- DefaultCircuitBreaker – Implementation
- CircuitBreakerRegistry – Khởi tạo & DI
- ResilienceExecutor – Wrapper timeout + retry + bulkhead + CB
- ResilienceLogger – logging + state change
- Outbound Clients: WalletHttpClient, ConnectorHttpClient...

### 4.2. Class Diagram chi tiết

*(Ghi chú: Phần này chứa Class Diagram. Trong PDF gốc, có hình ảnh diagram chi tiết.)*

## 5. Chi tiết hành vi State Machine

### 5.1. CLOSED → OPEN

Điều kiện:

- totalCalls >= minimumCalls
- failureRate >= failureRateThreshold
- hoặc
- slowCallRate >= slowCallRateThreshold

Hành động:

- Chuyển sang OPEN
- openUntil = now + openStateDurationMs
- log state change

### 5.2. OPEN → HALF_OPEN

Khi:

- now >= openUntil

Hành động:
set halfOpenRemainingPermits = halfOpenMaxCalls
chuyển sang HALF_OPEN

### 5.3. HALF_OPEN → CLOSED

Khi:

tt c n request trong HALF_OPEN u thành công

### 5.4. HALF_OPEN → OPEN

Khi:

bt k request test nào tht bi

## 6. Sequence Diagram: Saga Step → Circuit Breaker → Wallet

*(Ghi chú: Phần này chứa Sequence Diagram. Trong PDF gốc, có hình ảnh diagram chi tiết về Saga Step với Circuit Breaker và Wallet.)*

## 7. Chính sách cụ thể (Policy Example)

```yaml
circuitBreaker:
  policies:
    - key: "wallet.reserve"
      failureRateThreshold: 50
      slidingWindowSize: 50
      minimumCalls: 20
      slowCallDurationMs: 500
      slowCallRateThreshold: 80
      openStateDurationMs: 10000
      halfOpenMaxCalls: 5

    - key: "connector.momo.topup"
      failureRateThreshold: 30
      slidingWindowSize: 100
      minimumCalls: 20
      slowCallDurationMs: 800
      slowCallRateThreshold: 60
      openStateDurationMs: 15000
      halfOpenMaxCalls: 3
```

## 8. Logging & Observability

### 8.1. Log state change

```log
[CIRCUIT_BREAKER] key=wallet.reserve
transition=CLOSED → OPEN
failureRate=67%
slowCallRate=43%
openUntil=2025-11-14T10:25:00.233Z
```

### 8.2. Metric xuất (Prometheus)

cb_state{key="wallet.reserve"}
cb_open_total{key="connector.momo.topup"}
cb_failure_rate{key="wallet.reserve"}

### 8.3. Trace attribute (OpenTelemetry)

cb.state=OPEN
cb.key=connector.momo.topup

## 9. Best Practice

- Không tính lỗi business vào failure rate.Ví dụ: INSUFFICIENT_BALANCE.
- Timeout thấp, openStateDuration dài để tránh “flapping”.
- Tách biệt breaker theo key (per dependency).
- Dùng in-memory breaker cho POC; sau này có thể nâng cấp sang distributed (Redis).
- Luôn kết hợp với:
  - Timeout
  - Bulkhead
  - Retry (với backoff)
  - Idempotency

## 10. Hướng dẫn tích hợp

### CircuitBreakerPolicy

```typescript
// resilience/circuit-breaker.policy.ts
interface CircuitBreakerPolicy {
  key: string;                   // 'connector.momo.topup'
  failureRateThreshold: number;  // 50 (%) lỗi → mở
  slidingWindowSize: number;     // 50 (số request trong cửa sổ)
  minimumCalls: number;          // 20 (tối thiểu trước khi evaluate)
  slowCallDurationMs: number;    // 500 (ms)
  slowCallRateThreshold: number; // 80 (%)
  openStateDurationMs: number;   // 10000 (ms)
  halfOpenMaxCalls: number;      // 5 (số call test ở HALF_OPEN)
}
```

Policy sẽ được load từ config:

```typescript
interface CircuitBreakerConfig {
  policies: CircuitBreakerPolicy[];
}
```

### CircuitBreakerStateType & CircuitBreakerSnapshot

Vai trò: mô tả state hiện tại của breaker cho một key.

```typescript
// resilience/circuit-breaker.types.ts
enum CircuitBreakerStateType {
  CLOSED = 'CLOSED',
  OPEN = 'OPEN',
  HALF_OPEN = 'HALF_OPEN',
}

interface CircuitBreakerSnapshot {
  key: string;
  state: CircuitBreakerStateType;
  failureRate: number;               // (failedCalls / totalCalls) * 100
  slowCallRate: number;              // (slowCalls / totalCalls) * 100
  totalCalls: number;
  failedCalls: number;
  slowCalls: number;
  lastStateChangeAt: Date;
  openUntil?: Date;                  // nếu OPEN
  halfOpenRemainingPermits?: number; // nếu HALF_OPEN
}
```

### CircuitBreakerMetrics

Vai trò: ghi nhận thống kê cho từng key (trong sliding window).

```typescript
// resilience/circuit-breaker.metrics.ts
interface CircuitBreakerMetrics {
  recordSuccess(key: string, durationMs: number): void;
  recordFailure(key: string, durationMs: number, error: Error): void;
  getSnapshot(key: string): CircuitBreakerSnapshot;
}
```

- recordSuccess:tăng totalCalls, nếu durationMs > slowCallDurationMs tăng slowCalls.
- recordFailure:
  tăng totalCalls, failedCalls, có thể tăng slowCalls nếu timeout.

(Logic bên trong bạn tự implement, có thể dùng ring buffer / sliding window per key.)

### CircuitBreaker (interface) & DefaultCircuitBreaker (implementation)

Interface

```typescript
// resilience/circuit-breaker.interface.ts
interface CircuitBreakerExecuteOptions {
  ignoreError?: (error: Error) => boolean; // trả về true nếu lỗi là business error không tính vào failure rate
}

interface CircuitBreaker {
  execute<T>(
    key: string,
    fn: () => Promise<T>,
    options?: CircuitBreakerExecuteOptions,
  ): Promise<T>;

  getSnapshot(key: string): CircuitBreakerSnapshot;
}
```

Implementation

```typescript
// resilience/default-circuit-breaker.ts
class DefaultCircuitBreaker implements CircuitBreaker {
  private readonly policies: Map<string, CircuitBreakerPolicy>;
  private readonly metrics: CircuitBreakerMetrics;
  private readonly states: Map<string, CircuitBreakerSnapshot>;
  private readonly logger: ResilienceLogger;

  constructor(
    policies: CircuitBreakerPolicy[],
    metrics: CircuitBreakerMetrics,
    logger: ResilienceLogger,
  ) {
    // init map
  }

  async execute<T>(
    key: string,
    fn: () => Promise<T>,
    options?: CircuitBreakerExecuteOptions,
  ): Promise<T> {
    // 1. preCheckState(key) → throw nếu OPEN
    // 2. Đo thời gian thực thi fn()
    // 3. recordSuccess / recordFailure
    // 4. tryTransitionState(key)
  }

  getSnapshot(key: string): CircuitBreakerSnapshot {
    // trả về snapshot hiện tại (hoặc default)
  }

  private preCheckState(key: string): void {
    // - Nếu state = OPEN và chưa hết openUntil → throw CircuitBreakerOpenError
    // - Nếu state = OPEN và đã hết openUntil → chuyển sang HALF_OPEN, reset halfOpenRemainingPermits
    // - Nếu state = HALF_OPEN thì giảm halfOpenRemainingPermits (nếu <0 → block)
  }

  private postRecordSuccess(key: string, durationMs: number): void {
    // metrics.recordSuccess(...)
    // tryTransitionState(key)
  }

  private postRecordFailure(
    key: string,
    durationMs: number,
    error: Error,
    options?: CircuitBreakerExecuteOptions,
  ): void {
    // nếu ignoreError(error) → coi như success cho breaker (chỉ là business error)
    // ngược lại → metrics.recordFailure(...)
    // tryTransitionState(key)
  }

  private tryTransitionState(key: string): void {
    // dựa trên snapshot + policy:
    // - CLOSED → OPEN nếu failureRate >= threshold, totalCalls >= minimumCalls
    // - HALF_OPEN → CLOSED nếu số call success
    // - HALF_OPEN → OPEN nếu còn fail
    // emit logStateChange
  }
}
```

### CircuitBreakerRegistry

Vai trò: central DI để lấy breaker theo tên (nếu sau này bạn muốn nhiều breaker với policy khác nhau).

```typescript
// resilience/circuit-breaker.registry.ts
class CircuitBreakerRegistry {
  private readonly breakers: Map<string, CircuitBreaker>;
  private readonly policies: CircuitBreakerPolicy[];
  private readonly metricsFactory: () => CircuitBreakerMetrics;
  private readonly logger: ResilienceLogger;

  constructor(
    policies: CircuitBreakerPolicy[],
    metricsFactory: () => CircuitBreakerMetrics,
    logger: ResilienceLogger,
  ) {}

  getBreaker(name: string): CircuitBreaker {
    // name ví dụ: 'default', 'critical-deps',...
    // nếu chưa có thì khởi tạo DefaultCircuitBreaker với policies phù hợp
  }

  getPolicy(key: string): CircuitBreakerPolicy {
    // tìm policy theo key, nếu không có → trả về policy mặc định
  }
}
```

### ResilienceExecutor

Vai trò: là “entry point” cho các HTTP client dùng, wrap chung: timeout + retry + bulkhead + circuit breaker.

```typescript
// resilience/resilience.executor.ts
interface ResilienceExecuteOptions<T> {
  key: string;                         // dùng cho circuit breaker & metrics
  operation: () => Promise<T>;         // hàm thực sự gọi HTTP/gRPC
  timeoutMs?: number;
  retryPolicy?: RetryPolicy;
  bulkheadKey?: string;
  circuitBreakerOptions?: CircuitBreakerExecuteOptions;
}

class ResilienceExecutor {
  constructor(
    private readonly circuitBreaker: CircuitBreaker,
    private readonly retryStrategy: RetryStrategy,
    private readonly timeoutExecutor: TimeoutExecutor,
    private readonly bulkheadLimiter: BulkheadLimiter,
  ) {}

  async execute<T>(opts: ResilienceExecuteOptions<T>): Promise<T> {
    const { key, operation, timeoutMs, retryPolicy, bulkheadKey, circuitBreakerOptions } = opts;

    // pseudo-flow:
    // 1. wrap operation trong timeoutExecutor (nếu có timeoutMs)
    // 2. wrap trong bulkheadLimiter (nếu có bulkheadKey)
    // 3. wrap trong retryStrategy (nếu có retryPolicy)
    // 4. cuối cùng: circuitBreaker.execute(key, wrappedOperation, circuitBreakerOptions)
  }
}
```

### Logger & metrics integration – ResilienceLogger

```typescript
// resilience/resilience.logger.ts
class ResilienceLogger {
  logStateChange(
    snapshot: CircuitBreakerSnapshot,
    prevState: CircuitBreakerStateType,
  ): void {
    // log structured + emit metric nếu cần
  }

  logFailure(key: string, error: Error, durationMs: number): void {
    // log chi tiết cho debugging
  }

  logSlowCall(key: string, durationMs: number): void {
    // log slow call
  }
}
```

### Tích hợp với HTTP Client (Wallet / Connector)

Ví dụ: wallet.http-client.ts

```typescript
// infrastructure/http-clients/wallet.http-client.ts
class WalletHttpClient {
  constructor(
    private readonly httpService: HttpService,
    private readonly resilienceExecutor: ResilienceExecutor,
  ) {}

  async reserve(request: WalletReserveRequest): Promise<WalletReserveResponse> {
    return this.resilienceExecutor.execute({
      key: 'wallet.reserve',
      timeoutMs: 1000,
      retryPolicy: {
        maxAttempts: 2,
        backoffMs: 100,
        retryOn: (error) => this.isTransientError(error),
      },
      bulkheadKey: 'wallet',
      circuitBreakerOptions: {
        ignoreError: (error) => this.isBusinessError(error),
      },
      operation: async () => {
        // chỉ chứa logic gọi HTTP, không concern circuit breaker
        // ví dụ: await this.httpService.post(...)
        return {} as WalletReserveResponse;
      },
    });
  }

  private isTransientError(error: Error): boolean {
    // 5xx, timeout, connect error,...
    return false;
  }

  private isBusinessError(error: Error): boolean {
    // lỗi như INSUFFICIENT_BALANCE → không tính là failure breaker
    return false;
  }
}
```

Tương tự cho ConnectorHttpClient:

```typescript
class ConnectorHttpClient {
  constructor(
    private readonly httpService: HttpService,
    private readonly resilienceExecutor: ResilienceExecutor,
  ) {}

  async topup(request: ConnectorTopupRequest): Promise<ConnectorTopupResponse> {
    return this.resilienceExecutor.execute({
      key: 'connector.momo.topup',
      timeoutMs: 1500,
      retryPolicy: {
        maxAttempts: 1,
        backoffMs: 200,
        retryOn: (error) => this.isTransientError(error),
      },
      bulkheadKey: 'connector.momo',
      operation: async () => {
        // call REST/soap/gRPC telco
        return {} as ConnectorTopupResponse;
      },
    });
  }

  private isTransientError(error: Error): boolean {
    return false;
  }
}
```

*(Ghi chú: Các phần diagram và hình ảnh trong PDF gốc không thể hiển thị trực tiếp trong Markdown text. Nếu cần, có thể tham chiếu đến file PDF gốc hoặc sử dụng công cụ để nhúng hình ảnh.)*
