# Agent Orchestration

> Agents work on both **Cursor** (via @ reference) and **Claude Code** (via Task tool).

## Available Agents

Located in `.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| `planner` | Implementation planning | Complex features, refactoring |
| `architecture` | System design | Architectural decisions |
| `tdd-guide` | Test-driven development | New features, bug fixes |
| `code-reviewer` | Code review | After writing code |
| `security-reviewer` | Security analysis | Before commits |
| `e2e-runner` | E2E testing | Critical user flows |
| `refactor-cleaner` | Dead code cleanup | Code maintenance |
| `doc-updater` | Documentation | Updating docs |
| `circuit-breaker` | Resilience patterns | External service calls |

## How to Use Agents

### Cursor IDE

Reference agents with `@` in your prompt:

```
@.claude/agents/code-reviewer.md
Review the code I just wrote in src/application/order/

@.claude/agents/tdd-guide.md  
Write tests for CreateOrderUseCase

@.claude/agents/architecture.md
Is my folder structure correct for DDD?
```

### Claude Code

Use the Task tool to invoke agents:

```bash
Task: Use planner agent to plan user authentication feature
Task: Use code-reviewer agent to review recent changes
Task: Use security-reviewer agent before pushing
```

## When to Use Which Agent

| Situation | Agent | Invocation |
|-----------|-------|------------|
| Complex feature requests | `planner` | Automatic or manual |
| Code just written/modified | `code-reviewer` | After changes |
| Bug fix or new feature | `tdd-guide` | Before writing code |
| Architectural decision | `architecture` | Design phase |
| Before commit/push | `security-reviewer` | Security check |
| Critical user flows | `e2e-runner` | E2E testing |

## Parallel Execution (Claude Code)

Use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Task: Agent 1 - Security analysis of auth.ts
Task: Agent 2 - Performance review of cache system  
Task: Agent 3 - Type checking of utils.ts

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker

## Pre-defined Prompts

For common tasks, use prompts in `.claude/prompts/`:

| Prompt | Purpose |
|--------|---------|
| `code-review.md` | Code review workflow |
| `write-test.md` | Test writing guide |
| `implement-feature.md` | Feature implementation |
| `refactor.md` | Refactoring workflow |
| `debug.md` | Debugging approach |
| `security-check.md` | Security review |

Example:
```
@.claude/prompts/code-review.md
@.claude/agents/code-reviewer.md
Review src/application/order/use-cases/create-order.use-case.ts
```
