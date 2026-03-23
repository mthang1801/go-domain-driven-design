# AI Assistant Configuration

This folder contains configuration for AI-powered development assistants (Cursor IDE + Claude Code).

## Platform Support

| Platform        | Entry Point         | Hooks | Agents            | Skills            |
| --------------- | ------------------- | ----- | ----------------- | ----------------- |
| **Cursor**      | `rules.md`          | No    | Via `@` reference | Via `@` reference |
| **Claude Code** | `.claude/AGENTS.md` | Yes   | Via Task tool     | Via Task tool     |

## Directory Structure

```
project-root/
├── rules.md              # Cursor IDE main config
├── .claude/
│   ├── agents/               # Agent definitions (shared)
│   ├── contexts/             # Context modes
│   ├── prompts/              # Pre-defined prompts (Cursor)
│   ├── rules/                # Rule files
│   ├── skills/               # Skill guides (shared)
│   └── README.md             # This file
│   ├── AGENTS.md             # Claude Code / Codex session instructions
│   ├── hooks/                # Hook scripts used by the active setup
│   └── skills/
│       └── continuous-learning/  # Claude Code only skills
```

## Usage

### Cursor IDE

1. **Automatic Loading**: `rules.md` is loaded automatically
2. **Reference Agents**: Use `@.claude/agents/agent-name.md` in prompts
3. **Reference Skills**: Use `@.claude/skills/skill-name/SKILL.md` in prompts
4. **Use Prompts**: Use `@.claude/prompts/prompt-name.md` for common tasks

Example:

```
@.claude/agents/dv-code-reviewer.md
@.claude/prompts/code-review.md

Review the changes in src/application/sql-editor/
```

### Claude Code

1. **Automatic Loading**: `.claude/AGENTS.md` is loaded automatically
2. **Invoke Agents**: Use Task tool
3. **Hook scripts**: Review `.claude/hooks/README.md` and `.claude/hooks/settings-hooks.json` for the current hook configuration

Example:

```bash
Task: Use dv-backend-developer agent from .claude/agents/dv-backend-developer.md to create SqlSnippet entity
Task: Use dv-code-reviewer agent from .claude/agents/dv-code-reviewer.md to review recent changes
Task: Use dv-debugger agent from .claude/agents/dv-debugger.md to fix the DI error
```

---

## DV Developer Team (10 Agents)

> **Security by Default**: `security-review` skill is bundled with ALL developer-facing agents.
> Full reference: [`agents/DV-TEAM.md`](agents/DV-TEAM.md)

| Agent                    | Role                                           | Skills Bundled |
| ------------------------ | ---------------------------------------------- | -------------- |
| `dv-backend-developer`   | NestJS DDD — entities, use-cases, repositories | 11 skills      |
| `dv-code-reviewer`       | Comprehensive code review — all patterns       | ALL 17 skills  |
| `dv-refactor-specialist` | Safe refactoring with patterns                 | 2 skills       |
| `dv-debugger`            | Bug fixing, log analysis, error tracing        | 4 skills       |
| `dv-frontend-developer`  | React/Next.js — Metabase design system         | 3 skills       |
| `dv-test-writer`         | TDD — unit, integration, E2E tests             | 4 skills       |
| `dv-db-optimizer`        | Query optimization, indexes, schema design     | 5 skills       |

### Trigger Matrix

| Task                                             | Use Agent                |
| ------------------------------------------------ | ------------------------ |
| Domain entity / use-case / repository / APIs     | `dv-backend-developer`   |
| React component / Next.js page / UI              | `dv-frontend-developer`  |
| Server won't start / DI error / TypeScript error | `dv-debugger`            |
| Slow query / N+1 / schema design                 | `dv-db-optimizer`        |
| Before PR / "review code"                        | `dv-code-reviewer`       |
| Code smells / pattern migration                  | `dv-refactor-specialist` |
| Write tests / TDD / coverage                     | `dv-test-writer`         |

---

## Foundation Agents

General-purpose agents for cross-cutting concerns:

| Agent               | Purpose                        | File                          |
| ------------------- | ------------------------------ | ----------------------------- |
| `architecture`      | System design, layer decisions | `agents/architecture.md`      |
| `planner`           | Feature planning               | `agents/planner.md`           |
| `code-reviewer`     | Code review after changes      | `agents/code-reviewer.md`     |
| `tdd-guide`         | Test-driven development        | `agents/tdd-guide.md`         |
| `refactor-cleaner`  | Dead code cleanup              | `agents/refactor-cleaner.md`  |
| `security-reviewer` | Security analysis              | `agents/security-reviewer.md` |
| `e2e-runner`        | E2E testing                    | `agents/e2e-runner.md`        |
| `doc-updater`       | Documentation                  | `agents/doc-updater.md`       |
| `circuit-breaker`   | Resilience patterns            | `agents/circuit-breaker.md`   |

