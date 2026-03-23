# Redis Stream Guidelines

Tài liệu hướng dẫn sử dụng Redis Stream APIs trong hệ thống.

## Mục lục

1. [Tổng quan về Redis Streams](#tổng-quan-về-redis-streams)
2. [API Endpoints](#api-endpoints)
3. [Các Use Cases](#các-use-cases)
4. [Best Practices](#best-practices)
5. [Ví dụ sử dụng](#ví-dụ-sử-dụng)

## Tổng quan về Redis Streams

Redis Streams là một cấu trúc dữ liệu mạnh mẽ cho việc xử lý event streaming, message queues, và real-time data processing. Nó cung cấp:

- **Persistent logs**: Lưu trữ messages theo thời gian
- **Consumer Groups**: Hỗ trợ nhiều consumers xử lý messages
- **Message acknowledgment**: Đảm bảo messages được xử lý
- **Message claiming**: Xử lý messages bị timeout
- **Blocking reads**: Đọc messages real-time

## API Endpoints

### 1. Basic Stream Operations

#### 1.1. Add Message to Stream

**Endpoint:** `POST /redis/stream/add`

**Body:**
```json
{
  "key": "user-events",
  "fields": {
    "action": "login",
    "userId": "12345",
    "timestamp": 1234567890
  },
  "id": "*"
}
```

**Response:**
```json
{
  "messageId": "1234567890-0",
  "key": "user-events"
}
```

**Mô tả:** Thêm một message vào stream. Sử dụng `*` để tự động generate ID.

#### 1.2. Get Stream Length

**Endpoint:** `GET /redis/stream/:key/length`

**Example:** `GET /redis/stream/user-events/length`

**Response:**
```json
{
  "key": "user-events",
  "length": 100
}
```

#### 1.3. Read Messages (Range)

**Endpoint:** `GET /redis/stream/:key/range`

**Query Parameters:**
- `start`: Start ID (default: `-` for beginning)
- `end`: End ID (default: `+` for end)
- `count`: Maximum number of messages (optional)

**Example:** `GET /redis/stream/user-events/range?start=-&end=+&count=10`

**Response:**
```json
{
  "key": "user-events",
  "count": 10,
  "messages": [
    {
      "id": "1234567890-0",
      "fields": {
        "action": "login",
        "userId": "12345"
      }
    }
  ]
}
```

#### 1.4. Read Messages (Reverse Range)

**Endpoint:** `GET /redis/stream/:key/rev-range`

**Query Parameters:**
- `end`: End ID (default: `+`)
- `start`: Start ID (default: `-`)
- `count`: Maximum number of messages (optional)

**Example:** `GET /redis/stream/user-events/rev-range?count=10`

**Response:** Tương tự như range, nhưng theo thứ tự ngược lại.

#### 1.5. Get Stream Info

**Endpoint:** `GET /redis/stream/:key/info`

**Example:** `GET /redis/stream/user-events/info`

**Response:**
```json
{
  "key": "user-events",
  "info": {
    "length": 100,
    "first-entry": { ... },
    "last-entry": { ... },
    "groups": 2,
    ...
  }
}
```

#### 1.6. Read from Stream (Blocking)

**Endpoint:** `POST /redis/stream/read`

**Body:**
```json
{
  "streams": [
    {
      "key": "user-events",
      "id": "$"
    }
  ],
  "count": 10,
  "block": 5000
}
```

**Mô tả:** Đọc messages với blocking. `id: "$"` để đọc messages mới. `block` là timeout milliseconds.

**Response:**
```json
{
  "count": 1,
  "messages": [
    {
      "name": "user-events",
      "messages": [...]
    }
  ]
}
```

### 2. Consumer Groups

#### 2.1. Create Consumer Group

**Endpoint:** `POST /redis/stream/:key/group/create`

**Body:**
```json
{
  "group": "order-processors",
  "id": "$",
  "mkStream": false
}
```

**Parameters:**
- `group`: Tên consumer group
- `id`: Starting ID (`$` for latest, `0` for beginning)
- `mkStream`: Tạo stream nếu chưa tồn tại

**Response:**
```json
{
  "key": "orders",
  "group": "order-processors",
  "message": "Consumer group created successfully"
}
```

#### 2.2. Create Consumer Group If Not Exists

**Endpoint:** `POST /redis/stream/:key/group/create-if-not-exists`

**Body:** Tương tự như create

**Response:**
```json
{
  "key": "orders",
  "group": "order-processors",
  "created": true,
  "message": "Consumer group created"
}
```

**Mô tả:** Tạo consumer group nếu chưa tồn tại, không throw error nếu đã tồn tại.

#### 2.3. Read from Consumer Group

**Endpoint:** `POST /redis/stream/:key/group/read`

**Body:**
```json
{
  "group": "order-processors",
  "consumer": "worker-1",
  "id": ">",
  "count": 10,
  "block": 5000,
  "noack": false
}
```

**Parameters:**
- `group`: Tên consumer group
- `consumer`: Tên consumer
- `id`: Message ID (`>` for new messages)
- `count`: Số lượng messages tối đa
- `block`: Block timeout (milliseconds)
- `noack`: Không cần acknowledge

**Response:**
```json
{
  "key": "orders",
  "group": "order-processors",
  "consumer": "worker-1",
  "count": 5,
  "messages": [...]
}
```

### 3. Pending Messages

#### 3.1. Get Pending Messages Info

**Endpoint:** `GET /redis/stream/:key/group/:group/pending`

**Query Parameters:**
- `start`: Start ID (optional)
- `end`: End ID (optional)
- `count`: Maximum count (optional)
- `consumer`: Filter by consumer (optional)

**Example:** 
- `GET /redis/stream/orders/group/order-processors/pending` - Tổng quan
- `GET /redis/stream/orders/group/order-processors/pending?start=0&end=9999999999999&count=10` - Chi tiết

**Response (Tổng quan):**
```json
{
  "key": "orders",
  "group": "order-processors",
  "pending": {
    "count": 5,
    "lower-id": "1234567890-0",
    "higher-id": "1234567899-0",
    "consumers": [
      {
        "name": "worker-1",
        "count": 3
      },
      {
        "name": "worker-2",
        "count": 2
      }
    ]
  }
}
```

**Response (Chi tiết):**
```json
{
  "key": "orders",
  "group": "order-processors",
  "pending": [
    {
      "id": "1234567890-0",
      "consumer": "worker-1",
      "elapsed-time": 5000,
      "delivery-count": 1
    }
  ]
}
```

#### 3.2. Claim Pending Messages

**Endpoint:** `POST /redis/stream/:key/group/:group/claim`

**Body:**
```json
{
  "consumer": "worker-2",
  "minIdleTime": 1000,
  "ids": ["1234567890-0", "1234567891-0"]
}
```

**Parameters:**
- `consumer`: Consumer mới sẽ claim messages
- `minIdleTime`: Thời gian idle tối thiểu (milliseconds)
- `ids`: Danh sách message IDs cần claim

**Response:**
```json
{
  "key": "orders",
  "group": "order-processors",
  "consumer": "worker-2",
  "claimed": 2,
  "messages": [...]
}
```

**Mô tả:** Claim các messages đã bị timeout từ consumer khác.

#### 3.3. Acknowledge Messages

**Endpoint:** `POST /redis/stream/:key/group/:group/ack`

**Body:**
```json
{
  "ids": ["1234567890-0", "1234567891-0"]
}
```

**Response:**
```json
{
  "key": "orders",
  "group": "order-processors",
  "acked": 2,
  "messageIds": ["1234567890-0", "1234567891-0"]
}
```

**Mô tả:** Xác nhận đã xử lý xong messages.

### 4. Stream Management

#### 4.1. Trim Stream

**Endpoint:** `POST /redis/stream/:key/trim`

**Body:**
```json
{
  "strategy": "MAXLEN",
  "threshold": 50,
  "approx": false
}
```

**Parameters:**
- `strategy`: `MAXLEN` hoặc `MINID`
- `threshold`: Giá trị threshold (number cho MAXLEN, string ID cho MINID)
- `approx`: Sử dụng approximate trimming (nhanh hơn)

**Response:**
```json
{
  "key": "logs",
  "strategy": "MAXLEN",
  "threshold": 50,
  "trimmed": 25
}
```

**Mô tả:** Trim stream để quản lý memory. `MAXLEN` giữ N messages mới nhất, `MINID` giữ messages từ ID trở đi.

#### 4.2. Delete Messages

**Endpoint:** `POST /redis/stream/:key/delete`

**Body:**
```json
{
  "ids": ["1234567890-0", "1234567891-0"]
}
```

**Response:**
```json
{
  "key": "user-events",
  "deleted": 2,
  "messageIds": ["1234567890-0", "1234567891-0"]
}
```

## Các Use Cases

### 1. Event Streaming

Sử dụng Redis Streams để lưu trữ và xử lý events:

```typescript
// Thêm event
await redisClient.xAdd('user-events', {
  action: 'login',
  userId: '12345',
  timestamp: Date.now()
});

// Đọc events
const events = await redisClient.xRange('user-events', '-', '+', 100);
```

### 2. Message Queue với Consumer Groups

Xử lý messages với nhiều workers:

```typescript
// Tạo consumer group
await redisClient.xGroupCreateIfNotExists('orders', 'order-processors', '$', true);

// Worker đọc messages
const messages = await redisClient.xReadGroup(
  'order-processors',
  'worker-1',
  [{ key: 'orders', id: '>' }],
  { count: 10, block: 5000 }
);

// Xử lý messages
for (const message of messages[0].messages) {
  // Process message
  await processOrder(message.fields);
  
  // Acknowledge
  await redisClient.xAck('orders', 'order-processors', [message.id]);
}
```

### 3. Real-time Monitoring

Monitoring real-time với blocking reads:

```typescript
// Thêm metrics
await redisClient.xAdd('system-metrics', {
  cpu: 75.5,
  memory: 60.2,
  timestamp: Date.now()
});

// Đọc real-time
const metrics = await redisClient.xRead(
  [{ key: 'system-metrics', id: '$' }],
  { block: 5000, count: 10 }
);
```

### 4. Error Handling với Message Claiming

Xử lý messages bị timeout:

```typescript
// Kiểm tra pending messages
const pending = await redisClient.xPending('orders', 'order-processors');

if (pending.count > 0) {
  // Lấy chi tiết pending messages
  const pendingDetails = await redisClient.xPending(
    'orders',
    'order-processors',
    '0',
    '9999999999999',
    100
  );
  
  // Claim messages đã timeout (idle > 60000ms)
  const messageIds = pendingDetails
    .filter(msg => msg['elapsed-time'] > 60000)
    .map(msg => msg.id);
  
  if (messageIds.length > 0) {
    const claimed = await redisClient.xClaim(
      'orders',
      'order-processors',
      'worker-backup',
      60000,
      messageIds
    );
    
    // Xử lý lại claimed messages
    for (const msg of claimed) {
      await processOrder(msg.fields);
      await redisClient.xAck('orders', 'order-processors', [msg.id]);
    }
  }
}
```

### 5. Stream Trimming để Quản lý Memory

Giữ stream size trong giới hạn:

```typescript
// Trim stream, giữ 1000 messages mới nhất
await redisClient.xTrim('logs', 'MAXLEN', 1000);

// Approximate trim (nhanh hơn)
await redisClient.xTrim('logs', 'MAXLEN', 1000, true);
```

## Best Practices

### 1. Message ID

- Sử dụng `*` để tự động generate ID khi thêm message
- Redis tự động tạo ID theo format: `<milliseconds-time>-<sequence-number>`
- ID tăng dần, có thể so sánh

### 2. Consumer Groups

- Luôn tạo consumer group trước khi sử dụng
- Sử dụng `xGroupCreateIfNotExists` để tránh lỗi
- Đặt `mkStream: true` nếu muốn tự động tạo stream

### 3. Message Acknowledgment

- Luôn acknowledge messages sau khi xử lý xong
- Sử dụng try-catch để đảm bảo acknowledge ngay cả khi có lỗi
- Không sử dụng `noack: true` trừ khi thực sự cần

### 4. Error Handling

- Kiểm tra pending messages định kỳ
- Sử dụng message claiming cho messages bị timeout
- Đặt threshold hợp lý cho minIdleTime

### 5. Stream Trimming

- Trim streams định kỳ để quản lý memory
- Sử dụng approximate trimming (`approx: true`) để tăng performance
- Xem xét sử dụng `MAXLEN` cho logs, `MINID` cho events cần retention policy

### 6. Blocking Reads

- Sử dụng blocking reads cho real-time processing
- Đặt timeout hợp lý (5-10 giây thường đủ)
- Sử dụng `$` ID để chỉ đọc messages mới

### 7. Consumer Naming

- Sử dụng tên consumer có ý nghĩa (ví dụ: `worker-1`, `worker-2`)
- Tránh sử dụng random IDs trừ khi thực sự cần
- Monitor consumers thông qua xPending

### 8. Performance

- Batch operations khi có thể (xAdd nhiều messages, xAck nhiều IDs)
- Sử dụng approximate trimming cho large streams
- Monitor stream length và trim khi cần

## Ví dụ sử dụng

### Ví dụ 1: Order Processing System

```typescript
// 1. Setup consumer group
await redisClient.xGroupCreateIfNotExists(
  'orders',
  'order-processors',
  '$',
  true
);

// 2. Producer: Thêm orders
await redisClient.xAdd('orders', {
  orderId: 'order-001',
  customerId: 'cust-123',
  amount: 99.99,
  items: JSON.stringify([{ id: 'item-1', quantity: 2 }])
});

// 3. Consumer: Đọc và xử lý
const messages = await redisClient.xReadGroup(
  'order-processors',
  'worker-1',
  [{ key: 'orders', id: '>' }],
  { count: 10, block: 5000 }
);

for (const stream of messages) {
  for (const msg of stream.messages) {
    try {
      await processOrder(msg.fields);
      await redisClient.xAck('orders', 'order-processors', [msg.id]);
    } catch (error) {
      // Log error, message sẽ được claim sau
      console.error('Error processing order:', error);
    }
  }
}

// 4. Error recovery: Claim timeout messages
const pending = await redisClient.xPending(
  'orders',
  'order-processors',
  '0',
  '9999999999999',
  100
);

const timeoutMessages = pending
  .filter(msg => msg['elapsed-time'] > 60000)
  .map(msg => msg.id);

if (timeoutMessages.length > 0) {
  const claimed = await redisClient.xClaim(
    'orders',
    'order-processors',
    'worker-backup',
    60000,
    timeoutMessages
  );
  
  // Xử lý lại
  for (const msg of claimed) {
    await processOrder(msg.fields);
    await redisClient.xAck('orders', 'order-processors', [msg.id]);
  }
}
```

### Ví dụ 2: Event Logging

```typescript
// Thêm events
await redisClient.xAdd('application-logs', {
  level: 'INFO',
  service: 'auth-service',
  message: 'User logged in',
  userId: '12345',
  timestamp: new Date().toISOString()
});

// Đọc logs (latest 100)
const logs = await redisClient.xRevRange('application-logs', '+', '-', 100);

// Trim logs (giữ 10000 entries)
await redisClient.xTrim('application-logs', 'MAXLEN', 10000, true);
```

### Ví dụ 3: Real-time Metrics

```typescript
// Producer: Gửi metrics
setInterval(async () => {
  await redisClient.xAdd('system-metrics', {
    cpu: getCpuUsage(),
    memory: getMemoryUsage(),
    disk: getDiskUsage(),
    timestamp: Date.now()
  });
}, 5000);

// Consumer: Đọc real-time
while (true) {
  const metrics = await redisClient.xRead(
    [{ key: 'system-metrics', id: '$' }],
    { block: 5000, count: 10 }
  );
  
  for (const stream of metrics) {
    for (const msg of stream.messages) {
      await processMetrics(msg.fields);
    }
  }
}
```

## Lưu ý

1. **Memory Management**: Streams có thể tốn nhiều memory nếu không trim định kỳ
2. **Message Ordering**: Messages được đảm bảo theo thứ tự ID
3. **Consumer Groups**: Mỗi message chỉ được deliver đến một consumer trong group
4. **Acknowledgment**: Messages chưa được ack sẽ nằm trong pending list
5. **Performance**: Blocking reads hiệu quả hơn polling
6. **Error Recovery**: Sử dụng message claiming cho error recovery

## Tài liệu tham khảo

- [Redis Streams Documentation](https://redis.io/docs/data-types/streams/)
- [Redis Streams Tutorial](https://redis.io/docs/data-types/streams-tutorial/)
- Code examples: `libs/src/core/redis/examples/redis-stream-example.ts`