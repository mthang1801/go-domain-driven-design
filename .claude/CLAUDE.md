# .claude — Claude Code Agent Instructions

> **Entry point** cho Claude Code. File này tương đương với `.claude/AGENTS.md`.
> Toàn bộ tài nguyên (agents, skills, rules, contexts, workflows, specs) năm trong `.claude/` — tham chiếu khi gọi bất kỳ agent nào.

---

## Universal Safety Rules

- **NO AUTO-COMMIT**: Agent MUST NOT perform `git commit` or `git push` autonomously. This task is reserved for the User unless explicitly ordered.
- **NO AUTO-PUBLISH**: Agent MUST NOT perform `npm publish` or trigger automated releases/deployments autonomously.
- **SKILL PREREQUISITE**: If a task maps to a skill, you **MUST** verify the skill folder exists in `.claude/skills/`. If missing:
    - **Fallback**: If you cannot install or find it, **STOP** and ask the user. **DO NOT** attempt manual generation blindly without the skill.
- **USER CONFIRMATION**: For destructive actions or public releases, always request explicit User approval first.

### Restricted Commands (REQUIRE USER CONFIRMATION)

The following commands are classified by risk level. You **MUST NOT** execute them without explicit user confirmation/approval in the chat.

#### GROUP 1 – EXTREMELY DANGEROUS

- `rm -rf`, `rm -r`, `rm`, `unlink`, `shred`, `wipe`

#### GROUP 2 – HIGH DANGER

- `rmdir`, `cp --remove-destination`

#### GROUP 4 – INDIRECT DANGER

- `mv`, `install`

---

## Core Workflow

### Step 1 — Đọc Context Trước Khi Làm

Trước khi tạo hoặc sửa bất cứ thứ gì, Agent **PHẢI** đọc:

```text
docs/plan/progress.md            — Tiến độ tổng thể + backlog (BẮT BUỘC ĐỌC)
changelogs/CHANGELOG.md          — Change history, known issues
.claude/agents/architecture.md   — Kiến trúc tổng thể, folder rules
.claude/rules.md                 — Coding rules & dependencies
libs/src/ddd/                    — Base classes DDD
docs/README.md                   — Cấu trúc tài liệu
```

> ⚠️ Agent PHẢI đọc `docs/plan/progress.md` và `CHANGELOG.md` trước khi bắt đầu bất kỳ planning hoặc execution nào
> để nắm tiến độ tổng thể, biết module nào đang ở phase nào, và backlog còn gì.

### Step 2 — Scaffold Change

Tạo proposal trước khi implement:

```text
changelogs/changes/<slug>/
├── proposal.md    — Mô tả thay đổi, lý do, impact
├── tasks.md       — Danh sách tasks phân rã theo layer + skill
└── design.md      — (Optional) Diagram Mermaid, data flow

.claude/specs/<slug>/
└── <feature>.spec.md  — Delta specs (KHÔNG đặt trong changes/)
```

### Step 3 — Refine Specs

- Update delta specs in `.claude/specs/<slug>/`
- Never modify source-of-truth specs directly without merging.

```markdown
## ADDED Requirements

- ...

## MODIFIED Requirements

- ...

## REMOVED Requirements

- ...
```

### Step 4 — Approval

- Wait for user: "Specs approved."

> Agent **KHÔNG** được viết code trước khi nhận được "Specs approved." từ User.

### Step 5 — Implementation

**CRITICAL: When implementing tasks, ALWAYS use Skills system:**

1. **Read task line** to identify skill:

    ```markdown
    ## 1. Domain Layer – View Entity (projectType: nestjs, skill: ddd-domain)

    - [ ] 1.1 Create View entity and value objects
    ```

2. **Find skill folder**:
    - Check available skills listed at the beginning of the prompt.
    - Project-specific: `.claude/skills/<skill-name>/` (e.g., `use-case-layer`, `backend-patterns-skill`, `frontend-design`)

3. **Read skill.md (SKILL.md)**:
    - Understand purpose, steps, inputs, outputs
    - Follow tone, rules, and limitations

4. **Implement following SKILL.md guidance**:
    - Follow NestJS DDD conventions
    - Use correct naming conventions (PascalCase for classes, camelCase for variables)
    - Apply code style rules
    - Implement error handling according to the `error-handling` skill

**Special case - NestJS Use Case Layer:**

