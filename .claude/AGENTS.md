# .claude — AI Agent Instructions

This document defines the workflow for AI agents working with the Data Visualizer project under `.claude`.

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

## Core Workflow

### Step 1 — Đọc Context Trước Khi Làm

Trước khi tạo hoặc sửa bất cứ thứ gì, Agent **PHẢI** đọc theo thứ tự ưu tiên:

#### 1a. Nắm tiến độ & context hiện tại (BẮT BUỘC ĐỌC ĐẦU TIÊN)

```text
docs/plan/progress.md               — Progress tracker
changelogs/CHANGELOG.md             — Index: progress, change history, known issues
changelogs/changes/                 — Chi tiết từng thay đổi (README.md, tasks, evidence)
changelogs/ERROR_LOG.md             — Error log & lessons learned
changelogs/API_MAP.md               — API endpoint map (9 modules)
```

> ⚠️ **Đây là bước quan trọng nhất.** Agent PHẢI đọc `CHANGELOG.md` (metadata index)
> và `docs/plan/progress.md` (tiến độ tổng thể + backlog) trước khi bắt đầu bất kỳ planning hoặc execution nào để:
>
> - Nắm tiến độ tổng thể từ `progress.md` — biết module nào đang ở phase nào, backlog còn gì
> - Tránh lặp lại công việc đã làm
> - Nắm known issues và lessons learned (xem `ERROR_LOG.md`)
> - Xác định task tiếp theo theo thứ tự ưu tiên

#### 1b. Đọc documentation để hiểu kiến trúc & module specs

```text
docs/                            — Documentation tổng thể project
docs/architecture/README.md      — Architecture overview, module map, tech stack
docs/modules/                    — Module specifications chi tiết (10 modules)
docs/architecture/design-philosophy.md — UI/UX design philosophy
docs/agent-access.md             — URLs, credentials, automation patterns
```

#### 1c. Đọc technical context

```text
.claude/agents/architecture.md   — Kiến trúc tổng thể, folder rules
.claude/rules.md                 — Coding rules & dependencies
libs/src/ddd/                    — Base classes DDD
docs/README.md                   — Cấu trúc tài liệu
```

### Step 2 — Scaffold Change

Tạo proposal trước khi implement:

```text
changelogs/changes/<slug>/
├── proposal.md    — Mô tả thay đổi, lý do, impact
├── tasks.md       — Danh sách tasks phân rã theo layer + skill
├── design.md      — (Optional) Diagram Mermaid, data flow
└── evidence/      — Thư mục lưu trữ hình ảnh, video minh hoạ kết quả

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
- Agent MUST read `.claude/skills/backend-patterns-skill/SKILL.md and EXAMPLE.md` (and `.claude/skills/supabase-postgres-best-practices/SKILL.md` when designing data schemas).
- Provide solid architecture optimizations, secure endpoints, properly indexed tables following Supabase best practices (indexing, no loops).

**Special case - Frontend Development & Design:**

- Task: `(skill: vercel-react-best-practices)`, `(skill: server-side-render)`, `(skill: frontend-design)`, `(skill: ui-ux-pro-max)`, or `(skill: web-design-guidelines)`
- Agent MUST read `.claude/skills/vercel-react-best-practices/SKILL.md` for primary React/Next.js architecture. If working on backend-embedded views via NestJS, read `.claude/skills/server-side-render/SKILL.md`.
- Read `.claude/skills/frontend-design/SKILL.md` or `.claude/skills/ui-ux-pro-max/SKILL.md` when defining CSS and interactions.
- Priority is a **Dedicated React/Next.js Frontend** obeying Vercel best practices.
- Implement authentic design principles; avoid generic UI AI slop. Ensure components map nicely to `web-design-guidelines`.

### Step 6 — Archive & Update

- **CRITICAL**: Update `changelogs/CHANGELOG.md` with a new entry detailing the completed work, broken down by specific module and code branch.
- **CRITICAL**: Update `docs/plan/progress.md` — cập nhật tiến độ tổng thể sau khi hoàn thành task, fix bug, refactor, hoặc được review. Ghi rõ module nào đã thay đổi, status mới, và backlog nếu có.
- **CRITICAL**: Update the `changelogs/changes/` directory to reflect the completion of the task (e.g., closing tasks, updating statuses). And structure of folder must be:
    - `tasks.md` (include checklist task)
    - `proposal.md` (include plan/ solution)
    - `evidence/` (include screenshots/videos)
    - `README.md` (optional - to summarize if needed)
    - **CRITICAL**: Do not use any other structure (e.g., only README.md or wrong file names).
- **CRITICAL**: After updating changelog/changes, **capture and SAVE visual evidence** of the completed work:
    - **Save Locally**: Create an `evidence/` folder inside your current `changelogs/changes/<slug>/` directory and save all media files there.
    - **Screenshots**: Capture browser screenshots showing the UI/feature in its final state and save them to the `evidence/` folder.
    - **Video playback**: Record a browser session demonstrating the feature workflow and save the video to the `evidence/` folder.
    - **Attach**: Embed these local file links into the changelog entry or walkthrough artifact so reviewers can persistently verify them without running the app.
- Ensure all tests pass (`npm run test`) and lint checks clear (`npm run lint`).
- Move delta specs into source specs logically.
- Move change folder to archives.

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

## Skills System

**CRITICAL: Mandatory Prerequisite Check**

1. **Stop & Verify**: Check `.claude/skills/` for the requested skill.
2. **Execute**: Read the `SKILL.md` file before generating code.

### When Change Has Multiple Skills

**Important**: Each task group uses ONE skill. When working on a task group, agent MUST use that skill's `SKILL.md`. Switch skill instructions when switching task groups!

## Agentic Team Ecosystem

See [DV Agent Team](agents/DV-TEAM.md) for the full specialized developer team.

The project features a full ecosystem of 10+ specialized AI Agents. Their specific interactions throughout the SDLC are defined in:

- [Agentic Team Workflow](workflows/agentic-team.md)
- [DV Developer Team](agents/DV-TEAM.md)

### DV-ORCHESTRATOR — Điều Phối Agent

> **CRITICAL**: Khi nhận task phức tạp từ user, Agent NÊN tham chiếu [DV-ORCHESTRATOR](agents/DV-ORCHESTRATOR.md) để xác định agent nào cần gọi và thứ tự thực thi.

**Quy trình orchestration:**

```text
1. Đọc agents/DV-ORCHESTRATOR.md
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
