# Debug Prompt

Use this prompt when debugging issues or errors.

## Usage

```
@.claude/prompts/debug.md

Debug: [error message or symptom]
```

## Prompt Template

---

**Issue**: [Error message or unexpected behavior]
**Expected**: [What should happen]
**Actual**: [What is happening]

**Debug Approach**:
1. **Reproduce** - Verify the issue can be reproduced
2. **Isolate** - Narrow down the source
3. **Analyze** - Understand root cause
4. **Fix** - Implement solution
5. **Verify** - Confirm fix works
6. **Test** - Add regression test

**Information to Provide**:
- Full error message and stack trace
- Steps to reproduce
- Relevant code snippets
- Recent changes that might be related
- Environment (local, dev, prod)

**Debug Techniques**:
- Add logging at key points
- Check input/output at each step
- Verify database state
- Check external service responses
- Review recent git commits
- Check dependency versions

**Common Issues in DDD Projects**:
- [ ] Domain event not dispatched
- [ ] Repository mapping error
- [ ] Transaction not committed
- [ ] Circular dependency
- [ ] Missing provider in module
- [ ] Incorrect injection token

---

## Example

```
@.claude/prompts/debug.md

Debug: "Order created but OrderCreatedEvent not firing"

Expected: OrderCreatedEvent should be published after order.create()
Actual: Event handler never receives the event
Recent change: Updated BaseAggregateRoot
```
