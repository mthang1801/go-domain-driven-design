# EXAMPLE.md — Report Stream Export + SSE Progress

> Copy-paste examples cho dv-team. Mỗi section là một use-case hoàn chỉnh.

---

## Example 1: CSV Stream Export (đơn giản nhất)

### 1.1 Controller

```typescript
// src/presentation/portal/order/order.controller.ts

import { Controller, Get, Query } from '@nestjs/common';
import { SwaggerApiResponse } from '@core/swagger';
import { ReportCsvStreamOrderUsecase } from '@application/order/use-cases/report-csv-stream-order.usecase';
import { FindAllOrderQueryDto } from '@application/order/dto/find-all-order-query.dto';

@Controller()
export class OrderController {
    constructor(private readonly reportCsvStreamOrderUsecase: ReportCsvStreamOrderUsecase) {}

    @Get('report/csv/stream')
    @SwaggerApiResponse({ summary: 'Export CSV orders' })
    async reportCsvStream(@Query() query: FindAllOrderQueryDto) {
        // Controller chỉ delegate, KHÔNG xử lý logic
        return await this.reportCsvStreamOrderUsecase.execute(query);
    }
}
```

### 1.2 UseCase

```typescript
// src/application/order/use-cases/report-csv-stream-order.usecase.ts

import { ReportService } from '@common/modules/report/interfaces';
import { ReportFactory } from '@common/modules/report/factories';
import { ReportCsvWorksheetTemplate } from '@common/modules/report/plugins/csv/templates/report-csv-worksheet.template';
import { IOrderRepository } from '@domain/order/repositories/order.repository';
import { ENUM_ORDER_STATUS } from '@shared/enum';
import { Inject, Injectable } from '@nestjs/common';
import { FindAllOrderQueryDto } from '../dto/find-all-order-query.dto';

@Injectable()
export class ReportCsvStreamOrderUsecase {
    constructor(
        @Inject(IOrderRepository) private readonly orderRepository: IOrderRepository,
        @Inject(ReportService) private readonly reportService: ReportService,
    ) {}

    /**
     * Flow chính:
     * 1. Define template + worksheet (columns, mapping)
     * 2. Tạo DB stream qua TypeORM $stream()
     * 3. Set stream vào worksheet
     * 4. Gọi reportService.render() → trả về stream response
     */
    async execute(query: FindAllOrderQueryDto) {
        // ─── Step 1: Define worksheet columns ────────────────────
        const orderSheet = this.createOrderSheet() as ReportCsvWorksheetTemplate;

        // ─── Step 2: Define template ─────────────────────────────
        const template = this.createTemplate();
        template.addContent(orderSheet);

        // ─── Step 3: Tạo DB stream ──────────────────────────────
        const queryStream = await this.orderRepository
            .createQueryBuilder('o', { query })
            .$innerJoinAndSelect('customer', 'c')
            .$select([
                'o.id id',
                'o.orderCode order_code',
                'o.totalAmount total_amount',
                'o.status status',
                'o.createdAt created_at',
                'c.name customer_name',
                'c.email customer_email',
            ])
            .$orderBy({ id: 'ASC' })
            .$stream({ usePgQueryStream: true });
        // ⬆ QUAN TRỌNG: usePgQueryStream để stream từng row từ PG

        // ─── Step 4: Set stream vào sheet ────────────────────────
        orderSheet.setStream(queryStream);

        // ─── Step 5: Render (plugin sẽ tự xử lý) ────────────────
        return await this.reportService.render(template);
    }

    // ─── Private: Define columns ─────────────────────────────────

    private createOrderSheet() {
        return ReportFactory.createReportCsvWorksheet()
            .setUseTransform(false)
            .setColumn([
                { header: 'Mã đơn', key: 'order_code' },
                { header: 'Khách hàng', key: 'customer_name' },
                { header: 'Email', key: 'customer_email' },
                {
                    header: 'Tổng tiền',
                    key: 'total_amount',
                    width: 20,
                    style: { numFmt: '#,##0' }, // Format số
                },
                {
                    header: 'Trạng thái',
                    key: 'status',
                    width: 25,
                    mapping: {
                        // Auto-map giá trị
                        [ENUM_ORDER_STATUS.PENDING]: 'Chờ xử lý',
                        [ENUM_ORDER_STATUS.PROCESSING]: 'Đang xử lý',
                        [ENUM_ORDER_STATUS.COMPLETED]: 'Hoàn thành',
                        [ENUM_ORDER_STATUS.CANCELLED]: 'Đã hủy',
                    },
                },
                { header: 'Ngày tạo', key: 'created_at' },
            ]);
    }

    private createTemplate() {
        return ReportFactory.createReportCsvTemplate({
            name: 'ORDER_EXPORT',
            fileName: 'orders',
            storageDirectory: 'public/reports/order',
        });
    }
}
```

