# Go Sample Agents Design

## Meta

- Date: 2026-04-18
- Scope: `examples/go-sample/.agents` as the first sub-project
- Goal: create a reusable `.agents` source-of-truth template for Go services, using `examples/nestjs-sample/.agents` as reference but not as a copy target
- Follow-on work: scaffold `examples/go-sample` code sample after `.agents` is validated

## Summary

The first deliverable is not application code. It is a reusable `.agents` operating system for Go services.

`examples/go-sample/.agents` will be designed as a generic template that can later be lifted into other Go service repositories. It will preserve the strongest parts of the NestJS sample operating model:

- orchestrator-first planning
- progress and changelog tracking
- spec-first changes
- TDD and verification gates
- specialist agent delegation
- reusable skills, workflows, rules, hooks, and scripts

The Go version must remove NestJS- and TypeScript-specific assumptions and replace them with Go-native guidance centered on:

- `cmd/`, `internal/`, and `pkg/`
- constructor injection
- `context.Context`
- Gin HTTP delivery
- GORM + Postgres
- DDD + Clean Architecture
- domain events, outbox, and future messaging evolution

## Objectives

1. Create a clean `.agents` source of truth under `examples/go-sample/.agents`.
2. Make the agent system generic for future Go service repos.
3. Preserve the full operating model from the Nest sample, but clean and genericize it.
4. Align every rule and workflow with `documents/assets/architecture/go`.
5. Feed the resulting conventions and principles back into `examples/go-sample/README.md`.

## Non-Goals

1. Do not scaffold application code in this sub-project.
2. Do not mirror `.agents` into `.claude/` or `.cursor/`.
3. Do not implement Kafka/RabbitMQ orchestration yet.
4. Do not hardcode commerce-specific logic into the agent template.

## Source Material

The design derives from these sources:

- `examples/nestjs-sample/.agents/`
- `docs/nestjs-sample-libs-spec.md`
- `documents/assets/architecture/go/README.md`
- `documents/assets/architecture/go/02-domain-layer.md`
- `documents/assets/architecture/go/03-application-layer.md`
- `documents/assets/architecture/go/04-infrastructure-layer.md`
- `documents/assets/architecture/go/05-presentation-layer.md`
- `documents/assets/architecture/go/06-domain-events.md`
- `documents/assets/architecture/go/07-saga-pattern.md`

The NestJS sample is a reference system. The Go template must be rewritten around Go-specific constraints, not transliterated.

## Proposed Structure

```text
examples/go-sample/
├── .agents/
│   ├── AGENTS.md
│   ├── README.md
│   ├── project.md
│   ├── rules.md
│   ├── agents/
│   │   ├── README.md
│   │   ├── architecture.md
│   │   ├── interaction-protocol.md
│   │   ├── go-orchestrator.md
│   │   ├── go-architect.md
│   │   ├── go-backend-developer.md
│   │   ├── go-code-reviewer.md
│   │   ├── go-debugger.md
│   │   ├── go-test-writer.md
│   │   ├── go-db-optimizer.md
│   │   ├── go-devops-engineer.md
│   │   └── go-technical-writer.md
│   ├── skills/
│   │   ├── go-backend-patterns/
│   │   ├── go-clean-architecture/
│   │   ├── go-ddd/
│   │   ├── go-gorm-postgres/
│   │   ├── go-testing-tdd/
│   │   ├── go-error-handling/
│   │   ├── go-debugging/
│   │   ├── go-redis/
│   │   ├── go-microservices/
│   │   ├── go-saga/
│   │   ├── go-stream-pipeline/
│   │   ├── git-workflow/
│   │   ├── jira/
│   │   └── security-review/
│   ├── workflows/
│   │   ├── orchestration.md
│   │   ├── new-feature.md
│   │   ├── debugging.md
│   │   ├── code-review.md
│   │   └── test-generator.md
│   ├── rules/
│   │   ├── clean-architecture-go.md
│   │   ├── package-boundaries.md
│   │   ├── code-style-go.md
│   │   ├── testing-go.md
│   │   ├── security-go.md
│   │   ├── git-workflow.md
│   │   └── agents.md
│   ├── contexts/
│   │   ├── dev.md
│   │   ├── research.md
│   │   └── review.md
│   ├── prompts/
│   │   ├── implement-feature.md
│   │   ├── code-review.md
│   │   ├── debug.md
│   │   └── write-test.md
│   ├── hooks/
│   │   ├── README.md
│   │   ├── pre-context-loader.sh
│   │   ├── pre-layer-boundary-check.sh
│   │   ├── post-gofmt-check.sh
│   │   ├── post-go-test-check.sh
│   │   └── settings-hooks.json
│   ├── scripts/
│   │   ├── init-services.sh
│   │   ├── access-postgres.sh
│   │   ├── access-redis.sh
│   │   └── verify-go-env.sh
│   └── specs/
├── docs/
│   └── plan/progress.md
└── changelogs/
    ├── CHANGELOG.md
    └── changes/
```

