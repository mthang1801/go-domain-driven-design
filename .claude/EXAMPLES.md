# Real-World Examples (DDD + Clean Architecture)

Tài liệu này lấy ví dụ từ code thực tế trong monorepo: **domain-driven-design** (domain, application, presentation) và **data-visualizer** (infrastructure). Infrastructure layer áp dụng flow mới: dùng `src/infrastructure/persistence` thay cho `infrastructure/database`.

---

## 1. Cấu trúc Infrastructure (flow mới – theo data-visualizer)

Infrastructure **không** dùng folder `infrastructure/database`. Persistence gom trong `persistence/typeorm`, các adapter khác đặt cùng cấp.

```text
src/infrastructure/
├── persistence/
│   └── typeorm/
│       └── typeorm.module.ts    # LibTypeOrmModule + đăng ký repositories
├── redis/
│   ├── index.ts
│   └── redis.module.ts
├── telegram/
│   └── telegram.module.ts
└── {module}/                     # Theo từng bounded context
    ├── entities/                 # ORM entities (*.orm.entity.ts)
    ├── repositories/            # Repository implementations
    ├── services/                # Infra services (e.g. get-filtered-list)
    ├── events/handlers/        # Domain event handlers
    └── config/                  # YAML/config cho filter, report...
```

**TypeORM module (flow mới):** import `LibTypeOrmModule` từ `@core/database`, cấu hình trong `persistence/typeorm/typeorm.module.ts`, đăng ký repository providers tại đây (không tách riêng `infrastructure/database`).

---

## 2. Example 1: Agreement Feature

### 2.1 Domain Layer

**Entity (Aggregate Root)** – `domain/agreement/entities/agreement.entity.ts`

```typescript
import { BaseAggregateRoot, Result } from '@ddd/domain';
import { IUniqueEntityID } from '@ddd/interfaces';
import { AgreementCreatedEvent } from '../events';
import { AgreementApprovedEvent } from '../events/agreement-approved.event';
import { AgreementMoneyVO, AgreementNumberValueObject } from '../value-objects';

export enum ENUM_AGGREMENT_STATUS {
    DRAFT = 'DRAFT',
    PENDING_APPROVAL = 'PENDING_APPROVAL',
    APPROVED = 'APPROVED',
    REJECTED = 'REJECTED',
    CANCELLED = 'CANCELLED',
}

export interface AgreementProps {
    agreementNumber: AgreementNumberValueObject;
    amount: AgreementMoneyVO;
    customerId?: string;
    startDate: Date;
    endDate: Date;
    status: string;
    createdAt: Date;
    updatedAt: Date;
    createdBy?: string;
    updatedBy?: string;
    approvedBy?: string;
    approvedAt?: Date;
}

export class Agreement extends BaseAggregateRoot<AgreementProps> {
    constructor(props: AgreementProps, id?: IUniqueEntityID) {
        super(props, id);
    }

    get agreementNumber(): AgreementNumberValueObject {
        return this.props.agreementNumber;
    }
    get amount(): AgreementMoneyVO {
        return this.props.amount;
    }
    get status(): string {
        return this.props.status;
    }
    get startDate(): Date {
        return this.props.startDate;
    }
    get endDate(): Date {
        return this.props.endDate;
    }
    get approvedBy(): string | undefined {
        return this.props.approvedBy;
    }
    get approvedAt(): Date | undefined {
        return this.props.approvedAt;
    }
    // ... other getters

    public approve(approvedBy: string): Result<void> {
        if (this.status !== ENUM_AGGREMENT_STATUS.PENDING_APPROVAL) {
            return Result.fail<void>(`Agreement is not pending approval`);
        }
        this.props.status = ENUM_AGGREMENT_STATUS.APPROVED;
        this.props.approvedBy = approvedBy;
        this.props.approvedAt = new Date();
        this.addDomainEvent(AgreementApprovedEvent.create(this.id, approvedBy));
        return Result.ok<void>();
    }

    public static create(props: AgreementProps, id?: IUniqueEntityID): Result<Agreement> {
        const agreement = new Agreement(
            {
                ...props,
                status: props.status || ENUM_AGGREMENT_STATUS.DRAFT,
                createdAt: new Date(),
                updatedAt: new Date(),
            },
            id,
        );
        if (!id) {
            agreement.addDomainEvent(
                AgreementCreatedEvent.create(agreement.id, {
                    aggrementNumber: agreement.agreementNumber.getValue(),
                    amount: agreement.amount.amount,
                    currency: agreement.amount.currency,
                    status: agreement.status,
                    startDate: agreement.startDate,
                    endDate: agreement.endDate,
                }),
            );
        }
        return Result.ok<Agreement>(agreement);
    }
}
```

