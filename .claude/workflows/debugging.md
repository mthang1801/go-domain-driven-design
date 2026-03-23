---
description: Workflow: Debugging Issues
---

# Workflow: Debugging Issues

## Step-by-Step Debugging

### Step 1: Reproduce the Issue

- [ ] Get exact steps to reproduce
- [ ] Note error messages
- [ ] Check logs
- [ ] Identify which layer has the issue
- [ ] **Antigravity Task**: Generate or update the `task.md` artifact with the suspected error layers and reproduction steps.

**Cursor Command:**

```
@Codebase Find where {{ERROR_MESSAGE}} is thrown and trace the execution path
```

### Step 2: Identify the Layer

- [ ] Presentation (Controller/DTO issue)?
- [ ] Application (Use Case logic issue)?
- [ ] Domain (Business logic issue)?
- [ ] Infrastructure (Repository/DB issue)?

### Step 3: Add Logging

Dùng decorator **`@LogExecution`** từ `@common/decorators/log.decorator` (libs/src/common/decorators/log.decorator.ts). Bật `isDebug: true` khi cần xem args/flow; bật `enableLogResponse: true` khi cần xem kết quả trả về. Khi có lỗi, log error kèm **stack trace dạng JSON stringify** (decorator đã log `stringify(error?.stack)`; nếu tự bắt lỗi thì dùng cùng format).

**Decorator trên use-case / service (khi cần debug):**

```typescript
import { LogExecution } from '@common/decorators/log.decorator';

@Injectable()
export class Create{{Entity}}UseCase extends BaseCommand<...> {

    @LogExecution({ isDebug: true, enableLogResponse: true })
    async execute(request: Create{{Entity}}Request): Promise<...> {
        // ...
    }
}
```

- **isDebug: true** — log args đầu vào (stringify) khi method bắt đầu.
- **enableLogResponse: true** — log kết quả trả về (stringify) khi method kết thúc.
- Mặc định decorator đã log lỗi với `this.logger.error(stringify(error?.stack), error?.stack, 'ClassName#method.ERROR')`.

**Khi bắt lỗi thủ công (catch block), luôn log stack trace dạng JSON stringify:**

```typescript
import { stringify } from '@shared/utils';

try {
    // ...
} catch (error: any) {
    this.logger.error(
        stringify({ message: error?.message, stack: error?.stack, name: error?.name }),
        error?.stack,
        `${this.constructor.name}#execute.ERROR`,
    );
    throw error;
}
```

Hoặc nếu không import `stringify`: `stringify({ message: error?.message, stack: error?.stack })`.

**Cursor Command:**

```
Add logging to trace {{FEATURE}} execution flow:
1. Use @LogExecution from @common/decorators/log.decorator with isDebug: true (and enableLogResponse: true if needed)
2. On manual catch, use this.logger.error with stack trace as JSON stringify (stringify from @shared/utils or JSON.stringify)
```

### Step 4: Write Failing Test

- [ ] Write test that reproduces the bug
- [ ] Ensure test fails with current code
- [ ] Fix will make test pass

**Cursor Command:**

```
Write a test that reproduces the bug where {{DESCRIPTION}}
```

### Step 5: Fix the Issue

- [ ] Fix in appropriate layer
- [ ] Ensure test passes
- [ ] Check for side effects

### Step 6: Verify Fix

- [ ] All tests pass
- [ ] Manual verification
- [ ] Check related functionality

**Commands:**
// turbo

```bash
pnpm test
pnpm test:cov
pnpm test:e2e
```
