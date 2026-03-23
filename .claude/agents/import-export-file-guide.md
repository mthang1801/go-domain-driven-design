---
name: import-export-file-guide
model: fast
---

# Huong Dan Import/Export trong NestJS (TypeScript)

## Muc Luc
1. [Khai niem co ban](#khai-niem-co-ban)
2. [Module va Folder](#module-va-folder)
3. [Import Syntax](#import-syntax)
4. [Export (Public/Private)](#export-publicprivate)
5. [Vi du thuc te](#vi-du-thuc-te)
6. [Best Practices](#best-practices)

## Khai niem co ban

### NestJS vs Go (tom tat)
| Khai niem | NestJS (TypeScript) | Go |
| --- | --- | --- |
| Module | Nest Module | Package |
| Export | `export` keyword | Ten viet hoa |
| Import | `import { ... } from '...'` | `import "path"` |
| Default Export | Co the su dung | Khong co |

## Module va Folder

- Moi folder nen co `index.ts` de export toan bo thanh phan trong folder (barrel pattern).
- Module NestJS dung de gom provider/controller va export dependency ra ben ngoai.

## Import Syntax

### 1. Named import
```ts
import { UserService } from './user.service';
```

### 2. Import tu index.ts (barrel)
```ts
import { UserService, UserRepository } from './user';
```

### 3. Alias path (tsconfig path)
```ts
import { UserService } from '@application/user';
```

## Export (Public/Private)

### 1. Export class/function/type
```ts
export class UserService {}
export type UserId = string;
export const USER_TOKEN = Symbol('USER_TOKEN');
```

### 2. Private (khong export)
```ts
class InternalMapper {}
const defaultTimeout = 3000;
```

## Vi du thuc te

### 1. Folder structure
```
src/
  application/
    user/
      user.service.ts
      user.repository.ts
      index.ts
```

### 2. user.service.ts
```ts
export class UserService {
  createUser() {}
}
```

### 3. user.repository.ts
```ts
export class UserRepository {
  findById() {}
}
```

### 4. index.ts (barrel)
```ts
export * from './user.service';
export * from './user.repository';
```

### 5. Import tu folder
```ts
import { UserService, UserRepository } from './application/user';
```

## Best Practices

### 1. Barrel index.ts
- Moi folder co `index.ts` de export cac file trong folder do.
- Tranh import sau qua nhieu level.

### 2. Ten file
- Ten file theo chuc nang: `user.service.ts`, `order.entity.ts`, `payment.port.ts`.
- Dong nhat naming convention trong toan bo codebase.

### 3. Export chi can thiet
- Chi export nhung class/type/const can dung ben ngoai.
- Thanh phan internal khong export.

### 4. Tranh default export
- Uu tien named export de de refactor.

### 5. Module boundary
- `module.ts` chi export provider can dung ben ngoai.
- `index.ts` chi lam nhiem vu gom export.