**Value Object** – `domain/agreement/value-objects/agreement-number.vo.ts`

```typescript
import { BaseValueObject, Guard, Result } from '@ddd/domain';

interface AgreementNumberProps {
    value: string;
}

export class AgreementNumberValueObject extends BaseValueObject<AgreementNumberProps> {
    private constructor(props: AgreementNumberProps) {
        super(props);
    }

    get value() {
        return this.props.value;
    }

    public static create(agreementNumber: string): Result<AgreementNumberValueObject> {
        const guardResult = Guard.againstNullOrUndefined(agreementNumber, 'agreementNumber');
        if (guardResult.isFailure)
            return Result.fail<AgreementNumberValueObject>(guardResult.errors);
        const lengthResult = Guard.againstAtMinLength(5, agreementNumber, 'agreementNumber');
        if (lengthResult.isFailure)
            return Result.fail<AgreementNumberValueObject>(lengthResult.errors);
        return Result.ok(new AgreementNumberValueObject({ value: agreementNumber }));
    }
}
```

**Repository Port** – `domain/agreement/repositories/agreement.repository.ts`

```typescript
import { IRepositoryTypeORMBase } from '@ddd/interfaces';
import { AgreementOrm } from '@infrastructure/agreement/entities';
import { Agreement } from '../entities';

export interface IAgreementRepository extends IRepositoryTypeORMBase<Agreement, AgreementOrm> {
    findByAgreementNumber(agreementNumber: string): Promise<Agreement | null>;
    findByCustomerId(customerId: string): Promise<Agreement[]>;
    findByStatus(status: string): Promise<Agreement[]>;
    findById(id: string): Promise<Agreement | null>;
}

export const IAgreementRepository = Symbol('IAgreementRepository');
```

### 2.2 Application Layer

**Command – Create** – `application/agreement/use-cases/create-agreement.use-case.ts`

```typescript
import { UsecaseBadRequestException } from '@common/exceptions';
import { BaseCommand } from '@ddd/application';
import { Agreement } from '@domain/agreement/entities';
import { IAgreementRepository } from '@domain/agreement/repositories';
import { AgreementMoneyVO, AgreementNumberValueObject } from '@domain/agreement/value-objects';
import { Inject } from '@nestjs/common';
import { formatLogMessageWithIcon } from '@shared/utils';

interface CreateAgreementRequest {
    agreementNumber: string;
    amount: number;
    currency: string;
    startDate: Date;
    endDate: Date;
    status: string;
}

export class CreateAgreementUseCase extends BaseCommand<CreateAgreementRequest, void> {
    constructor(
        @Inject(IAgreementRepository) private readonly agreementRepository: IAgreementRepository,
    ) {
        super();
    }

    async execute(request: CreateAgreementRequest): Promise<void> {
        const agreementNumberResult = AgreementNumberValueObject.create(request.agreementNumber);
        if (agreementNumberResult.isFailure) {
            throw new UsecaseBadRequestException(agreementNumberResult.errors);
        }
        const moneyResult = AgreementMoneyVO.create(request.amount, request.currency);
        if (moneyResult.isFailure) {
            throw new UsecaseBadRequestException(moneyResult.errors);
        }
        const agreementResult = Agreement.create({
            agreementNumber: agreementNumberResult.getValue(),
            amount: moneyResult.getValue(),
            startDate: request.startDate,
            endDate: request.endDate,
            status: request.status,
            createdAt: new Date(),
            updatedAt: new Date(),
        });
        if (agreementResult.isFailure) {
            throw new UsecaseBadRequestException(agreementResult.errors);
        }
        await this.agreementRepository.save(agreementResult.getValue());
    }

    protected async afterExecute(request: CreateAgreementRequest, response: void): Promise<void> {
        this.logger.log(formatLogMessageWithIcon('END', `Agreement created successfully`));
    }
}
```

