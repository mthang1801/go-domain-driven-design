# Import Engine — Complete Implementation Example

Reference implementation: **Customer Import** (`src/application/import/`)

---

## 1. Domain Repository Interface

```typescript
// src/domain/customer/repositories/customer.repository.ts
export interface ICustomerRepository {
    existsByEmail(email: string): Promise<boolean>;
    existsByPhone(phone: string): Promise<boolean>;
    /** Required for saga compensation rollback */
    deleteByIds(ids: string[]): Promise<void>;
    /** Must return new record ID (string) — used to track for rollback */
    createWithRelations(payload: CreateCustomerImportPayload): Promise<string>;
}
export const ICustomerRepository = Symbol('ICustomerRepository');
```

---

## 2. TypeORM Repository Implementation

```typescript
// src/infrastructure/persistence/modules/customer/repositories/customer.repository.ts
@Injectable()
export class CustomerRepository implements ICustomerRepository {
    constructor(private readonly dataSource: DataSource) {}

    async existsByEmail(email: string): Promise<boolean> {
        const count = await this.dataSource.getRepository(CustomerOrm).count({ where: { email } });
        return count > 0;
    }

    async existsByPhone(phone: string): Promise<boolean> {
        const count = await this.dataSource.getRepository(CustomerOrm).count({ where: { phone } });
        return count > 0;
    }

    async deleteByIds(ids: string[]): Promise<void> {
        if (!ids.length) return;
        await this.dataSource.getRepository(CustomerOrm).delete(ids);
    }

    async createWithRelations(payload: CreateCustomerImportPayload): Promise<string> {
        let customerId!: string;
        await this.dataSource.transaction(async (manager) => {
            const repo = manager.getRepository(CustomerOrm);
            const customer = await repo.save(repo.create({ ...payload }));
            customerId = customer.id;
            // Insert profile, address as needed...
        });
        return customerId;
    }
}
```

---

## 3. Saga (Business Logic + Compensation)

```typescript
// src/application/import/saga/customer-import.saga.ts
const VN_PHONE_REGEXP = /^(0[35789]\d{8}|0[12][0-9]{8})$/;
const EMAIL_REGEXP = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const BATCH_SIZE = 100;

export interface CustomerImportSagaData {
    correlationId: string;
    filePath: string;
    persistedIds: string[]; // track for rollback
    totalRows: number;
    importedRows: number;
    failedRows: number;
    errors: Array<{ rowNumber: number; message: string }>;
}

@Injectable()
export class CustomerImportSaga {
    private readonly logger = new Logger(CustomerImportSaga.name);

    constructor(
        @Inject(ImportStreamPipelineBuilder)
        private readonly pipelineBuilder: ImportStreamPipelineBuilder,
        @Inject(ICustomerRepository) private readonly customerRepository: ICustomerRepository,
    ) {}

    /**
     * All-or-nothing execution:
     *   - Any row fails → compensate(deleteByIds) → return failure summary
     *   - Exception thrown → compensate → re-throw
     */
    async execute(command: ImportProcessCommand): Promise<ImportProcessResult> {
        const state: CustomerImportSagaData = {
            correlationId: command.correlationId,
            filePath: command.filePath,
            persistedIds: [],
            totalRows: 0,
            importedRows: 0,
            failedRows: 0,
            errors: [],
        };

        try {
            await this.runPipeline(state, command);
        } catch (err) {
            this.logger.error(
                `Unexpected error — compensating ${state.persistedIds.length} records`,
                err,
            );
            await this.compensate(state);
            throw err;
        }

        if (state.failedRows > 0) {
            this.logger.warn(
                `${state.failedRows} row(s) failed — compensating ${state.persistedIds.length} committed records`,
            );
            await this.compensate(state);
            return {
                totalRows: state.totalRows,
                importedRows: 0,
                failedRows: state.totalRows,
                errors: state.errors,
            };
        }

        return {
            totalRows: state.totalRows,
            importedRows: state.importedRows,
            failedRows: 0,
            errors: [],
        };
    }

    private async runPipeline(
        state: CustomerImportSagaData,
        command: ImportProcessCommand,
    ): Promise<void> {
        // Build worksheet with column definitions
        const worksheet = ImportFactory.createImportCsvWorksheet()
            .setSourceFilePath(state.filePath)
            .setColumn([
                { header: 'firstName', key: 'firstName', type: 'string', required: true },
                { header: 'lastName', key: 'lastName', type: 'string', required: true },
                { header: 'email', key: 'email', type: 'string', required: true },
                { header: 'phone', key: 'phone', type: 'string' },
                {
                    header: 'status',
                    key: 'status',
                    type: 'string',
                    mapping: { 'Hoạt động': 'ACTIVE', 'Không hoạt động': 'INACTIVE' },
                },
                { header: 'loyaltyPoints', key: 'loyaltyPoints', type: 'number' },
                { header: 'lastOnlineAt', key: 'lastOnlineAt', type: 'date' },
            ]);

        const template = ImportFactory.createImportCsvTemplate({ name: ImportModuleType.CUSTOMER });
        template.addContent(worksheet);

        const [pipeline] = this.pipelineBuilder.buildCsvPipeline<Record<string, any>>(template);
        const batched = pipeline.batch(BATCH_SIZE);

        let rowNumber = 1;
        for await (const batch of batched.source as AsyncIterable<Record<string, any>[]>) {
            for (const row of batch) {
                state.totalRows++;

                // ── Format validation ─────────────────────────────────────────
                if (!row.email?.trim() || !EMAIL_REGEXP.test(row.email.trim())) {
                    state.failedRows++;
                    state.errors.push({ rowNumber, message: `Invalid email: "${row.email}"` });
                    rowNumber++;
                    continue;
                }
                if (row.phone && !VN_PHONE_REGEXP.test(row.phone.trim())) {
                    state.failedRows++;
                    state.errors.push({ rowNumber, message: `Invalid phone: "${row.phone}"` });
                    rowNumber++;
                    continue;
                }

                // ── DB uniqueness ─────────────────────────────────────────────
                if (await this.customerRepository.existsByEmail(row.email.trim().toLowerCase())) {
                    state.failedRows++;
                    state.errors.push({ rowNumber, message: `Email already exists: ${row.email}` });
                    rowNumber++;
                    continue;
                }
                if (row.phone && (await this.customerRepository.existsByPhone(row.phone.trim()))) {
                    state.failedRows++;
                    state.errors.push({ rowNumber, message: `Phone already exists: ${row.phone}` });
                    rowNumber++;
                    continue;
                }

                // ── Persist ───────────────────────────────────────────────────
                const id = await this.customerRepository.createWithRelations({
                    firstName: String(row.firstName ?? '').trim(),
                    lastName: String(row.lastName ?? '').trim(),
                    email: String(row.email ?? '')
                        .trim()
                        .toLowerCase(),
                    phone: row.phone?.trim() || undefined,
                    status: row.status === 'INACTIVE' ? 'INACTIVE' : 'ACTIVE',
                    loyaltyPoints: typeof row.loyaltyPoints === 'number' ? row.loyaltyPoints : 0,
                    lastOnlineAt: row.lastOnlineAt instanceof Date ? row.lastOnlineAt : undefined,
                });

                state.persistedIds.push(id); // track for potential rollback
                state.importedRows++;
                await command.onProgress(state.totalRows, state.totalRows);
                rowNumber++;
            }
        }
    }

    async compensate(state: CustomerImportSagaData): Promise<void> {
        if (!state.persistedIds.length) return;
        this.logger.warn(
            `Rolling back ${state.persistedIds.length} customers — correlationId=${state.correlationId}`,
        );
        await this.customerRepository.deleteByIds(state.persistedIds);
    }
}
```

