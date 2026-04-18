# CHANGELOG

## 2026-04-18
- Added this repository as the first reference consumer of a reusable Go service agent template.
- Documented architecture principles, operating model, and roadmap in `README.md`.
- Scaffolded `.agents` with generic Go-focused agent roles, skills, workflows, rules, contexts, prompts, hooks, and helper scripts.
- Established local progress tracking and change-management entry points for future feature work.
- Hardened `.agents/agents` so team docs and specialist cards now behave as detailed operational contracts rather than short role summaries.
- Rewrote `.agents/agents/architecture.md` into a detailed structural spec and deepened `.agents/agents/go-orchestrator.md` into a more complete execution governor.
- Deepened the remaining specialist cards so review, debugging, persistence, devops, testing, and technical-writing roles follow the same operational-contract format.
- Copied the repository skill set into `skills/`, added repo-local bridge skills under `.agents/skills/`, and updated agent cards to load copied base skills before repo-local precision skills.
- Clarified that this repository must resolve broad skills from its copied local `skills/` tree instead of any external root skill tree, and removed one remaining repo-specific absolute path from the copied skill set.
- Normalized copied skill docs and `.agents` docs to repo-local root-relative references so the sample can be moved without carrying nested-path, home-directory, or broken cross-tree assumptions.
- Added one bundle skill per agent role, rewired role cards to use a single primary entry skill, and updated the skill map and team docs so role activation no longer depends on inline multi-skill expansion.
