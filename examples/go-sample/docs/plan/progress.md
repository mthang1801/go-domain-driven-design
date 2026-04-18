# Progress

## Current State
- Phase 1 focus is `.agents` as the reusable source-of-truth operating model for future Go services.
- Entry docs, Go-native skills, workflows, rules, contexts, prompts, hooks, and helper scripts are scaffolded.
- Team-level agent docs have been hardened from short profiles into detailed operating contracts with routing, handoff, checklist, and completion rules.
- `architecture.md` now needs to be treated as a structural spec, and `go-orchestrator.md` as the execution governor for the team.
- Specialist cards now follow the same deeper format across review, debugging, database, devops, test, and technical-writing roles.
- `skills/` now contains a copied local base skill set, while `.agents/skills/` contains local bridge skills and precise sample-specific skills.
- Agent guidance now explicitly forbids falling back to any external root skill tree, so the sample can be moved to a different repository without base-skill reference drift.
- Copied skill docs and `.agents` docs now use repo-local root-relative paths such as `skills/`, `.agents/`, `docs/`, and `changelogs/` instead of home-directory or nested-repo-specific references.
- Each agent role now has a dedicated bundle skill under `.agents/skills/`, and role cards reference that single entry skill instead of expanding the entire stack inline.
- Service code under `cmd/`, `internal/`, and `pkg/` has not been implemented yet in this sample.

## Next Milestones
1. Add sample service skeleton under `cmd/`, `internal/`, and `pkg/`.
2. Implement the first end-to-end bounded-context flow on `HTTP + Postgres + GORM`.
3. Introduce Redis behind explicit ports.
4. Design broker adapter-manager patterns for Kafka and RabbitMQ.

## Risks
- The current boundary hook is intentionally lightweight and should evolve into stronger import/package verification once the codebase exists.
- Future messaging support needs a careful abstraction to avoid premature generic infrastructure.
- The agent roster is backend-first; future product-analysis or frontend-specific roles should only be added if the sample grows beyond service-template scope.