---

## Example 2: ExcelJS Stream Export (multi-sheet)

### 2.1 UseCase

```typescript
// src/application/user/use-cases/report-exceljs-stream-user.usecase.ts

import { ReportService } from '@common/modules/report/interfaces';
import { ReportFactory } from '@common/modules/report/factories';
import { IUserRepository } from '@domain/users/repositories/user.repository';
import { ENUM_STATUS } from '@shared/enum';
import { Inject, Injectable } from '@nestjs/common';
import { FindAllQueryFilterDto } from '../dto/find-all-query-filter-user.dto';

@Injectable()
export class ReportExceljsStreamUserUsecase {
    constructor(
        @Inject(IUserRepository) private readonly userRepository: IUserRepository,
        @Inject(ReportService) private readonly reportService: ReportService,
    ) {}

    async execute(query: FindAllQueryFilterDto) {
        // 1. Define template (workbook metadata)
        const template = ReportFactory.createReportExceljsTemplate({
            name: 'USER',
            storageDirectory: 'public/reports/user',
            author: { name: 'System', email: 'system@cms.com' },
        });

        // 2. Define worksheets
        const activeSheet = this.createActiveUsersSheet();
        const verifiedSheet = this.createVerifiedUsersSheet();

        template.addContent(activeSheet);
        template.addContent(verifiedSheet);

        // 3. Tạo DB streams song song
        const [activeStream, verifiedStream] = await Promise.all([
            this.userRepository
                .createQueryBuilder('u', { query })
                .$innerJoinAndSelect('profile', 'up')
                .$select(['u.id id', 'u.email email', 'u.status status', 'up.gender gender'])
                .addSelect(`(SELECT CONCAT_WS(' ', up.firstName, up.lastName))`, 'name')
                .$where({ status: ENUM_STATUS.ACTIVE })
                .$stream({ usePgQueryStream: true }),

            this.userRepository
                .createQueryBuilder('u', { query })
                .$innerJoinAndSelect('profile', 'up')
                .$select(['u.id id', 'u.email email', 'u.isVerified is_verified'])
                .addSelect(`(SELECT CONCAT_WS(' ', up.firstName, up.lastName))`, 'name')
                .$where({ isVerified: true })
                .$stream({ usePgQueryStream: true }),
        ]);

        // 4. Set streams vào sheets
        activeSheet.setStream(activeStream);
        verifiedSheet.setStream(verifiedStream);

        // 5. Render
        return await this.reportService.render(template);
    }

    private createActiveUsersSheet() {
        return ReportFactory.createExceljsWorksheet()
            .setSheetName('Active Users')
            .setIsDefaultSheet(true)
            .setColumn([
                { header: 'ID', key: 'id' },
                { header: 'Họ tên', key: 'name', width: 30 },
                { header: 'Email', key: 'email', width: 30 },
                {
                    header: 'Trạng thái',
                    key: 'status',
                    mapping: {
                        [ENUM_STATUS.ACTIVE]: 'Hoạt động',
                        [ENUM_STATUS.INACTIVE]: 'Ngưng HĐ',
                    },
                },
                { header: 'Giới tính', key: 'gender' },
            ]);
    }

    private createVerifiedUsersSheet() {
        return ReportFactory.createExceljsWorksheet()
            .setSheetName('Verified Users')
            .setColumn([
                { header: 'ID', key: 'id' },
                { header: 'Họ tên', key: 'name', width: 30 },
                { header: 'Email', key: 'email', width: 30 },
                {
                    header: 'Xác thực',
                    key: 'is_verified',
                    mapping: { true: '✅ Đã xác thực', false: '❌ Chưa' },
                },
            ]);
    }
}
```

---

## Example 3: SSE Progress — Client-side subscription

### 3.1 Backend — SSE Endpoint (đã có sẵn trong report.controller.ts)