- Task: `(skill: use-case-layer)`
- Agent MUST read `.claude/skills/use-case-layer/SKILL.md`
- Agent MUST extend `BaseCommand` or `BaseQuery`.
- Agent MUST ensure CQRS principles are respected.

**Special case - NestJS Backend Patterns & Database:**

- Task: `(skill: backend-patterns)` or `(skill: supabase-postgres-best-practices)`
- Agent MUST read `.claude/skills/backend-patterns-skill/SKILL.md` (and `.claude/skills/supabase-postgres-best-practices/SKILL.md` when designing data schemas).
- Provide solid architecture optimizations, secure endpoints, properly indexed tables following Supabase best practices (indexing, no loops).

**Special case - Frontend Development & Design:**

- Task: `(skill: vercel-react-best-practices)`, `(skill: server-side-render)`, `(skill: frontend-design)`, `(skill: ui-ux-pro-max)`, or `(skill: web-design-guidelines)`
- Agent MUST read `.claude/skills/vercel-react-best-practices/SKILL.md` for primary React/Next.js architecture. If working on backend-embedded views via NestJS, read `.claude/skills/server-side-render/SKILL.md`.
- Read `.claude/skills/frontend-design/SKILL.md` or `.claude/skills/ui-ux-pro-max/SKILL.md` when defining CSS and interactions.
- Priority is a **Dedicated React/Next.js Frontend** obeying Vercel best practices.
- Implement authentic design principles; avoid generic UI AI slop. Ensure components map nicely to `web-design-guidelines`.

### Step 6 — Archive & Update

- **CRITICAL**: Update `docs/plan/progress.md` — cập nhật tiến độ tổng thể sau khi hoàn thành task, fix bug, refactor, hoặc được review. Ghi rõ module nào đã thay đổi, status mới, và backlog nếu có.
- Ensure all tests pass (`npm run test`) and lint checks clear (`npm run lint`).
- Move delta specs into source specs logically.
- Move change folder to archives.

---

## Spec Format

Specs must include:

- `## Meta` section with project type, domain, stack
- `## Summary | Tóm tắt`
- `## Proposed Changes | Các thay đổi đề xuất`
- `## Verification | Xác minh`

## Delta Spec Format

Delta specs use:

- `## ADDED Requirements`
- `## MODIFIED Requirements`
- `## REMOVED Requirements`

## Tasks Format

Tasks grouped by project type and skill:

```markdown
## 1. Data Visualizer module – Runtime Engine (projectType: nestjs, skill: use-case-layer)

- [ ] Task description
```

---

## Skills System

**CRITICAL: Mandatory Prerequisite Check**

1. **Stop & Verify**: Check `.claude/skills/` for the requested skill.
2. **Execute**: Read the `SKILL.md` file before generating code.

### When Change Has Multiple Skills

**Important**: Each task group uses ONE skill. When working on a task group, agent MUST use that skill's `SKILL.md`. Switch skill instructions when switching task groups!

---

## DV Developer Team (`.claude/agents/DV-TEAM.md`)

> **10 specialized agents** built for Data Visualizer. Each bundles relevant skills automatically.
> **Security by Default**: `security-review` is bundled with ALL developer-facing agents.
> Full reference: [`.claude/agents/DV-TEAM.md`](.claude/agents/DV-TEAM.md)

| Agent                    | Role                                           | Skills        |
| ------------------------ | ---------------------------------------------- | ------------- |
| `dv-backend-developer`   | NestJS DDD — entities, use-cases, repositories | 11 skills     |
| `dv-code-reviewer`       | Comprehensive code review — all patterns       | ALL 17 skills |
| `dv-refactor-specialist` | Safe refactoring with patterns                 | 2 skills      |
| `dv-debugger`            | Bug fixing, log analysis, error tracing        | 4 skills      |
| `dv-frontend-developer`  | React/Next.js — Metabase design system         | 3 skills      |
| `dv-test-writer`         | TDD — unit, integration, E2E tests             | 4 skills      |
| `dv-db-optimizer`        | Query optimization, indexes, schema design     | 5 skills      |

### DV Agent Trigger Matrix

| Task                                             | Use Agent                |
| ------------------------------------------------ | ------------------------ |
| Domain entity / use-case / repository / APIs     | `dv-backend-developer`   |
| React component / Next.js page / UI              | `dv-frontend-developer`  |
| Server won't start / DI error / TypeScript error | `dv-debugger`            |
| Slow query / N+1 / schema design                 | `dv-db-optimizer`        |
| Before PR / "review code"                        | `dv-code-reviewer`       |
| Code smells / pattern migration                  | `dv-refactor-specialist` |
| Write tests / TDD / coverage                     | `dv-test-writer`         |

