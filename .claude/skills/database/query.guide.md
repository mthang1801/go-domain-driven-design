## Query Guide (TypeORM Builder Extensions)

Core database mo rong `Repository` va `SelectQueryBuilder` de ho tro query chain de dang.

### 1) Repository.$createQueryBuilder

Su dung trong repository:

```typescript
return this.repository
  .$createQueryBuilder('entity', { query })
  .$leftJoinAndSelect('entity.relation', 'relation', {
    selectFields: ['id', 'name'],
  })
  .$where('entity.status = :status', { status: 'ACTIVE' })
  .$andWhere('entity.formTemplateId = :formTemplateId', { formTemplateId: 1 })
  .getManyAndCount();
```

`$createQueryBuilder` co the nhan:
- `alias`
- `options.queryRunner`
- `options.query` (duoc dung trong `$where` neu khong truyen parameter)

### 2) Join helpers

Builder ho tro:
- `$leftJoinAndSelect(...)`
- `$innerJoinAndSelect(...)`
- `$addLeftJoinAndSelect(...)` / `$addInnerJoinAndSelect(...)`

Options:
- `selectFields`: chi dinh field can select
- `condition`, `parameters`
- `withDeleted`

### 3) Where helpers

`$where`, `$andWhere`, `$orWhere` nhan:
- string SQL
- `Brackets`
- function callback
- object conditions

Helper se tu dong map param, ho tro operator trong `@core/database/typeorm/helper`.

### 4) Pagination & order

Su dung `$addPaginate`, `$orderBy`, `$addOrderBy` (xem `typeorm/builder`).

### 5) Vi du tu infra repository

Trong `group-field-master-data.repository.ts`:
- chain `.$createQueryBuilder(...)`
- `.$leftJoinAndSelect(...)`
- `.$where(...)`
- `.orderBy(...).addOrderBy(...)`

Nen uu tien builder helper de dong bo filter/pagination/ordering giua cac repository.
