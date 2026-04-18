# Go Sample Agents Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `examples/go-sample/.agents` as a reusable source-of-truth operating system for Go services and document its principles in `examples/go-sample/README.md`.

**Architecture:** The work is split into focused layers: top-level `.agents` entry docs, generic agent definitions, Go-native skills, reusable workflows/rules/hooks/scripts, and project tracking artifacts. The template is derived from the Nest sample operating model but rewritten around Go Clean Architecture, Gin, GORM/Postgres, constructor injection, `context.Context`, and future Redis/messaging evolution.

**Tech Stack:** Markdown, shell scripts, JSON, Go project conventions, agent/skill documentation.

---

## Chunk 1: Sample Root And Entry Docs

### Task 1: Create `examples/go-sample` root documentation

**Files:**
- Create: `examples/go-sample/README.md`
- Create: `examples/go-sample/.gitignore`

- [ ] **Step 1: Create root README skeleton**

Include sections for overview, architecture principles, folder structure, `.agents` operating model, development workflow, and roadmap.

- [ ] **Step 2: Add Go-specific architectural principles**

Document:
- `Presentation -> Application -> Domain <- Infrastructure`
- role of `cmd/`, `internal/`, `pkg/`
- why `pkg` acts as the platform layer inside this sample
- why `.agents` is the source of truth

- [ ] **Step 3: Add project-local ignore rules**

Add `.superpowers/`, temp artifacts, and other local agent/runtime output paths without changing unrelated repo behavior.

- [ ] **Step 4: Verify docs read cleanly**

Run: `sed -n '1,260p' examples/go-sample/README.md`
Expected: complete README with no placeholders or unfinished sections

### Task 2: Create top-level `.agents` entry docs

**Files:**
- Create: `examples/go-sample/.agents/AGENTS.md`
- Create: `examples/go-sample/.agents/README.md`
- Create: `examples/go-sample/.agents/project.md`
- Create: `examples/go-sample/.agents/rules.md`

- [ ] **Step 1: Write `AGENTS.md` as the main entrypoint**

Include:
- safety rules
- required reading order
- spec-first workflow
- change tracking expectations
- skill prerequisite behavior
- Go-specific implementation expectations

- [ ] **Step 2: Write `.agents/README.md`**

Explain directory structure, generic Go-service intent, and how agents/skills/workflows/rules interact.

- [ ] **Step 3: Write `project.md`**

Describe `examples/go-sample` as the first reference implementation of a reusable Go service template.

- [ ] **Step 4: Write `rules.md`**

Summarize high-level project rules and point to detailed rules under `.agents/rules/`.

- [ ] **Step 5: Verify top-level docs**

Run: `find examples/go-sample/.agents -maxdepth 1 -type f | sort`
Expected: all four entry docs exist

---

## Chunk 2: Generic Agent System

### Task 3: Create generic agent architecture docs

**Files:**
- Create: `examples/go-sample/.agents/agents/README.md`
- Create: `examples/go-sample/.agents/agents/architecture.md`
- Create: `examples/go-sample/.agents/agents/interaction-protocol.md`

- [ ] **Step 1: Write `agents/README.md`**

Document the generic team shape and when to use each specialist.

- [ ] **Step 2: Write `agents/architecture.md`**

Describe the Go service architecture that all agents must honor:
- `cmd/`
- `internal/`
- `pkg/`
- service-local docs/changelogs

- [ ] **Step 3: Write `interaction-protocol.md`**

Define escalation, handoff, review gates, and when agents must stop and ask the user.

- [ ] **Step 4: Verify cross-links**

Run: `rg -n "go-orchestrator|go-backend-developer|clean architecture|context.Context" examples/go-sample/.agents/agents`
Expected: agent docs consistently reference Go-native concepts

### Task 4: Create generic specialist agents

**Files:**
- Create: `examples/go-sample/.agents/agents/go-orchestrator.md`
- Create: `examples/go-sample/.agents/agents/go-architect.md`
- Create: `examples/go-sample/.agents/agents/go-backend-developer.md`
- Create: `examples/go-sample/.agents/agents/go-code-reviewer.md`
- Create: `examples/go-sample/.agents/agents/go-debugger.md`
- Create: `examples/go-sample/.agents/agents/go-test-writer.md`
- Create: `examples/go-sample/.agents/agents/go-db-optimizer.md`
- Create: `examples/go-sample/.agents/agents/go-devops-engineer.md`
- Create: `examples/go-sample/.agents/agents/go-technical-writer.md`

