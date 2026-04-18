# Go Agent Cards Hardening Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite `examples/go-sample/.agents/agents` into a detailed, reusable Go service team operating model with strict role definitions, routing, handoff, and completion gates.

**Architecture:** Keep business/domain concerns generic, but make agent professionalism explicit. Team-level docs define routing and interaction protocol; each specialist card defines mandatory reads, bundled skills, boundaries, workflow, output contract, and success metrics.

**Tech Stack:** Markdown documentation, Go service architecture conventions, existing `.agents` operating model.

---

## Chunk 1: Team-Level Operating Docs

### Task 1: Harden the team map and routing docs

**Files:**
- Create: `examples/go-sample/.agents/agents/GO-TEAM.md`
- Modify: `examples/go-sample/.agents/agents/README.md`
- Modify: `examples/go-sample/.agents/agents/interaction-protocol.md`

- [ ] **Step 1: Define the team surface**

Document the Go team inventory, routing order, agent trigger matrix, and SDLC flow.

- [ ] **Step 2: Tighten the interaction protocol**

Add handoff payload requirements, escalation rules, conflict handling, and review gates.

- [ ] **Step 3: Verify team-level docs are internally consistent**

Run: `sed -n '1,260p' examples/go-sample/.agents/agents/GO-TEAM.md`
Expected: detailed routing and team model with no Nest-specific assumptions

## Chunk 2: Rewrite Specialist Agent Cards

### Task 2: Rewrite core delivery agents

**Files:**
- Modify: `examples/go-sample/.agents/agents/go-orchestrator.md`
- Modify: `examples/go-sample/.agents/agents/go-architect.md`
- Modify: `examples/go-sample/.agents/agents/go-backend-developer.md`
- Modify: `examples/go-sample/.agents/agents/go-test-writer.md`

- [ ] **Step 1: Expand orchestrator into an operating contract**
- [ ] **Step 2: Expand architect card with boundary, ADR, and trade-off responsibilities**
- [ ] **Step 3: Expand backend developer card with Go runtime, transport, persistence, and workflow rules**
- [ ] **Step 4: Expand test writer card with TDD and verification ownership**

### Task 3: Rewrite review and operational agents

**Files:**
- Modify: `examples/go-sample/.agents/agents/go-code-reviewer.md`
- Modify: `examples/go-sample/.agents/agents/go-debugger.md`
- Modify: `examples/go-sample/.agents/agents/go-db-optimizer.md`
- Modify: `examples/go-sample/.agents/agents/go-devops-engineer.md`
- Modify: `examples/go-sample/.agents/agents/go-technical-writer.md`

- [ ] **Step 1: Expand reviewer and debugger cards**
- [ ] **Step 2: Expand database, devops, and writer cards**
- [ ] **Step 3: Verify each card includes trigger, reads, workflow, boundaries, and output expectations**

## Chunk 3: Integrate With Sample Operating Model

### Task 4: Sync entry docs and tracking artifacts

**Files:**
- Modify: `examples/go-sample/.agents/AGENTS.md`
- Modify: `examples/go-sample/.agents/README.md`
- Modify: `examples/go-sample/docs/plan/progress.md`
- Modify: `examples/go-sample/changelogs/CHANGELOG.md`

- [ ] **Step 1: Update entry docs to point to detailed team-level references**
- [ ] **Step 2: Note the hardening pass in progress tracking and changelog**
- [ ] **Step 3: Verify no stale “lightweight” language remains**

## Chunk 4: Verification

### Task 5: Run inventory and stale-reference checks

**Files:**
- Verify only

- [ ] **Step 1: Verify agent file inventory**

Run: `find examples/go-sample/.agents/agents -maxdepth 1 -type f | sort`
Expected: detailed Go team docs plus all specialist cards

- [ ] **Step 2: Verify stale Nest-specific tokens are absent from Go agent cards**

Run: `rg -n "NestJS|TypeORM|BaseCommand|BaseQuery|class-validator|decorator|provider" examples/go-sample/.agents/agents`
Expected: no stale framework-specific references except intentional comparisons if any

- [ ] **Step 3: Verify high-signal docs render cleanly**

Run: `sed -n '1,260p' examples/go-sample/.agents/agents/go-backend-developer.md`
Expected: detailed operational card with explicit responsibilities, boundaries, and success metrics