**Command – Approve** – `application/agreement/use-cases/approve-agreement.use-case.ts`

```typescript
@Injectable()
export class ApproveAgreementUseCase extends BaseCommand<ApproveAgreementRequest, void> {
    constructor(
        @Inject(IAgreementRepository) private readonly agreementRepository: IAgreementRepository,
    ) {
        super();
    }

    async execute(request: ApproveAgreementRequest): Promise<void> {
        const agreement = await this.agreementRepository.findById(request.agreementId);
        if (!agreement) {
            throw new UsecaseBadRequestException([
                { validation: 'NOT_EXISTS', args: { property: 'agreement' } },
            ]);
        }
        const approveResult = agreement.approve(request.approvedBy);
        if (approveResult.isFailure) {
            throw new UsecaseBadRequestException(approveResult.errors);
        }
        await this.agreementRepository.save(agreement);
    }
}
```

**Query – List (filtered)** – `application/agreement/use-cases/get-agreement-list.use-case.ts`

```typescript
import { BaseQuery } from '@ddd/application';
import type {
    AgreementListFilters,
    AgreementListPagination,
    AgreementListResult,
} from '@infrastructure/agreement/services/get-agreement-list.service';
import { GetAgreementListService } from '@infrastructure/agreement/services/get-agreement-list.service';
import { Injectable } from '@nestjs/common';

export interface AgreementListRequest {
    filters?: AgreementListFilters;
    pagination?: AgreementListPagination;
}

@Injectable()
export class GetAgreementListUseCase extends BaseQuery<AgreementListRequest, AgreementListResult> {
    constructor(private readonly getAgreementListService: GetAgreementListService) {
        super();
    }

    async query(request: AgreementListRequest): Promise<AgreementListResult> {
        const filters = request.filters ?? {};
        const pagination = request.pagination ?? {};
        return this.getAgreementListService.execute(filters, pagination);
    }
}
```

### 2.3 Infrastructure Layer (flow mới: persistence + module agreement)

**Persistence module** – `infrastructure/persistence/typeorm/typeorm.module.ts`

```typescript
import { LibTypeOrmModule } from '@core/database';
import { IAgreementRepository } from '@domain/agreement/repositories';
import { AgreementRepository } from '@infrastructure/agreement/repositories/agreement.repository';
import { Global, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { resolve } from 'path';
import { typeOrmModuleOptions } from './typeorm.options';

const repositoryProviders = [{ provide: IAgreementRepository, useClass: AgreementRepository }];

@Global()
@Module({
    imports: [
        LibTypeOrmModule.forRootAsync({
            inject: [ConfigService],
            useFactory: async (configService: ConfigService) => typeOrmModuleOptions(configService),
            sqlScripts: {
                enabled: true,
                paths: [resolve(process.cwd(), 'database/sql')],
                continueOnError: true,
                retryFailedFunctions: true,
            },
        }),
    ],
    providers: repositoryProviders,
    exports: repositoryProviders,
})
export class TypeOrmInfrastructureModule {}
```

**Repository** – `infrastructure/order/repositories/order.repository.ts`