- [ ] **Step 1: Write `go-orchestrator.md`**

It must:
- read progress and changelog first
- emit concise plans
- route to specialists
- preserve the full operating model from the Nest sample in a Go-native form

- [ ] **Step 2: Write the implementation-focused agent cards**

Create `go-architect`, `go-backend-developer`, `go-test-writer`, `go-db-optimizer`, and `go-debugger` with:
- trigger conditions
- responsibilities
- required skills
- hard boundaries

- [ ] **Step 3: Write the quality and operational agent cards**

Create `go-code-reviewer`, `go-devops-engineer`, and `go-technical-writer`.

- [ ] **Step 4: Verify agent inventory**

Run: `find examples/go-sample/.agents/agents -maxdepth 1 -type f | sort`
Expected: generic Go agent set present with no project-specific `dv-*` names

---

## Chunk 3: Go-Native Skills

### Task 5: Create the first Go skill set

**Files:**
- Create: `examples/go-sample/.agents/skills/go-backend-patterns/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-clean-architecture/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-ddd/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-gorm-postgres/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-testing-tdd/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-error-handling/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-debugging/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-redis/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-microservices/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-saga/SKILL.md`
- Create: `examples/go-sample/.agents/skills/go-stream-pipeline/SKILL.md`
- Create: `examples/go-sample/.agents/skills/git-workflow/SKILL.md`
- Create: `examples/go-sample/.agents/skills/jira/SKILL.md`
- Create: `examples/go-sample/.agents/skills/security-review/SKILL.md`

- [ ] **Step 1: Create skill folders and YAML frontmatter**

Each skill must have:
- valid `name`
- valid `description`
- Go-native trigger language

- [ ] **Step 2: Write architecture/core skills**

Write `go-clean-architecture`, `go-ddd`, and `go-backend-patterns`.

- [ ] **Step 3: Write delivery/runtime skills**

Write `go-gorm-postgres`, `go-error-handling`, `go-debugging`, and `go-testing-tdd`.

- [ ] **Step 4: Write future-facing infra skills**

Write `go-redis`, `go-microservices`, `go-saga`, and `go-stream-pipeline` at a level appropriate for the current roadmap.

- [ ] **Step 5: Write generic project-process skills**

Write `git-workflow`, `jira`, and `security-review`.

- [ ] **Step 6: Validate skill file inventory**

Run: `find examples/go-sample/.agents/skills -maxdepth 2 -name SKILL.md | sort`
Expected: every planned skill has a `SKILL.md`

---

## Chunk 4: Workflows, Rules, Contexts, Prompts

### Task 6: Create reusable workflows

**Files:**
- Create: `examples/go-sample/.agents/workflows/orchestration.md`
- Create: `examples/go-sample/.agents/workflows/new-feature.md`
- Create: `examples/go-sample/.agents/workflows/debugging.md`
- Create: `examples/go-sample/.agents/workflows/code-review.md`
- Create: `examples/go-sample/.agents/workflows/test-generator.md`

- [ ] **Step 1: Port the orchestration workflow concept**

Keep the same governance pattern as the Nest sample, but translate verification and implementation steps to Go.

- [ ] **Step 2: Write feature/debugging/review workflows**

Make them reference the new Go skills and rules rather than NestJS-specific ones.

- [ ] **Step 3: Verify workflow references**

Run: `rg -n "NestJS|TypeScript|BaseCommand|BaseQuery" examples/go-sample/.agents/workflows`
Expected: no stale Nest-specific references

### Task 7: Create detailed rules and working contexts

**Files:**
- Create: `examples/go-sample/.agents/rules/clean-architecture-go.md`
- Create: `examples/go-sample/.agents/rules/package-boundaries.md`
- Create: `examples/go-sample/.agents/rules/code-style-go.md`
- Create: `examples/go-sample/.agents/rules/testing-go.md`
- Create: `examples/go-sample/.agents/rules/security-go.md`
- Create: `examples/go-sample/.agents/rules/git-workflow.md`
- Create: `examples/go-sample/.agents/rules/agents.md`
- Create: `examples/go-sample/.agents/contexts/dev.md`
- Create: `examples/go-sample/.agents/contexts/research.md`
- Create: `examples/go-sample/.agents/contexts/review.md`
- Create: `examples/go-sample/.agents/prompts/implement-feature.md`
- Create: `examples/go-sample/.agents/prompts/code-review.md`
- Create: `examples/go-sample/.agents/prompts/debug.md`
- Create: `examples/go-sample/.agents/prompts/write-test.md`

