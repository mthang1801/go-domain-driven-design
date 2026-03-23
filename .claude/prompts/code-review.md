# Code Review Prompt

Use this prompt after writing or modifying code.

## Usage

```
@.claude/prompts/code-review.md

Review the code I just wrote in [file path]
```

## Prompt Template

---

**Context**: I just wrote/modified code and need a review.

**Review Focus**:
1. **Security** - Check for vulnerabilities, hardcoded secrets, injection risks
2. **Architecture** - Verify Clean Architecture boundaries are respected
3. **DDD Compliance** - Ensure proper use of base classes from `libs/src/ddd`
4. **Code Quality** - Check naming, complexity, duplication
5. **Error Handling** - Verify proper exception usage
6. **Tests** - Check if tests exist and are adequate

**Output Format**:
- 🔴 **CRITICAL**: Must fix before commit
- 🟠 **HIGH**: Should fix
- 🟡 **MEDIUM**: Consider fixing
- 🟢 **SUGGESTION**: Nice to have

**For each issue provide**:
- File and line number
- Problem description
- Suggested fix with code example

---

## Example

```
@.claude/prompts/code-review.md
@.claude/agents/code-reviewer.md

Review src/application/order/use-cases/create-order.use-case.ts
```
