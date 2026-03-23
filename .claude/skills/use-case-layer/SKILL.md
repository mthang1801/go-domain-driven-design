---
name: use-case-layer
description: Use-case layer conventions for NestJS DDD. Use when creating or modifying use-cases in application layer. All use-cases must extend BaseCommand or BaseQuery.
---

# Use-Case Layer

## Quy tắc bắt buộc

Mọi use-case phải extend một trong hai base class:

| Base class | Khi dùng | Method implement | Gọi từ controller |
|------------|----------|------------------|-------------------|
| **BaseQuery** | Get list, get detail (read-only) | `query(request)` | `queryWithHooks(request)` |
| **BaseCommand** | Create, Update, Delete, Approve, Cancel, Pay, Ship... (write) | `execute(request)` | `executeWithHooks(request)` |

## BaseQuery – Read use-cases

```typescript
import { BaseQuery } from '@ddd/application';

@Injectable()
export class GetAgreementListUseCase extends BaseQuery<AgreementListRequest, AgreementListResult> {
    constructor(private readonly getAgreementListService: GetAgreementListService) {
        super();
    }

    async query(request: AgreementListRequest): Promise<AgreementListResult> {
        return this.getAgreementListService.execute(request.filters ?? {}, request.pagination ?? {});
    }
}
```

Controller: `this.getAgreementListUseCase.queryWithHooks({ filters, pagination })`

## BaseCommand – Write use-cases

```typescript
import { BaseCommand } from '@ddd/application';

@Injectable()
export class CancelOrderUseCase extends BaseCommand<CancelOrderRequest, void> {
    constructor(
        @Inject(IOrderRepository) private readonly orderRepository: IOrderRepository,
    ) {
        super();
    }

    async execute(request: CancelOrderRequest): Promise<void> {
        const order = await this.orderRepository.findById(request.orderId);
        // ...
        await this.orderRepository.save(order);
    }
}
```

Controller: `this.cancelOrderUseCase.executeWithHooks({ orderId, reason })`

## Hooks (tùy chọn)

- **BaseQuery**: `beforeQuery`, `validate`, `afterValidate`, `afterQuery`, `onError`
- **BaseCommand**: `beforeExecute`, `validate`, `afterValidate`, `afterExecute`, `onError`