- [ ] **Step 1: Write architecture and boundary rules**

Encode Go package/layer constraints and import direction.

- [ ] **Step 2: Write style/testing/security/process rules**

Make these reference Go-native commands and practices.

- [ ] **Step 3: Write dev/research/review contexts**

Keep them light but useful for consistent operating modes.

- [ ] **Step 4: Write reusable prompts**

Create prompt stubs aligned with the new generic agents.

- [ ] **Step 5: Verify no stale Nest naming remains**

Run: `rg -n "NestJS|TypeORM|class-validator|decorator|provider" examples/go-sample/.agents/rules examples/go-sample/.agents/contexts examples/go-sample/.agents/prompts`
Expected: either no matches or only intentional comparative references

---

## Chunk 5: Hooks, Scripts, Project Tracking, Final README Sync

### Task 8: Create hooks and utility scripts

**Files:**
- Create: `examples/go-sample/.agents/hooks/README.md`
- Create: `examples/go-sample/.agents/hooks/pre-context-loader.sh`
- Create: `examples/go-sample/.agents/hooks/pre-layer-boundary-check.sh`
- Create: `examples/go-sample/.agents/hooks/post-gofmt-check.sh`
- Create: `examples/go-sample/.agents/hooks/post-go-test-check.sh`
- Create: `examples/go-sample/.agents/hooks/settings-hooks.json`
- Create: `examples/go-sample/.agents/scripts/init-services.sh`
- Create: `examples/go-sample/.agents/scripts/access-postgres.sh`
- Create: `examples/go-sample/.agents/scripts/access-redis.sh`
- Create: `examples/go-sample/.agents/scripts/verify-go-env.sh`

- [ ] **Step 1: Write hook docs and config**

Describe how hooks should be used without assuming non-existent tooling.

- [ ] **Step 2: Write safe utility scripts**

Scripts should be low-risk, documented, and aligned with the staged roadmap.

- [ ] **Step 3: Make scripts executable**

Run: `chmod +x examples/go-sample/.agents/hooks/*.sh examples/go-sample/.agents/scripts/*.sh`
Expected: shell scripts executable

- [ ] **Step 4: Verify scripts directory**

Run: `find examples/go-sample/.agents/hooks examples/go-sample/.agents/scripts -maxdepth 1 -type f | sort`
Expected: hooks and scripts present

### Task 9: Create project tracking skeleton and sync README

**Files:**
- Create: `examples/go-sample/docs/plan/progress.md`
- Create: `examples/go-sample/changelogs/CHANGELOG.md`
- Create: `examples/go-sample/changelogs/changes/.gitkeep`
- Modify: `examples/go-sample/README.md`

- [ ] **Step 1: Create `progress.md`**

Add a generic tracker shape that `go-orchestrator` can read later.

- [ ] **Step 2: Create `CHANGELOG.md`**

Add a generic changelog skeleton with room for known issues and recent work.

- [ ] **Step 3: Finalize `README.md`**

Ensure the README includes:
- architecture principles
- `.agents` operating model
- description/spec responsibilities
- roadmap

- [ ] **Step 4: Run a final structural verification**

Run: `find examples/go-sample -maxdepth 4 | sort`
Expected: `.agents`, `docs/plan`, and `changelogs` exist with the planned skeleton

- [ ] **Step 5: Run content sanity checks**

Run: `rg -n "dv-|NestJS|TypeScript|BaseCommand|BaseQuery" examples/go-sample/.agents examples/go-sample/README.md`
Expected: no stale project-specific or Nest-specific leftovers except deliberate comparative references

---

## Final Verification

- [ ] **Step 1: Review the full tree**

Run: `find examples/go-sample -maxdepth 4 | sort`
Expected: complete `.agents` template and project docs skeleton

- [ ] **Step 2: Review high-signal entry files**

Run:
```bash
sed -n '1,220p' examples/go-sample/README.md
sed -n '1,220p' examples/go-sample/.agents/AGENTS.md
sed -n '1,220p' examples/go-sample/.agents/agents/go-orchestrator.md
```
Expected: the sample reads as a Go-native reusable template, not a Nest port

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-04-18-go-sample-agents-design.md \
  docs/superpowers/plans/2026-04-18-go-sample-agents.md \
  examples/go-sample
git commit -m "feat: scaffold reusable go agents template"
```

Only do this step if the user explicitly asks for a commit.
