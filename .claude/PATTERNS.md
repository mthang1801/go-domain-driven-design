# Common Patterns - Quick Reference

## 🎯 Aggregate Pattern

```typescript
export class {{Entity}} extends BaseAggregateRoot {
    private constructor(id: UniqueEntityId, private props: {{Entity}}Props) {
        super(id);
        this.validate();
    }

    public static create(props: Create{{Entity}}Props): {{Entity}} {
        const entity = new {{Entity}}(UniqueEntityId.create(), {
            ...props,
            createdAt: new Date(),
            updatedAt: new Date()
        });

        entity.addDomainEvent(new {{Entity}}CreatedEvent(entity));
        return entity;
    }

    public static reconstitute(id: UniqueEntityId, props: {{Entity}}Props): {{Entity}} {
        return new {{Entity}}(id, props);
    }

    private validate(): void {
        // Invariants
    }

    // Getters only, no setters
}
```

## 🎯 Value Object Pattern

```typescript
interface {{ValueObject}}Props {
    value: string;
}

export class {{ValueObject}} extends ValueObject<{{ValueObject}}Props> {
    private constructor(props: {{ValueObject}}Props) {
        super(props);
    }

    public static create(value: string): {{ValueObject}} {
        // Validation
        return new {{ValueObject}}({ value });
    }

    get value(): string {
        return this.props.value;
    }
}
```

## 🎯 Use Case Pattern (Command / Query)

Use-case **bắt buộc** extend `BaseCommand` (ghi) hoặc `BaseQuery` (đọc). Gọi `executeWithHooks(request)` / `queryWithHooks(request)` từ controller.

**Command (Create/Update/Delete/Approve/...):**

```typescript
@Injectable()
export class {{Action}}{{Entity}}UseCase extends BaseCommand<
    {{Action}}{{Entity}}Request,
    {{Action}}{{Entity}}Response
> {
    constructor(
        @Inject(I{{Entity}}Repository)
        private readonly repository: I{{Entity}}Repository
    ) {
        super();
    }

    async execute(request: {{Action}}{{Entity}}Request): Promise<{{Action}}{{Entity}}Response> {
        // 1. Validate (VO.create, Guard...)
        // 2. Load aggregate / check rules
        // 3. Domain logic (aggregate.create, aggregate.approve...)
        // 4. repository.save(aggregate)
        // 5. Return response
    }

    protected async afterExecute?(request: {{Action}}{{Entity}}Request, response: {{Action}}{{Entity}}Response): Promise<void> {
        this.logger.log('...');
    }
}
```

**Query (Get list / Get detail):**

```typescript
@Injectable()
export class Get{{Entity}}ListUseCase extends BaseQuery<
    Get{{Entity}}ListRequest,
    Get{{Entity}}ListResult
> {
    constructor(private readonly listService: Get{{Entity}}ListService) {
        super();
    }

    async query(request: Get{{Entity}}ListRequest): Promise<Get{{Entity}}ListResult> {
        return this.listService.execute(request.filters ?? {}, request.pagination ?? {});
    }
}
```

## 🎯 Repository Pattern

Repository kế thừa `BaseRepositoryTypeORM` từ `@ddd/infrastructure`. **Không** dùng `@InjectRepository` — truyền `DataSource` và mapper vào constructor; base class tự lấy repository từ DataSource.

```typescript
@Injectable()
export class {{Entity}}Repository
    extends BaseRepositoryTypeORM<{{Entity}}, {{Entity}}Orm>
    implements I{{Entity}}Repository
{
    constructor(dataSource: DataSource) {
        super({{Entity}}Orm, dataSource, {{Entity}}Mapper.create());
    }

    findById(id: string): Promise<{{Entity}} | null> {
        return this.findOneBy({ id });
    }

    override async save(domain: {{Entity}}): Promise<{{Entity}}> {
        const result = await super.saveOne(domain);
        await this.dispatchDomainEventsForAggregates(result);
        return result;
    }
}
```

Mapping Domain ↔ ORM thực hiện trong **Mapper** (xem pattern Mapper bên dưới), không viết toPersistence/toDomain trong repository.

## 🎯 Mapper Pattern (Domain ↔ ORM)

Mapper nằm ở `src/shared/mappers/` (hoặc tương đương trong monorepo), extend `BaseMapper<DomainEntity, OrmEntity>` từ `@ddd/infrastructure`. Repository dùng `XxxMapper.create()` khi khởi tạo. Ví dụ: `domain-driven-design/src/shared/mappers` (agreement.mapper, order.mapper, order-item.mapper).

```typescript
import { UniqueEntityID } from '@ddd/domain';
import { BaseMapper } from '@ddd/infrastructure';
import { {{Entity}} } from '@domain/{{module}}/entities';
import { {{Entity}}Orm } from '@infrastructure/{{module}}/entities/{{entity}}.orm.entity';

export class {{Entity}}Mapper extends BaseMapper<{{Entity}}, {{Entity}}Orm> {
    toDomain(orm: {{Entity}}Orm): {{Entity}} {
        const voResult = SomeVO.create(orm.someField);
        if (voResult.isFailure) throw new Error(voResult.errorMessage);
        const entityResult = {{Entity}}.create(
            { someField: voResult.getValue(), createdAt: orm.createdAt, updatedAt: orm.updatedAt },
            new UniqueEntityID(orm.id.toString()),
        );
        if (entityResult.isFailure) throw new Error(entityResult.errorMessage);
        return entityResult.getValue();
    }

    toOrm(domain: {{Entity}}): {{Entity}}Orm {
        return {{Entity}}Orm.fromInput({
            id: domain.id.toValue(),
            someField: domain.someField.getValue(),
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt,
        }) as {{Entity}}Orm;
    }
}
```

