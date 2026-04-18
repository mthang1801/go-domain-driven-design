# Lending Microservices — Recommended Agent Set

Specialized agents cho monorepo Lending. Bộ này giữ structure mạnh từ sample thành công, nhưng đã đổi toàn bộ assumptions sang stack thật của repo hiện tại.

> **Workspace shape**: `lending/` là workspace root đa repo, không phải git root cho mọi task. Khi agent chạm vào một package hoặc service con, mọi lệnh `git` và verification phải chạy trong đúng subrepo đó.

> **Security by Default**: mọi developer-facing agent đều phải đi qua `security-review` khi task chạm code hoặc user data.

## Team Overview

| Agent | Role | File |
| --- | --- | --- |
| **`lending-orchestrator`** | Intake, routing, execution brief | `lending-orchestrator.md` |
| `lending-product-analyst` | Requirements, AC, scope, edge cases | `lending-product-analyst.md` |
| `lending-backend-developer` | NestJS DDD backend, RabbitMQ, import or export runtime | `lending-backend-developer.md` |
| `lending-feature-developer` | Cross-layer or cross-service feature delivery | `lending-feature-developer.md` |
| `lending-frontend-developer` | Umi Max frontend specialist | `lending-frontend-developer.md` |
| `lending-db-optimizer` | Query, filter, index, export-scale optimization | `lending-db-optimizer.md` |
| `lending-test-writer` | TDD, regression tests, coverage for risky paths | `lending-test-writer.md` |
| `lending-debugger` | Root-cause analysis across services, queues, and UI | `lending-debugger.md` |
| `lending-refactor-specialist` | Safe refactor without behavior drift | `lending-refactor-specialist.md` |
| `lending-code-reviewer` | Final quality gate before merge | `lending-code-reviewer.md` |
| `lending-agents` | Focused execution agent for the dedicated frontend subteam | `lending-agents.md` |

## Agent Cards

### lending-product-analyst

> Dùng trước khi implement nếu yêu cầu còn mơ hồ hoặc có nguy cơ scope creep.
> Luôn xác định subrepo chịu trách nhiệm trước khi handoff sang agent khác.

### lending-backend-developer

> Dùng cho backend service, DDD layers, RabbitMQ, import engine, report export runtime.

### lending-feature-developer

> Dùng khi task chạm nhiều layer hoặc nhiều service.

### lending-frontend-developer

> Dùng cho `frontend/` khi cần UI specialist bám đúng archetype, helper graph, docs stack dưới `.agents/skills/lending-frontend/references/*`, và dynamic-form/export/upload conventions.

### lending-db-optimizer

> Dùng khi query chậm, list filter phức tạp, export đọc dữ liệu lớn, hoặc cần `native-query-filter`.
> Ưu tiên root-table list query, count query tách riêng, và strategy aggregation/refund dựa trên query plan thật.

### lending-test-writer

> Dùng cho TDD, regression test, và test cover cho path rủi ro cao.

### lending-debugger

> Dùng cho bug, timeout, queue issue, runtime crash, preview fail, hoặc state bug.

### lending-refactor-specialist

> Dùng khi cần giảm duplication, sửa code smell, hoặc kéo code về đúng patterns repo mà không đổi behavior.

### lending-code-reviewer

> Dùng cuối flow hoặc khi user yêu cầu review.

### lending-agents

> Đây là execution agent hẹp cho workflow frontend 2-agent đã dựng riêng. Khi task hoàn toàn thuộc `frontend/`, orchestrator có thể route vào đây thay vì flow rộng hơn. Agent này phải bám docs-first workflow trong `.agents/skills/lending-frontend/references/*`.

## Trigger Matrix

| Task | Primary Agent | Secondary Agent |
| --- | --- | --- |
| Feature mới chưa rõ scope | `lending-product-analyst` | `lending-orchestrator` |
| Backend change trong một service | `lending-backend-developer` | `lending-test-writer` |
| Cross-service flow qua RabbitMQ | `lending-feature-developer` | `lending-backend-developer` |
| Frontend list/detail/create/update/export | `lending-frontend-developer` | `lending-agents` |
| Frontend-only delivery theo workflow riêng | `lending-agents` | `lending-orchestrator` |
| Slow query hoặc list filter nặng | `lending-db-optimizer` | `lending-backend-developer` |
| Bug hoặc timeout | `lending-debugger` | `lending-test-writer` |
| Refactor | `lending-refactor-specialist` | `lending-test-writer` |
| Viết hoặc tăng test | `lending-test-writer` | — |
| Review trước merge | `lending-code-reviewer` | — |

## Recommended SDLC Flow

```text
0. Clarify scope
   -> lending-product-analyst

1. Route the task
   -> lending-orchestrator

2. Write or update tests when risk justifies it
   -> lending-test-writer

3. Implement
   -> lending-backend-developer or lending-feature-developer
   -> lending-frontend-developer or lending-agents

4. Optimize if needed
   -> lending-db-optimizer

5. Debug or refactor follow-up
   -> lending-debugger or lending-refactor-specialist

6. Final review
   -> lending-code-reviewer
```

## Workspace Notes

- Một task có thể chạm nhiều subrepo, nhưng mỗi verification step phải target đúng package hoặc service đang đổi.
- Khi report plan, review, hoặc DB optimization, ghi rõ subrepo nào là execution root để tránh chạy lệnh ở workspace root sai ngữ cảnh.
- Với query-heavy work, `lending-db-optimizer` không chỉ tối ưu SQL; agent này cũng phải xác nhận query plan, count split, và aggregation strategy trước khi coi task là done.

## Usage Examples

```text
Task: Use lending-product-analyst from .agents/agents/lending-product-analyst.md to clarify the scope of a new repayment export feature
Task: Use lending-backend-developer from .agents/agents/lending-backend-developer.md to add a RabbitMQ request-response contract between lending-transaction and lending-evf
Task: Use lending-frontend-developer from .agents/agents/lending-frontend-developer.md to update the finance-product detail flow without duplicating export logic
Task: Use lending-code-reviewer from .agents/agents/lending-code-reviewer.md to review recent changes before merge
```

## Notes

- File `lending-orchestrator.md` là điểm vào mặc định nếu chưa chắc nên dùng agent nào.
- File `lending-agents.md` là frontend execution agent chuyên biệt, không thay thế toàn bộ team trên.
- Các file agent cũ mang assumption từ project khác không còn là source of truth cho Lending.
