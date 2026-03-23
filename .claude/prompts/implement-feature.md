# Implement Feature Prompt

Use this prompt when implementing a new feature.

## Usage

```
@.claude/prompts/implement-feature.md

Implement [feature description]
```

## Prompt Template

---

**Feature**: [Brief description]

**Workflow**:
1. **Plan** - Break down into tasks
2. **Design** - Identify affected layers and files
3. **Test First** - Write failing tests
4. **Implement** - Make tests pass
5. **Refactor** - Clean up code
6. **Review** - Self-review before commit

**Architecture Checklist**:
- [ ] Domain layer: Entities, Value Objects, Events, Repository Interface
- [ ] Application layer: Use-case (extends BaseCommand/BaseQuery)
- [ ] Infrastructure layer: Repository implementation, Event handlers
- [ ] Presentation layer: Controller, DTOs

**Files to Create/Modify**:
```
src/domain/{module}/
  └── entities/{entity}.entity.ts
  └── value-objects/{vo}.vo.ts
  └── events/{event}.event.ts
  └── repositories/{repo}.repository.interface.ts

src/application/{module}/
  └── use-cases/{action}.use-case.ts

src/infrastructure/{module}/
  └── repositories/{repo}.repository.ts
  └── entities/{entity}.orm.entity.ts

src/presentation/portal/{module}/
  └── controllers/{module}.controller.ts
  └── dtos/{action}.dto.ts
```

**Before Commit**:
```bash
pnpm format && pnpm lint && pnpm test
```

---

## Example

```
@.claude/prompts/implement-feature.md
@.claude/agents/planner.md
@.claude/agents/architecture.md

Implement "Create Product" feature with:
- Product entity with name, price, SKU
- CreateProductUseCase
- REST endpoint POST /products
- Validation for all fields
```