```typescript
import { BaseRepositoryTypeORM } from '@ddd/infrastructure';
import { ENUM_ORDER_STATUS, Order } from '@domain/order/entities';
import { IOrderRepository } from '@domain/order/repositories';
import { OrderMapper } from '@modules-shared/mappers';
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { OrderOrm } from '../entities';

@Injectable()
export class OrderRepository
    extends BaseRepositoryTypeORM<Order, OrderOrm>
    implements IOrderRepository
{
    constructor(dataSource: DataSource) {
        super(OrderOrm, dataSource, OrderMapper.create());
    }

    async findById(id: string): Promise<Order | null> {
        const orm = await this.repository.findOne({
            where: { id },
            relations: ['items'],
        });
        if (!orm) {
            return null;
        }
        return this.mapper.toDomain(orm);
    }

    async findByCode(code: string): Promise<Order | null> {
        const orm = await this.repository.findOne({
            where: { code },
            relations: ['items'],
        });
        if (!orm) {
            return null;
        }
        return this.mapper.toDomain(orm);
    }

    async findByCustomerId(customerId: string): Promise<Order[]> {
        const orms = await this.repository.find({
            where: { customerId },
            relations: ['items'],
            order: { createdAt: 'DESC' },
        });
        return orms.map((orm) => this.mapper.toDomain(orm));
    }

    async findByStatus(status: ENUM_ORDER_STATUS): Promise<Order[]> {
        const orms = await this.repository.find({
            where: { status },
            relations: ['items'],
            order: { createdAt: 'DESC' },
        });
        return orms.map((orm) => this.mapper.toDomain(orm));
    }

    async findByCustomerIdAndStatus(
        customerId: string,
        status: ENUM_ORDER_STATUS,
    ): Promise<Order[]> {
        const orms = await this.repository.find({
            where: { customerId, status },
            relations: ['items'],
            order: { createdAt: 'DESC' },
        });
        return orms.map((orm) => this.mapper.toDomain(orm));
    }

    override async save(order: Order): Promise<Order> {
        const result = await super.saveOne(order);
        await this.dispatchDomainEventsForAggregates(result);
        return result;
    }

    async delete(id: string): Promise<void> {
        await this.repository.delete({ id });
    }
}
```

**Factory** – `domain/order/factories/order.factories.ts`

```typescript
import { LogExecution } from '@common/decorators';
import { Result } from '@ddd/domain';
import { IBaseDomainEvent } from '@ddd/interfaces';
import { ICustomerRepository } from '@domain/customer/repositories';
import { IProductRepository } from '@domain/product';
import { Inject, Injectable, Logger } from '@nestjs/common';
import { Order, OrderItem } from '../entities';
import { IDiscountPolicy, TieredDiscountPolicy } from '../policies';
import { InventoryDomainService, PricingDomainService } from '../services';
import { AddressVO, MoneyVO, OrderCodeVO } from '../value-objects';

@Injectable()
@LogExecution()
export class OrderFactory {
    private readonly logger = new Logger(this.constructor.name);

    constructor(        
        private readonly inventoryService: InventoryDomainService,
        private readonly pricingService: PricingDomainService,        
    ) {}
    /**
     * Create order from cart
     */
    public async createFromCart(
        customerId: string,
        cartItems: Array<{
            productId: string;
            quantity: number;
            product
        }>,
        shippingAddress: AddressVO,
        billingAddress: AddressVO,
    ): Promise<Result<Order>> {
        //TODO: 1. Validate customer exists

        const customer = await this.customerRepository.findById(customerId);
        if (!customer) {
            return Result.fail('Customer not found');
        }

        //TODO: 2. Load product and create order item
        const orderItems: OrderItem[] = [];

        const cartItemsResult = cartItems.map((cartItem) => {
            const product = cartItem.product;
            if (!product) {
                return Result.fail(`Product ${cartItem.productId} not found`);
            }

            const unitPrice = MoneyVO.create(product.price.amount, product.price.currency).getValue();
            const discount = MoneyVO.zero(product.price.currency).getValue();
            const orderItemResult = OrderItem.create({
                productId: product.id.toValue(),
                productName: product.name.getValue(),
                quantity: cartItem.quantity,
                unitPrice,
                discountAmount: discount,
                weight: product.weight,
            });
            if (orderItemResult.isFailure) {
                return Result.fail(orderItemResult.errors);
            }

            orderItems.push(orderItemResult.getValue());
        });

        //TODO: 3. Check inventory availability
        // const availabilityResult = await this.inventoryService.checkAvailability(orderItems);
        // if (availabilityResult.isFailure) {
        //     return Result.fail(availabilityResult.errors);
        // }

        //TODO 4. Calculate subtotal
        const subtotal = orderItems.reduce(
            (sum, item) => sum.add(item.getSubtotal).getValue(),
            MoneyVO.zero().getValue(),
        );

        //TODO 5. Get warehouse address (for shipping calculation)
        const  warehouseAddress = this.getWarehouseAddress();

        //TODO 6. Calculate Shipping fee
        const shippingFee = this.pricingService.calculateShippingFee(orderItems, warehouseAddress, shippingAddress);

        //TODO: 7. Calculate taxrate
        const taxRate = this.getTaxRate();
        const tempOrder = { subtotal, shippingAddress } as Order;
        const tax = this.pricingService.calculateTax(tempOrder, taxRate);

        //TODO: 8. Apply discount (if eligible)
        const tempOrderForDiscount = {
            totalAmount: subtotal.add(tax).getValue().add(shippingFee).getValue(),
        } as Order;
        const discount = this.discountPolicy.calculateDiscount(tempOrderForDiscount, customer);

        //TODO: 9. Calculate total
        const totalAmount = subtotal.subtract(discount).getValue().add(tax).getValue().add(shippingFee).getValue();

        const orderCode = OrderCodeVO.generate();

        const orderResult = Order.create({
            code: orderCode,
            customerId,
            items: orderItems,
            shippingAddress,
            billingAddress,
            subtotal,
            discount,
            tax,
            shippingFee,
            totalAmount,
        });
        if (orderResult.isFailure) {
            return Result.fail(orderResult.errors);
        }
        return Result.ok(orderResult.getValue());
    }

    private async getWarehouseAddress(): Promise<AddressVO> {
        // In real app, get from configuration or database
        return AddressVO.create({
            addressLine: '123 Quang Trung St',
            province: 'Ho Chi Minh',
            district: 'Go Vap',
            ward: '10',
        }).getValue();
    }

    private getTaxRate(): number {
        return 10;
    }

    /**
     * Reconstitute order from event store (for Event Sourcing)
     */
    async fromEventStream(orderId: string, events: IBaseDomainEvent[]): Promise<Result<Order>> {
        // Event Sourcing: rebuild order state from events
        let orderState: any = {};

        for (const event of events) {
            orderState = this.applyEvent(orderState, event);
        }

        // Reconstruct order from final state
        // ... implementation details

        return Result.ok(/* reconstructed order */);
    }

    private applyEvent(state: any, event: IBaseDomainEvent): any {
        // Apply event to state
        // ... implementation details
        return state;
    }
}
```