- **toDomain(orm):** Tạo VO/Entity từ ORM, trả về domain entity (hoặc reconstitute với id).
- **toOrm(domain):** Map domain ra plain/ORM (có thể dùng `Orm.fromInput(...)` nếu có).
- Aggregate có nested entity: dùng mapper con (ví dụ `OrderItemMapper` trong `OrderMapper`).

## 🎯 Controller Pattern

Dùng **custom Swagger API** từ `@core/swagger` (libs/src/core/swagger/api.ts): `SwaggerApiTags`, `SwaggerApiCreatedResponse`, `SwaggerApiListResponse`, `SwaggerApiResponse`. Mỗi decorator nhận `{ summary, body?, responseType? }`.

```typescript
import {
    SwaggerApiTags,
    SwaggerApiCreatedResponse,
    SwaggerApiListResponse,
    SwaggerApiResponse,
} from '@core/swagger';

@Controller()
@SwaggerApiTags('{{Entity}}')
export class {{Entity}}Controller {
    constructor(
        private readonly createUseCase: Create{{Entity}}UseCase,
        private readonly getListUseCase: Get{{Entity}}ListUseCase
    ) {}

    @Post()
    @SwaggerApiCreatedResponse({
        summary: 'Create {{entity}}',
        body: Create{{Entity}}Dto,
        responseType: {{Entity}}ResponseDto,
    })
    async create(@Body() dto: Create{{Entity}}Dto) {
        return await this.createUseCase.executeWithHooks({
            /* map dto -> request */
        });
    }

    @Get()
    @SwaggerApiListResponse({
        summary: 'Get {{entity}} list with filters and pagination',
        responseType: {{Entity}}ResponseDto,
    })
    async list(@Query() dto: List{{Entity}}Dto) {
        return await this.getListUseCase.queryWithHooks({
            filters: { ... },
            pagination: { page: dto.page, limit: dto.limit },
        });
    }

    @Patch(':id/approve')
    @SwaggerApiResponse({
        summary: 'Approve {{entity}}',
        body: Approve{{Entity}}Dto,
    })
    async approve(@Param('id') id: string, @Body() dto: Approve{{Entity}}Dto) {
        return await this.approveUseCase.executeWithHooks({ agreementId: id, approvedBy: dto.approvedBy });
    }
}
```

## 🎯 DTO Pattern

```typescript
export class Create{{Entity}}Dto {
    @IsString()
    @IsNotEmpty()
    @MaxLength(255)
    name: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsUUID()
    relatedId: string;
}

export class {{Entity}}ResponseDto {
    id: string;
    name: string;
    description: string;
    createdAt: Date;

    static fromDto(dto: {{Entity}}Dto): {{Entity}}ResponseDto {
        const response = new {{Entity}}ResponseDto();
        response.id = dto.id;
        response.name = dto.name;
        response.description = dto.description;
        response.createdAt = dto.createdAt;
        return response;
    }
}
```

## 🎯 Domain Event Pattern

```typescript
export class {{Entity}}{{Action}}Event extends BaseDomainEvent {
    constructor(
        public readonly {{entity}}: {{Entity}},
        public readonly metadata?: Record<string, any>
    ) {
        super();
    }

    getAggregateId(): string {
        return this.{{entity}}.id.toString();
    }
}
```

## 🎯 Factory Pattern

```typescript
@Injectable()
export class {{Entity}}Factory {
    create(props: Create{{Entity}}Props): {{Entity}} {
        // Complex creation logic
        // Validation
        // Sub-entity creation
        return {{Entity}}.create(props);
    }

    createFromDto(dto: Create{{Entity}}Dto, userId: string): {{Entity}} {
        return this.create({
            ...dto,
            createdBy: new UniqueEntityId(userId)
        });
    }
}
```

## 🎯 Saga Pattern

```typescript
@Injectable()
export class {{Process}}Saga {
    constructor(
        private readonly step1Service: Step1Service,
        private readonly step2Service: Step2Service,
        private readonly compensationService: CompensationService
    ) {}

    async execute(input: {{Process}}Input): Promise<{{Process}}Result> {
        const context = new SagaContext();

        try {
            // Step 1
            await this.step1(context, input);

            // Step 2
            await this.step2(context, input);

            // Complete
            return this.complete(context);

        } catch (error) {
            // Rollback
            await this.compensate(context);
            throw error;
        }
    }

    private async step1(context: SagaContext, input: any): Promise<void> {
        const result = await this.step1Service.execute(input);
        context.saveStep('step1', result);
    }

    private async compensate(context: SagaContext): Promise<void> {
        // Reverse order compensation
        if (context.hasStep('step2')) {
            await this.compensationService.compensateStep2(context);
        }
        if (context.hasStep('step1')) {
            await this.compensationService.compensateStep1(context);
        }
    }
}

## 🎯 Frontend Priority & decoupled APIs

- **Current Goal**: Prioritize building UI as a dedicated SPA (React.js / Next.js / Vue.js) using the `vercel-react-best-practices` skill.
- **Backend View Note**: If embedding UI inside NestJS backend is absolutely necessary, use Server-Side Rendering (SSR) in NestJS with `.hbs` templates using `skills/server-side-render`.
- Always ensure strict API boundaries. Controllers must return JSON DTOs independently of SSR or client choices.
```
