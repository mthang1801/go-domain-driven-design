## Transaction Guide (TypeORM + Mongoose)

Hướng dẫn dùng transaction trong `libs/src/core/database` cho TypeORM và Mongoose.

### 1) TransactionManager tổng quát

```typescript
import { TransactionManager } from '@core/database';

@TransactionManager({ dbType: 'TypeORM' })
async doSomething() {
  // ...
}
```

Option:
- `dbType`: `'TypeORM' | 'Mongoose'` (default TypeORM)
- `host`: chọn connection host cụ thể
- `commitErrorCodes`: lỗi vẫn commit
- `rollbackErrorCodes`: lỗi sẽ rollback

### 2) TypeORM transaction

Sử dụng `@TypeOrmTransaction()` và `@InjectTransactionRepository(Entity)` để đảm bảo repository trong transaction dùng `QueryRunner`.

```typescript
import { InjectTransactionRepository, TypeOrmTransaction } from '@core/database';
import { Repository } from 'typeorm';

class ExampleRepository {
  @InjectTransactionRepository(FormOrm)
  private readonly formRepository: Repository<FormOrm>;

  @TypeOrmTransaction()
  async persist(input: Form) {
    // formRepository đã được bind theo queryRunner
    return this.formRepository.save(input as any);
  }
}
```

Luu y:
- Class phai inject `DataSource` de `dataSourceRepository` tim duoc dataSource.
- Method duoc wrap se tu dong `commit`/`rollback` theo `commitErrorCodes`/`rollbackErrorCodes`.
- Khong reuse repository da bind transaction sau khi method ket thuc.

### 3) Mongoose transaction

Sử dụng `@MongooseTransaction()` và `@InjectTransactionModel(Model)` để bind Model theo session.

```typescript
import { InjectTransactionModel, MongooseTransaction } from '@core/database';
import { Model } from 'mongoose';

class ExampleMongoRepository {
  @InjectTransactionModel(UserModel)
  private readonly userModel: Model<UserDocument>;

  @MongooseTransaction({ host: 'default' })
  async persist(input: User) {
    return this.userModel.create([input], { session: arguments[arguments.length - 1] as any });
  }
}
```

Luu y:
- Class phai co `this.connection.getConnection(host)` (tu MongoDB module).
- Session duoc tao/commit/abort tu dong theo errorCodes.
