# Saga Pattern Example (DDD + Kafka)

Example này mô tả end-to-end cách triển khai Saga pattern theo core ở `libs/src/ddd/saga`.

## 1) Orchestrator (`SagaDefinition` + `SagaStep`)

```typescript
@Injectable()
export class OrderPlacementSaga extends SagaDefinition<OrderPlacementSagaData> {
    readonly sagaType = 'OrderPlacementSaga';

    constructor(@Inject(IOrderRepository) private readonly orderRepository: IOrderRepository) {
        super();
    }

    steps() {
        return [
            SagaStep.create<OrderPlacementSagaData>('TrackOrder')
                .withLocalInvoke(async (data) => data)
                .compensate(async (data) => {
                    await this.orderRepository.delete(data.orderId);
                    return { command: null, isLocal: true };
                })
                .build(),
            SagaStep.create<OrderPlacementSagaData>('DecreaseInventory')
                .invoke(async (data) => ({
                    destination: 'inventory-service',
                    commandType: 'DecreaseInventoryCommand',
                    payload: {
                        orderId: data.orderId,
                        scenario: data.testScenario,
                    },
                }))
                .compensate(async (data) => ({
                    destination: 'inventory-service',
                    commandType: 'IncreaseInventoryCommand',
                    payload: { orderId: data.orderId },
                }))
                .build(),
            SagaStep.create<OrderPlacementSagaData>('FinalizeOrder')
                .withLocalInvoke(async (data) => data)
                .build(),
        ];
    }
}
```

## 2) Start Saga từ Use Case

```typescript
const saga = await this.sagaManager.create<OrderPlacementSagaData>({
    sagaType: 'OrderPlacementSaga',
    idempotencyId: request.clientRef,
    initialData: {
        orderId: order.id.toValue(),
        customerId: request.customerId,
        clientRef: request.clientRef,
        testScenario: request.testScenario,
    },
});
```

## 3) Participant consumer (echo headers)

```typescript
@Controller()
export class OrderPlacementSagaParticipantConsumer {
    @SubscribeEventPattern('inventory-service')
    async handleInventoryCommand(@Payload() value: unknown, @Ctx() context: KafkaContext): Promise<void> {
        const envelope = this.parse(value);
        const headers = this.extractHeaders(context);

        const outcome = envelope.payload?.scenario === 'CASE_3' ? 'FAILURE' : 'SUCCESS';

        await this.kafkaService.publish({
            topic: headers.command_reply_reply_to,
            key: headers.command_reply_saga_id,
            headers: {
                ...headers, // MUST echo command_reply_* headers
                reply_outcome: outcome,
                reply_type: outcome === 'SUCCESS' ? 'InventoryDeducted' : 'InventoryDeductionFailed',
            },
            message: {
                data: { orderId: envelope.payload?.orderId },
            },
        });
    }
}
```

## 4) Reply consumer

```typescript
@Controller()
export class OrderPlacementSagaReplyConsumer extends KafkaSagaReplyConsumerBase {
    @SubscribeEventPattern('OrderPlacementSaga-reply')
    async handleReply(@Payload() value: unknown, @Ctx() context: KafkaContext): Promise<void> {
        await this.processKafkaMessage(value, context);
    }
}
```

## 5) Test scenarios

- `CASE_1`: Order success + inventory success => saga `COMPLETED`
- `CASE_2`: Inventory success, customer-point fail => saga `COMPENSATED`
- `CASE_3`: Inventory fail => saga `COMPENSATED` (customer step không chạy)

## 6) Request mẫu

```json
{
    "clientRef": "ORDER-REF-001",
    "customerId": "cus_001",
    "testScenario": "CASE_1",
    "items": [
        { "productId": "prd_001", "quantity": 2 }
    ]
}
```

## 7) Rules bắt buộc

- Phải dùng `SagaDefinition`, `SagaStep`, `SagaManager` từ `libs/src/ddd/saga`
- Participant phải echo lại đầy đủ `command_reply_*` headers
- Không hardcode env key trong libs; mapping key đặt ở `src/infrastructure/**`