---

## 4. Strategy (Thin Delegator)

```typescript
// src/application/import/strategies/customer-import.strategy.ts
@Injectable()
export class CustomerImportStrategy implements ImportModuleStrategy {
    readonly moduleType = ImportModuleType.CUSTOMER; // must match the value sent by Controller

    constructor(@Inject(CustomerImportSaga) private readonly saga: CustomerImportSaga) {}

    async process(command: ImportProcessCommand): Promise<ImportProcessResult> {
        return this.saga.execute(command);
    }
}
```

---

## 5. Module Wiring

```typescript
// src/application/import/import.module.ts
const IMPORT_STRATEGIES = [CustomerImportStrategy] as const;
// ↑ To add new module: append XxxImportStrategy here — nothing else to change

@Global()
@Module({
    imports: [TypeOrmInfrastructureModule, ImportEngineModule.forRootAsync()],
    providers: [
        { provide: ICustomerRepository, useClass: CustomerRepository },
        CustomerImportSaga,
        ...IMPORT_STRATEGIES,
        {
            provide: ImportModuleProcessorFactory,
            useFactory: (...strategies: ImportModuleProcessor[]) => ({
                create: (module: string) => strategies.find((s) => s.moduleType === module),
            }),
            inject: [...IMPORT_STRATEGIES],
        },
    ],
    exports: [ImportModuleProcessorFactory],
})
export class ImportApplicationModule {}
```

---

## 6. Controller

```typescript
// src/presentation/portal/import/import.controller.ts
@Post('upload')
@UseInterceptors(FileInterceptor('file'))
async upload(
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: ImportUploadDto,
    @Headers('x-correlation-id') correlationId: string,
) {
    const filePath = await this.saveTemp(file);
    await this.importService.submit({
        correlationId,
        module: dto.module,    // e.g. 'customer'
        filePath,
        fileName: file.originalname,
        author: dto.author,
    });
    return { correlationId };
}
```

---

## 7. Adding a New Module (e.g. Product)

1. **Repository**: Add `existsByCode()`, `deleteByIds()`, `createWithRelations(): Promise<string>` to `IProductRepository`
2. **Saga**: Create `ProductImportSaga` — copy `CustomerImportSaga`, update column schema + validation rules
3. **Strategy**: Create `ProductImportStrategy` — delegate to `ProductImportSaga.execute()`
4. **Module**: Add `ProductImportSaga`, `ProductImportStrategy` to `IMPORT_STRATEGIES` array
5. **Controller**: Add `ImportModuleType.PRODUCT = 'product'` constant

That's it — no changes to `ImportWorker`, `ImportService`, or `ImportEngineModule`.
