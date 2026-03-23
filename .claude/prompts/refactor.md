# Refactor Prompt

Use this prompt when refactoring existing code.

## Usage

```
@.claude/prompts/refactor.md

Refactor [file/module] to [goal]
```

## Prompt Template

---

**Target**: [File or module to refactor]
**Goal**: [What improvement to achieve]

**Refactoring Types**:
- **Extract**: Split large functions/classes
- **Rename**: Improve naming clarity
- **Move**: Relocate to correct layer/module
- **Simplify**: Reduce complexity
- **Consolidate**: Merge duplicates
- **Cleanup**: Remove dead code

**Safety Checklist**:
- [ ] Understand existing code fully
- [ ] Existing tests pass before refactoring
- [ ] Make small, incremental changes
- [ ] Run tests after each change
- [ ] No behavior changes (unless intentional)

**Code Smells to Address**:
- Functions > 50 lines
- Files > 800 lines
- Deep nesting > 4 levels
- Duplicate code
- Magic numbers
- God classes
- Long parameter lists

**Architecture Violations to Fix**:
- Domain importing infrastructure
- Application importing presentation
- Business logic in controllers
- Database queries in domain layer

---

## Example

```
@.claude/prompts/refactor.md
@.claude/agents/refactor-cleaner.md

Refactor src/application/order/use-cases/create-order.use-case.ts:
- Extract validation logic to separate method
- Move price calculation to domain service
- Reduce function complexity
```