**Mapper** – `shared/mappers/agreement.mapper.ts` (Domain ↔ ORM)

```typescript
import { UniqueEntityID } from '@ddd/domain';
import { BaseMapper } from '@ddd/infrastructure';
import { Agreement } from '@domain/agreement/entities';
import { AgreementMoneyVO, AgreementNumberValueObject } from '@domain/agreement/value-objects';
import { AgreementOrm } from '@infrastructure/agreement/entities/agreement.orm.entity';

export class AgreementMapper extends BaseMapper<Agreement, AgreementOrm> {
    toDomain(orm: AgreementOrm): Agreement {
        const agreementNumberResult = AgreementNumberValueObject.create(orm.agreementNumber);
        if (agreementNumberResult.isFailure) throw new Error(agreementNumberResult.errorMessage);
        const moneyResult = AgreementMoneyVO.create(orm.amount, orm.currency);
        if (moneyResult.isFailure) throw new Error(moneyResult.errorMessage);
        const agreementResult = Agreement.create(
            {
                agreementNumber: agreementNumberResult.getValue(),
                amount: moneyResult.getValue(),
                customerId: orm.customerId,
                startDate: orm.startDate,
                endDate: orm.endDate,
                status: orm.status,
                createdAt: orm.createdAt,
                updatedAt: orm.updatedAt,
            },
            new UniqueEntityID(orm.id.toString()),
        );
        if (agreementResult.isFailure) throw new Error(agreementResult.errorMessage);
        return agreementResult.getValue();
    }

    toOrm(domain: Agreement): AgreementOrm {
        return AgreementOrm.fromInput({
            id: domain.id.toValue(),
            agreementNumber: domain.agreementNumber.getValue(),
            customerId: domain.customerId,
            startDate: domain.startDate,
            endDate: domain.endDate,
            amount: domain.amount.amount,
            currency: domain.amount.currency,
            status: domain.status,
            createdBy: domain.createdBy,
            updatedBy: domain.updatedBy,
            approvedBy: domain.approvedBy,
            approvedAt: domain.approvedAt,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt,
        }) as AgreementOrm;
    }
}
```