---

## Skills

| Skill                              | Purpose                               | Location                                                      |
| ---------------------------------- | ------------------------------------- | ------------------------------------------------------------- |
| `coding-standards`                 | Universal best practices              | `skills/coding-standards/`                                    |
| `tdd-workflow`                     | Test-driven development               | `skills/tdd-workflow/`                                        |
| `use-case-layer`                   | BaseCommand / BaseQuery CQRS layer    | `skills/use-case-layer/`                                      |
| `backend-patterns-skill`           | API, repository, service patterns     | `skills/backend-patterns-skill/` (Read SKILL.md & EXAMPLE.md) |
| `database`                         | Persistence, queries, transactions    | `skills/database/`                                            |
| `supabase-postgres-best-practices` | Postgres optimization, indexing       | `skills/supabase-postgres-best-practices/`                    |
| `error-handling`                   | Exception handling                    | `skills/error-handling/`                                      |
| `security-review`                  | Security analysis                     | `skills/security-review/`                                     |
| `redis`                            | Cache, streams                        | `skills/redis/`                                               |
| `microservices`                    | Event bus, subscribe patterns         | `skills/microservices/`                                       |
| `stream-pipeline`                  | Stream processing, big data           | `skills/stream-pipeline/`                                     |
| `idempotency-key`                  | Idempotency patterns                  | `skills/idempotency-key/`                                     |
| `saga`                             | Saga orchestration pattern            | `skills/saga/`                                                |
| `nestjs-config`                    | Configuration management              | `skills/nestjs-config/`                                       |
| `vercel-react-best-practices`      | React/Next.js architecture            | `skills/vercel-react-best-practices/`                         |
| `frontend-design`                  | React, UI patterns                    | `skills/frontend-design/`                                     |
| `ui-ux-pro-max`                    | CSS, interactions, design             | `skills/ui-ux-pro-max/`                                       |
| `web-design-guidelines`            | Design guidelines, accessibility      | `skills/web-design-guidelines/`                               |
| `server-side-render`               | SSR via NestJS                        | `skills/server-side-render/`                                  |
| `continuous-learning`              | Auto pattern extraction (Claude only) | `.claude/skills/continuous-learning/`                         |

---

## Rules

> See [`rules/README.md`](rules/README.md) for categorized index (load by context — backend vs frontend).

| Rule                  | Purpose                | Load When   |
| --------------------- | ---------------------- | ----------- |
| `code-style-guide.md` | Code formatting        | Always      |
| `security.md`         | Security guidelines    | Always      |
| `testing.md`          | Testing requirements   | Always      |
| `git-workflow.md`     | Git conventions        | Always      |
| `agents.md`           | Agent orchestration    | Reference   |
| `hooks.md`            | Hook configuration     | Claude Code |
| `performance.md`      | Performance tips       | Reference   |
| `async-*.md`          | Async patterns         | Backend     |
| `bundle-*.md`         | Bundle optimization    | Frontend    |
| `rendering-*.md`      | Rendering patterns     | Frontend    |
| `rerender-*.md`       | Re-render optimization | Frontend    |
| `server-*.md`         | Server-side patterns   | Frontend    |

---

## Prompts (Cursor)

| Prompt                 | Purpose                |
| ---------------------- | ---------------------- |
| `code-review.md`       | Code review workflow   |
| `write-test.md`        | Test writing guide     |
| `implement-feature.md` | Feature implementation |
| `refactor.md`          | Refactoring workflow   |
| `debug.md`             | Debugging approach     |
| `security-check.md`    | Security review        |

---

## Contexts

| Context       | Mode        | Focus                              |
| ------------- | ----------- | ---------------------------------- |
| `dev.md`      | Development | Code first, explain after          |
| `research.md` | Research    | Explore before acting              |
| `review.md`   | Review      | Quality, security, maintainability |

---

## Hooks (Claude Code Only)

See `.claude/hooks/README.md` and `.claude/hooks/settings-hooks.json` for the current hook configuration.

- **PreToolUse**: Validation before tool execution
- **PostToolUse**: Auto-format, checks after execution
- **Stop**: Final verification + continuous learning

---

## Best Practices

1. **Use DV agents** — always prefer `dv-*` agents over generic agents for this project
2. **Security by default** — all developer-facing agents bundle `security-review`
3. **Skills before code** — read `SKILL.md` before generating code for any skill
4. **Change proposals** — scaffold in `changelogs/changes/<slug>/` before implementing
5. **Reference, don't duplicate** — use `@` to reference existing docs
