# Write Test Prompt

Use this prompt when you need to write tests for a feature or fix.

## Usage

```
@.claude/prompts/write-test.md

Write tests for [feature/file]
```

## Prompt Template

---

**Context**: I need tests for the following code/feature.

**Test Requirements**:
1. **TDD Approach** - Write tests FIRST if implementing new feature
2. **Coverage Target** - Minimum 80% coverage
3. **Test Types**:
   - Unit tests for functions/utilities
   - Integration tests for use-cases/APIs
   - E2E tests for critical flows

**Test Structure** (AAA Pattern):
```typescript
describe('FeatureName', () => {
  it('should [expected behavior] when [condition]', async () => {
    // Arrange - setup test data
    // Act - execute the code
    // Assert - verify results
  });
});
```

**Edge Cases to Cover**:
- [ ] Null/undefined inputs
- [ ] Empty arrays/strings
- [ ] Invalid types
- [ ] Boundary values (min/max)
- [ ] Error conditions
- [ ] Concurrent operations

**Mocking**:
- Mock external dependencies (HTTP, Database, Redis)
- Use `jest.mock()` or `jest.spyOn()`
- Don't mock the unit under test

---

## Example

```
@.claude/prompts/write-test.md
@.claude/skills/tdd-workflow/SKILL.md

Write unit tests for CreateOrderUseCase covering:
- Valid order creation
- Invalid product ID
- Insufficient stock
- Payment failure
```