**Invocation:**

```
Task: Use dv-backend-developer agent from .claude/agents/dv-backend-developer.md to create SqlSnippet entity
Task: Use dv-code-reviewer agent from .claude/agents/dv-code-reviewer.md to review recent changes
Task: Use dv-debugger agent from .claude/agents/dv-debugger.md to fix DI error in logs module
```

---

## Foundation Agents (`.claude/agents/`)

General-purpose agents for cross-cutting concerns:

| Agent                      | Purpose                          | File                                         |
| -------------------------- | -------------------------------- | -------------------------------------------- |
| `architecture`             | Kiến trúc tổng thể, folder rules | `.claude/agents/architecture.md`             |
| `planner`                  | Implementation planning          | `.claude/agents/planner.md`                  |
| `tdd-guide`                | Test-driven development          | `.claude/agents/tdd-guide.md`                |
| `code-reviewer`            | Code review                      | `.claude/agents/code-reviewer.md`            |
| `security-reviewer`        | Security analysis                | `.claude/agents/security-reviewer.md`        |
| `e2e-runner`               | E2E testing                      | `.claude/agents/e2e-runner.md`               |
| `refactor-cleaner`         | Dead code cleanup                | `.claude/agents/refactor-cleaner.md`         |
| `doc-updater`              | Documentation                    | `.claude/agents/doc-updater.md`              |
| `circuit-breaker`          | Resilience patterns              | `.claude/agents/circuit-breaker.md`          |
| `class-classification`     | Class organization               | `.claude/agents/class-classification.md`     |
| `solid`                    | SOLID principles                 | `.claude/agents/solid.md`                    |
| `flow`                     | Flow control                     | `.claude/agents/flow.md`                     |
| `scope`                    | Scope management                 | `.claude/agents/scope.md`                    |
| `summary`                  | Summarization                    | `.claude/agents/summary.md`                  |
| `import-export-file-guide` | Import/export patterns           | `.claude/agents/import-export-file-guide.md` |

---

## Available Skills (`.claude/skills/`)

| Skill                              | Purpose                               | Path                                                       |
| ---------------------------------- | ------------------------------------- | ---------------------------------------------------------- |
| `coding-standards`                 | Universal best practices              | `.claude/skills/coding-standards/SKILL.md`                 |
| `tdd-workflow`                     | Test-driven development               | `.claude/skills/tdd-workflow/SKILL.md`                     |
| `nestjs-config`                    | Configuration management              | `.claude/skills/nestjs-config/SKILL.md`                    |
| `database`                         | Persistence, queries, transactions    | `.claude/skills/database/SKILL.md`                         |
| `redis`                            | Cache, streams                        | `.claude/skills/redis/SKILL.md`                            |
| `microservices`                    | Event bus, config, subscribe patterns | `.claude/skills/microservices/SKILL.md`                    |
| `backend-patterns-skill`           | API, repository, service patterns     | `.claude/skills/backend-patterns-skill/SKILL.md`           |
| `error-handling`                   | Exception handling                    | `.claude/skills/error-handling/SKILL.md`                   |
| `security-review`                  | Security analysis                     | `.claude/skills/security-review/SKILL.md`                  |
| `eval-harness`                     | Evaluation patterns                   | `.claude/skills/eval-harness/SKILL.md`                     |
| `find-skills`                      | Skill discovery                       | `.claude/skills/find-skills/SKILL.md`                      |
| `frontend-design`                  | React, UI patterns                    | `.claude/skills/frontend-design/SKILL.md`                  |
| `vercel-react-best-practices`      | React/Next.js architecture            | `.claude/skills/vercel-react-best-practices/SKILL.md`      |
| `server-side-render`               | SSR via NestJS                        | `.claude/skills/server-side-render/SKILL.md`               |
| `ui-ux-pro-max`                    | CSS, interactions, design             | `.claude/skills/ui-ux-pro-max/SKILL.md`                    |
| `web-design-guidelines`            | Design guidelines                     | `.claude/skills/web-design-guidelines/SKILL.md`            |
| `design-md`                        | Design documentation                  | `.claude/skills/design-md/SKILL.md`                        |
| `strategic-compact`                | Strategic design                      | `.claude/skills/strategic-compact/SKILL.md`                |
| `skill-creator`                    | Creating new skills                   | `.claude/skills/skill-creator/SKILL.md`                    |
| `continuous-learning`              | Pattern extraction from sessions      | `.claude/skills/continuous-learning/SKILL.md`              |
| `supabase-postgres-best-practices` | Supabase/Postgres patterns            | `.claude/skills/supabase-postgres-best-practices/SKILL.md` |
| `use-case-layer`                   | Use case / CQRS layer                 | `.claude/skills/use-case-layer/SKILL.md`                   |
| `saga`                             | Saga pattern                          | `.claude/skills/saga/SKILL.md`                             |
| `idempotency-key`                  | Idempotency patterns                  | `.claude/skills/idempotency-key/SKILL.md`                  |
| `stream-pipeline`                  | Stream processing                     | `.claude/skills/stream-pipeline/SKILL.md`                  |
| `ROUTER_MODULE_GUIDE`              | Router module guide                   | `.claude/skills/ROUTER_MODULE_GUIDE/SKILL.md`              |
| `agent-browser`                    | Browser automation                    | `.claude/skills/agent-browser/SKILL.md`                    |
| `agent-tools`                      | Agent tool usage                      | `.claude/skills/agent-tools/SKILL.md`                      |
| `ai-image-generation`              | AI image generation                   | `.claude/skills/ai-image-generation/SKILL.md`              |
| `nano-banana`                      | Nano banana patterns                  | `.claude/skills/nano-banana/SKILL.md`                      |
| `nano-banana-2`                    | Nano banana 2 patterns                | `.claude/skills/nano-banana-2/SKILL.md`                    |
| `project-guideline-examples`       | Project organization                  | `.claude/skills/project-guideline-examples/SKILL.md`       |