**ORM Entity** – `infrastructure/agreement/entities/agreement.orm.entity.ts`

```typescript
import { BaseUUIDEntity } from '@core/database';
import { Column, Entity } from 'typeorm';

@Entity('agreements')
export class AgreementOrm extends BaseUUIDEntity {
    @Column()
    agreementNumber: string;

    @Column({ nullable: true })
    amount: number;

    @Column({ nullable: true })
    currency: string;

    @Column({ nullable: true })
    customerId: string;

    @Column({ nullable: true })
    startDate: Date;

    @Column({ nullable: true })
    endDate: Date;

    @Column({ nullable: true })
    status: string;

    @Column({ nullable: true })
    createdBy: string;

    @Column({ nullable: true })
    updatedBy: string;

    @Column({ nullable: true })
    approvedBy: string;

    @Column({ nullable: true })
    approvedAt: Date;
}
```

### 2.4 Presentation Layer

**Controller** – `presentation/portal/agreement/agreement.controller.ts`

```typescript
@Controller()
@SwaggerApiTags('Agreement')
export class AgreementController {
    constructor(
        private readonly createAgreementUseCase: CreateAgreementUseCase,
        private readonly approveAgreementUseCase: ApproveAgreementUseCase,
        private readonly getAgreementListUseCase: GetAgreementListUseCase,
    ) {}

    @Get()
    @SwaggerApiListResponse({
        summary: 'Get agreement list with filters and pagination',
        responseType: Agreement,
    })
    public async list(@Query() dto: ListAgreementDto) {
        const safeDto = dto ?? {};
        const { page, limit, ...filters } = safeDto;
        return this.getAgreementListUseCase.queryWithHooks({
            filters: filters ?? {},
            pagination: { page, limit },
        });
    }

    @Post()
    @SwaggerApiCreatedResponse({ summary: 'Create agreement', body: CreateAgreementDto })
    public async create(@Body() dto: CreateAgreementDto) {
        return await this.createAgreementUseCase.executeWithHooks({
            agreementNumber: dto.agreementNumber,
            amount: dto.amount,
            currency: dto.currency,
            startDate: dto.startDate,
            endDate: dto.endDate,
            status: dto.status,
        });
    }

    @Patch(':id/approve')
    @SwaggerApiResponse({ summary: 'Approve agreement', body: ApproveAgreementDto })
    public async approve(@Param('id') id: string, @Body() dto: ApproveAgreementDto) {
        return await this.approveAgreementUseCase.executeWithHooks({
            agreementId: id,
            approvedBy: dto.approvedBy,
        });
    }
}
```

**DTOs** – `presentation/portal/agreement/dto/`

- `CreateAgreementDto`: agreementNumber, amount, currency, startDate, endDate, status (optional).
- `ListAgreementDto`: filters (status, agreementNumber, customerId, keyword, startDateFrom/To, endDateFrom/To, createdFrom/To, updatedFrom/To), pagination (page, limit).
- `ApproveAgreementDto`: approvedBy.

---

## 3. Example 2: Order Feature

### 3.1 Domain Layer

**Order Aggregate** – domain: `confirm()`, `pay()`, `ship()`, `cancel()`, `applyDiscount()`. Dùng `Result<T>`, domain events (OrderCreatedEvent, OrderConfirmedEvent, OrderPaidEvent, OrderShippedEvent, OrderCancelledEvent). Repository interface: `IOrderRepository` (findById, findByCode, findByCustomerId, findByStatus, save, delete).

### 3.2 Application Layer

**CreateOrderUseCase** (BaseCommand): nhận CreateOrderRequest (customerId, items, shippingAddress, billingAddress). Dùng `OrderFactory.createFromCart()` để tạo Order, rồi `orderRepository.save()`. Trả về `{ orderId, orderNumber }`.

**ConfirmOrderUseCase / PayOrderUseCase / ShipOrderUseCase / CancelOrderUseCase**: nhận request có orderId (và body tương ứng), load order, gọi method domain (confirm, pay, ship, cancel), save và dispatch events.

### 3.3 Infrastructure Layer (flow mới)