```typescript
// libs/src/common/modules/report/report.controller.ts (đã tồn tại)

@Sse('report/progress/:reportId')
getProgress(@Param('reportId') reportId: string): Observable<any> {
    return this.sseRouter.getStream('report', { reportId });
}
```

### 3.2 Frontend — Subscribe SSE

```typescript
// React / Vanilla JS

function subscribeExportProgress(correlationId: string) {
    const eventSource = new EventSource(`/v1/report/progress/${correlationId}`);

    eventSource.onmessage = (event) => {
        const progress = JSON.parse(event.data);
        // progress: { status, processedCount, totalRecord, progressMsg, filePath }

        const percent = Math.round((progress.processedCount / progress.totalRecord) * 100);

        switch (progress.status) {
            case 'INIT':
                showToast('Đang khởi tạo...');
                break;
            case 'PROCESSING':
                updateProgressBar(percent);
                break;
            case 'SUCCESS':
                showToast('✅ Export hoàn tất!');
                downloadFile(progress.filePath);
                eventSource.close();
                break;
            case 'FAILED':
                showToast('❌ Export thất bại');
                eventSource.close();
                break;
        }
    };

    eventSource.onerror = () => {
        eventSource.close();
    };
}
```

---

## Example 4: Push-Data Mode (Big Data > 100k records)

Khi dataset quá lớn để giữ toàn bộ connection stream, dùng push-data mode:

```typescript
@Injectable()
export class ReportExceljsPushDataOrderUsecase {
    constructor(
        @Inject(IOrderRepository) private readonly orderRepository: IOrderRepository,
        @Inject(ReportService) private readonly reportService: ReportService,
    ) {}

    async execute(query: FindAllOrderQueryDto) {
        const sheet = ReportFactory.createExceljsWorksheet()
            .setSheetName('Orders')
            .setColumn([
                { header: 'ID', key: 'id' },
                { header: 'Code', key: 'code' },
                { header: 'Amount', key: 'amount', style: { numFmt: '#,##0' } },
            ]);

        const template = ReportFactory.createReportExceljsTemplate({
            name: 'ORDER_BIG',
            storageDirectory: 'public/reports/order',
        });
        template.addContent(sheet);

        // Push data theo batch thay vì stream liên tục
        let cursor = 0;
        const batchSize = 1000;
        let hasMore = true;

        while (hasMore) {
            const batch = await this.orderRepository
                .createQueryBuilder('o')
                .$select(['o.id id', 'o.code code', 'o.amount amount'])
                .$where({ id: MoreThan(cursor) })
                .$orderBy({ id: 'ASC' })
                .limit(batchSize)
                .getMany();

            if (batch.length === 0) {
                hasMore = false;
                break;
            }

            // Push từng batch vào temp file (NDJSON)
            await sheet.pushDataToTempFile(batch);
            cursor = batch[batch.length - 1].id;
        }

        // Finalize: tạo readable stream từ temp file
        await sheet.finalizeTempFile();
        sheet.setStreamFromTempFile();

        return await this.reportService.render(template);
    }
}
```

---

## Quick Reference: Column Definition API

```typescript
{
    header: string;               // Tên cột hiển thị
    key: string;                  // Key map từ DB query result
    width?: number;               // Độ rộng (ExcelJS only)
    style?: {
        numFmt?: string;          // '#,##0.00', 'yyyy-mm-dd', ...
        font?: { bold: true };    // ExcelJS only
        fill?: { ... };           // ExcelJS only
    };
    mapping?: Record<string, string>;  // Auto-map value → display text
}
```

## Quick Reference: Factory Methods

| Cần tạo gì        | Factory Method                                |
| ----------------- | --------------------------------------------- |
| CSV Template      | `ReportFactory.createReportCsvTemplate()`     |
| CSV Worksheet     | `ReportFactory.createReportCsvWorksheet()`    |
| ExcelJS Template  | `ReportFactory.createReportExceljsTemplate()` |
| ExcelJS Worksheet | `ReportFactory.createExceljsWorksheet()`      |

## Quick Reference: DB Stream

```typescript
// TypeORM custom $stream — dùng pg-query-stream nội bộ
const stream = await this.repository
    .createQueryBuilder('alias', { query })
    .$innerJoinAndSelect('relation', 'alias2')
    .$select(['alias.col1 col1', 'alias.col2 col2'])
    .$where({ status: 'ACTIVE' })
    .$orderBy({ id: 'ASC' })
    .$stream({ usePgQueryStream: true });
```
