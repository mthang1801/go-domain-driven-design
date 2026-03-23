# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, perf, ci

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

## Feature Implementation Workflow

### 1. Plan First
- **Cursor**: `@.claude/agents/planner.md` to create implementation plan
- **Claude Code**: `Task: Use planner agent`
- Identify dependencies and risks
- Break down into phases

### 2. TDD Approach
- **Cursor**: `@.claude/agents/tdd-guide.md`
- **Claude Code**: `Task: Use tdd-guide agent`
- Write tests first (RED)
- Implement to pass tests (GREEN)
- Refactor (IMPROVE)
- Verify 80%+ coverage

### 3. Code Review
- **Cursor**: `@.claude/agents/code-reviewer.md`
- **Claude Code**: `Task: Use code-reviewer agent`
- Address CRITICAL and HIGH issues
- Fix MEDIUM issues when possible

### 4. Before Commit
```bash
pnpm format && pnpm lint && pnpm test
```

### 5. Commit & Push
- Detailed commit messages
- Follow conventional commits format
- Small, atomic commits preferred