**OrderRepository** – `infrastructure/order/repositories/order.repository.ts`

- Extends `BaseRepositoryTypeORM<Order, OrderOrm>`, implements `IOrderRepository`.
- Constructor: `super(OrderOrm, dataSource, OrderMapper.create())`.
- findById/findByCode: findOne với relations `['items']`, map qua mapper.
- save: `super.saveOne(order)` rồi `dispatchDomainEventsForAggregates(result)`.

**Persistence:** Đăng ký `IOrderRepository` -> `OrderRepository` trong `infrastructure/persistence/typeorm/typeorm.module.ts` (cùng nơi đăng ký Agreement và các repository khác).

### 3.4 Presentation Layer

**OrderCommandController** – `presentation/portal/order/controllers/order-command.controller.ts`

- POST `/`: createOrder(CreateOrderDto) -> createOrderUseCase.executeWithHooks({ customerId, items, shippingAddress, billingAddress }).
- PATCH `/:id/confirm`: confirmOrder(id).
- PATCH `/:id/pay`: payOrder(id, PayOrderDto).
- PATCH `/:id/ship`: shipOrder(id, ShipOrderDto).
- PATCH `/:id/cancel`: cancelOrder(id, CancelOrderDto).

DTOs: CreateOrderDto, PayOrderDto, ShipOrderDto, CancelOrderDto (theo dtos hiện có trong project).

---

## 4. Tóm tắt flow và quy ước

| Layer          | Nguồn tham chiếu     | Ghi chú                                                                    |
| -------------- | -------------------- | -------------------------------------------------------------------------- |
| Domain         | domain-driven-design | Aggregate + VO + Events + Repository interface (port).                     |
| Application    | domain-driven-design | BaseCommand/BaseQuery, execute/query, gọi executeWithHooks/queryWithHooks. |
| Infrastructure | data-visualizer      | persistence/typeorm (LibTypeOrmModule), repo + mapper + ORM entity.        |
| Presentation   | domain-driven-design | Controller gọi use-case, DTO validation, Swagger decorators.               |

- **Database/Persistence:** Không dùng `src/infrastructure/database`. Dùng `src/infrastructure/persistence/typeorm` (typeorm.module.ts) và đăng ký toàn bộ repository tại đây.
- **Use-case:** Command gọi `executeWithHooks(request)`, Query gọi `queryWithHooks(request)`.
- **Repository:** Kế thừa `BaseRepositoryTypeORM<Domain, Orm>`, inject `DataSource`, dùng mapper `XxxMapper.create()`, override `save` để gọi `dispatchDomainEventsForAggregates` sau `saveOne`.

Tham chiếu thêm: `@.claude/agents/architecture.md`, `@.claude/rules.md`.

---

## 5. AI Agents, Database & Generative UI (Flow bổ sung)

Khi làm việc với Front-end, Database Performance, hoặc tích hợp luồng AI được đề cập trong Phase 5, hãy sử dụng các rules thay vì tiếp cận thủ công truyền thống:

### Database (Postgres)

- Khi tối ưu query hoặc index (phần Data Visualizer Runtime Engine), phải tham khảo kiến thức từ `supabase-postgres-best-practices` để tránh lỗi Performance.

### Web UI/UX và Assets Pipeline

- Thay vì tự design Tailwind chung chung, sử dụng trí tuệ thiết kế từ `ui-ux-pro-max`, `frontend-design` để định hướng giao diện sạch đẹp, có chiều sâu của sản phẩm Data.
- Nếu bạn có asset ảnh hoặc Design Mockups, sử dụng SDK API `.claude/skills/design-md/` để trích xuất thành tài liệu `DESIGN.md`.
- Đảm bảo source HTML/CSS hoàn thành pass được check bằng `.claude/skills/web-design-guidelines/`.

### External AI / Browser Crawling

- Đối với flow đòi hỏi tích hợp external API / Browser Simulation: Dùng `.claude/skills/agent-browser/` cho Playwright Headless Crawling, và `.claude/skills/agent-tools/` để gọi AI 150+ open APIs thông qua `inference.sh`.
- Generate Assets demo có thể dùng `nano-banana` hoặc `nano-banana-2` (Gemini Native Models).