## Operating Model

### Orchestrator First

`go-orchestrator` is the central coordinator. It reads project state first, then emits short execution plans.

The minimum read path for complex tasks:

1. `docs/plan/progress.md`
2. `changelogs/CHANGELOG.md`
3. `project.md`
4. `agents/architecture.md`
5. relevant workflow and skill files

### Spec First

For non-trivial work, the system creates and tracks:

- `changelogs/changes/<slug>/proposal.md`
- `changelogs/changes/<slug>/tasks.md`
- optional `design.md`
- optional `evidence/`

Implementation is gated behind approved scope and a concrete task breakdown.

### TDD and Verification

The template keeps TDD and review gates:

- `go-test-writer` establishes RED where appropriate
- `go-backend-developer` or other implementers work inside defined scope
- `go-code-reviewer` performs mandatory review before work is considered done
- verification hooks prioritize `gofmt`, `go test`, and boundary checks

### Documentation Loop

The orchestrator and writer agents keep:

- `progress.md` in sync with live task state
- `CHANGELOG.md` updated after work completes
- reusable architectural knowledge in `.agents`

## Agent Roles

The system is generic and not domain-named. Initial roles:

- `go-orchestrator`
- `go-architect`
- `go-backend-developer`
- `go-code-reviewer`
- `go-debugger`
- `go-test-writer`
- `go-db-optimizer`
- `go-devops-engineer`
- `go-technical-writer`

These roles are intentionally broad enough for reuse across Go service repos.

They will be specialized around Go-native concerns:

- clean package boundaries
- DDD and application handlers
- GORM/Postgres persistence
- debugging panics, race conditions, goroutine leaks, and config/runtime failures
- CI/CD, runtime scripts, and containerized local development

## Skill Set

The initial Go-oriented skill families are:

- `go-backend-patterns`
- `go-clean-architecture`
- `go-ddd`
- `go-gorm-postgres`
- `go-testing-tdd`
- `go-error-handling`
- `go-debugging`
- `go-redis`
- `go-microservices`
- `go-saga`
- `go-stream-pipeline`
- `git-workflow`
- `jira`
- `security-review`

The priority is not to mirror the Nest skill count. The priority is to cover the actual Go service lifecycle with high-signal guidance.

## Rule Set

The rules must enforce Go-specific architecture boundaries, including:

- `Presentation -> Application -> Domain <- Infrastructure`
- no framework imports in domain
- no direct domain bypass from HTTP handlers
- constructor injection and explicit wiring
- `context.Context` propagation rules
- package naming and import hygiene
- test and review expectations

The rules must be strict enough to prevent architectural drift, but generic enough to move to future Go service repos.

## Relationship to `examples/go-sample/README.md`

The sample README must absorb the architectural principles and operating model from this design.

README responsibilities:

1. explain why `examples/go-sample` exists
2. explain the roles of `cmd/`, `internal/`, `pkg/`, `.agents/`, `docs/`, and `changelogs/`
3. document the Go Clean Architecture and DDD principles
4. document `.agents` as the source-of-truth operating model
5. describe the staged roadmap:
   - `.agents` first
   - code sample foundation next
   - Redis after
   - Kafka/RabbitMQ adapter-manager later

## Implementation Phasing

### Phase 1

Build the `.agents` system only:

- top-level `.agents` docs
- generic agent cards
- core workflows
- Go-native rule set
- initial Go skills
- progress/changelog skeleton
- README updates for principles and operating model

### Phase 2

Scaffold the code sample:

- `examples/go-sample/pkg/...`
- `cmd/api`, `cmd/worker`, `cmd/migrate`, `cmd/cli`
- service skeleton
- first bounded context flow later

### Phase 3

Add Redis guidance and code integrations.

### Phase 4

Add Kafka/RabbitMQ and the more complex adapter-manager patterns after the Go sample and docs are mature enough.

## Risks

1. Over-porting Nest terminology into Go and ending up with a TypeScript mindset in different syntax.
2. Creating too many skills too early and diluting the value of the template.
3. Letting the template become commerce-specific instead of reusable.
4. Mixing implementation guidance for future Kafka/RabbitMQ complexity into the first phase before the foundation is stable.

## Decisions

1. `examples/go-sample` is a new sample beside the Nest sample.
2. `.agents/` is the only source of truth. No `.claude/` or `.cursor/` mirrors in phase 1.
3. The `.agents` system must be generic for future Go services.
4. The operating model remains full-featured, but is cleaned and genericized.
5. Phase 1 delivers `.agents` first, then code sample work follows.
