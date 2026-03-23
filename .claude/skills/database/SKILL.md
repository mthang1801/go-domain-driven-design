---
name: database
description: database
---
## Persistence Guide (Repository Pattern)

Cach trien khai repository o layer infrastructure, dua tren `BaseRepository` trong `@core/database`.

### 1) Domain repository interface

Dat interface o `src/domain/**/repositories`:

```typescript
export abstract class IFormRepository {
  abstract persistData(input: Form, extraData?: any): Promise<Form>;
  abstract findById(id: number): Promise<Form>;
}
```

### 2) Infrastructure repository

Ke thua `BaseRepository<Domain, Orm>` va inject `DataSource`:

```typescript
import { BaseRepository } from '@core/database';
import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';

@Injectable()
export class FormRepository
  extends BaseRepository<Form, FormOrm>
  implements IFormRepository
{
  constructor(dataSource: DataSource) {
    super(FormOrm, dataSource, new FormMapper());
  }
}
```

### 3) Mapping va quy uoc

- `BaseRepository` tu dong map `Domain <-> Orm` qua `IMapper`.
- Dung `this.repository` cho query raw, `this.transformToDomain` khi tra ve.
- Khong dat business logic vao repository.

### 4) Transactional persistence

Neu can transaction:
- Su dung `@TypeOrmTransaction()` tren method.
- Inject repository theo transaction bằng `@InjectTransactionRepository(Entity)`.

```typescript
@InjectTransactionRepository(FormOrm)
private readonly formRepository: Repository<FormOrm>;
```

### 5) BaseOrmRepository

`BaseOrmRepository<T>` extend `Repository<T>` de can tuong tac raw va co `dataSource`, `tableName`.
Dung khi can custom repository thuoc ORM.