---

## Contexts (`.claude/contexts/`)

| Context       | Mode        | Focus                              |
| ------------- | ----------- | ---------------------------------- |
| `dev.md`      | Development | Code first, explain after          |
| `research.md` | Research    | Explore before acting              |
| `review.md`   | Review      | Quality, security, maintainability |

**Switch behavior:** Reference `.claude/contexts/dev.md` when implementing, `.claude/contexts/review.md` when reviewing.

---

## Prompts (`.claude/prompts/`)

| Prompt                 | Purpose                |
| ---------------------- | ---------------------- |
| `add-use-case.md`      | Adding use case        |
| `code-review.md`       | Code review workflow   |
| `create-feature.md`    | Feature creation       |
| `debug.md`             | Debugging approach     |
| `implement-feature.md` | Feature implementation |
| `refactor.md`          | Refactoring workflow   |
| `security-check.md`    | Security review        |
| `write-test.md`        | Test writing guide     |

**Use as template:** Read `.claude/prompts/implement-feature.md` before implementing new features.

---

## Rules (`.claude/rules/`)

| Rule                  | Purpose                                           |
| --------------------- | ------------------------------------------------- |
| `agents.md`           | Agent orchestration, when to use which            |
| `code-style-guide.md` | Code formatting, ESLint, Prettier                 |
| `git-workflow.md`     | Commit format, PR workflow                        |
| `hooks.md`            | Claude Code hooks (PreToolUse, PostToolUse, Stop) |
| `security.md`         | Security guidelines                               |
| `testing.md`          | Testing requirements                              |
| `performance.md`      | Performance tips                                  |
| `async-*.md`          | Async patterns                                    |
| `bundle-*.md`         | Bundle optimization                               |
| `rendering-*.md`      | Rendering patterns                                |
| `rerender-*.md`       | Re-render optimization                            |
| `server-*.md`         | Server-side patterns                              |

---

## Workflows (`.claude/workflows/`)

| Workflow            | Purpose                   |
| ------------------- | ------------------------- |
| `agentic-team.md`   | Full agentic team SDLC    |
| `debugging.md`      | Debugging workflow        |
| `new-feature.md`    | New feature development   |
| `orchestration.md`  | Agent orchestration       |
| `pr-describer.md`   | PR description generation |
| `test-generator.md` | Test generation           |

---

## Specs (`.claude/specs/`)

Product specs phân chia theo feature:

| Spec                             | Nội dung                 |
| -------------------------------- | ------------------------ |
| `01-core-foundation.md`          | Core foundation          |
| `02-schema-discovery.md`         | Schema discovery         |
| `03-visual-query-builder.md`     | Visual query builder     |
| `04-runtime-engine.md`           | Runtime engine           |
| `05-security-permissions.md`     | Security & permissions   |
| `06-data-import-pipeline.md`     | Data import pipeline     |
| `07-ai-agent-integration.md`     | AI agent integration     |
| `08-ui-ux-standards.md`          | UI/UX standards          |
| `09-performance-optimization.md` | Performance optimization |
| `10-notifications.md`            | Notifications            |
| `11-testing-and-deployment.md`   | Testing & deployment     |
| `12-data-visualizer-studio.md`   | Data visualizer studio   |

---

## Agentic Team Ecosystem

The project features a full ecosystem of 10 specialized AI Agents. Their specific interactions throughout the SDLC are defined in:

- [Agentic Team Workflow](.claude/workflows/agentic-team.md)

### DV-ORCHESTRATOR — Điều Phối Agent

> **CRITICAL**: Khi nhận task phức tạp từ user, Agent NÊN tham chiếu [DV-ORCHESTRATOR](.claude/agents/DV-ORCHESTRATOR.md) để xác định agent nào cần gọi và thứ tự thực thi.

**Quy trình orchestration:**

```text
1. Đọc .claude/agents/DV-ORCHESTRATOR.md
2. Áp dụng quy tắc chọn agent (priority-based)
3. Nhận YAML plan:
   plan:
     - agent: <tên-agent>
       file: .claude/agents/<tên-agent>.md
       task: "<mô tả task cụ thể>"
       next_if_ok: <agent-tiếp-theo | review>
4. Thực thi tuần tự:
   - Đọc file .md của agent được chọn
   - Thực hiện task
   - Nếu next_if_ok → chuyển sang agent tiếp
   - Nếu lỗi → dừng, báo user
5. Nếu plan: [] + clarify → hỏi user trước khi làm
```

**Khi nào dùng:**

- Task phức tạp, cross-layer (domain + API + frontend)
- Không chắc nên dùng agent nào
- Muốn đảm bảo thứ tự thực thi đúng (ví dụ: backend trước, API sau, review cuối)

**Agents Overview**:

- **Onboarding / Wiki-AI**: Documentation, orientation, architecture guidance via RAG.
- **PR Describer / Code Reviewer / Security Scanner / DB Migration**: PR validation, generation of commit descriptions, standard compliance, secure reviews.
- **Test / Doc Generators**: Automated test coverage and robust multi-level documentation.
- **Monitoring / Incident Agents**: Observability, realtime analysis, fault mitigation.

---

## Claude Code Specific

### Hooks Configuration

Configure in `~/.claude/settings.json`. See `.claude/settings.example.json` for reference.

```json
{
    "hooks": {
        "PreToolUse": [],
        "PostToolUse": [],
        "Stop": [
            {
                "matcher": "*",
                "hooks": [
                    {
                        "type": "command",
                        "command": ".claude/skills/continuous-learning/evaluate-session.sh"
                    }
                ]
            }
        ]
    }
}
```

### Continuous Learning (`.claude/skills/continuous-learning/`)

Claude Code only — automatically extracts reusable patterns from sessions.
See `.claude/skills/continuous-learning/SKILL.md` for configuration.

---

## Quick Commands

```bash
# Development
pnpm start:dev
pnpm test
pnpm test:cov
pnpm lint
pnpm format

# Build
pnpm build
pnpm start:prod

# Before commit
pnpm format && pnpm lint && pnpm test
```

---

## Summary

| Resource            | Location                              | Usage                                         |
| ------------------- | ------------------------------------- | --------------------------------------------- |
| Agents              | `.claude/agents/`                     | Task: Use X agent from .claude/agents/X.md    |
| Skills              | `.claude/skills/`                     | Task: Follow X from .claude/skills/X/SKILL.md |
| Contexts            | `.claude/contexts/`                   | Reference for mode switching                  |
| Prompts             | `.claude/prompts/`                    | Template for task types                       |
| Rules               | `.claude/rules/`                      | Reference for guidelines                      |
| Specs               | `.claude/specs/`                      | Product specifications                        |
| Workflows           | `.claude/workflows/`                  | SDLC workflows                                |
| Changes             | `changelogs/changes/`                 | Active change proposals                       |
| Hooks               | `~/.claude/settings.json`             | Automation                                    |
| Continuous Learning | `.claude/skills/continuous-learning/` | Claude only                                   |
