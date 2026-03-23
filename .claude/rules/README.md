# Rules Index — Load by Context

> **Agent guidance**: Don't load all 60+ rule files. Load only the group relevant to your task.
> This prevents context bloat and keeps agent focus sharp.

---

## Group 1: Universal (Always Load)

Áp dụng cho mọi task, mọi agent.

| File                  | Purpose                                      |
| --------------------- | -------------------------------------------- |
| `code-style-guide.md` | TypeScript/NestJS formatting, naming, ESLint |
| `git-workflow.md`     | Commit format, PR workflow                   |
| `security.md`         | Security mandatory checks                    |
| `testing.md`          | Test coverage requirements (80%+)            |
| `performance.md`      | Model selection, context management          |
| `agents.md`           | Agent orchestration guide                    |
| `hooks.md`            | Claude Code hooks configuration              |

---

## Group 2: Backend / NestJS DDD

Load khi làm task backend: Entity, UseCase, Repository, Controller, Module.

**Agents:** `dv-backend-developer`, `dv-debugger`

| File                           | Purpose                                  |
| ------------------------------ | ---------------------------------------- |
| `async-parallel.md`            | Promise.all for independent operations   |
| `async-defer-await.md`         | Defer await until needed                 |
| `async-dependencies.md`        | Dependency-based parallelization         |
| `async-api-routes.md`          | Prevent waterfall chains in API routes   |
| `js-early-exit.md`             | Early return patterns                    |
| `js-index-maps.md`             | Build Map for O(1) lookups               |
| `js-set-map-lookups.md`        | Set/Map vs Array includes                |
| `js-combine-iterations.md`     | Combine multiple array iterations        |
| `js-cache-function-results.md` | Cache repeated function calls            |
| `js-cache-property-access.md`  | Cache property access in loops           |
| `js-length-check-first.md`     | Early length check for array comparisons |
| `js-min-max-loop.md`           | O(n) min/max vs O(n log n) sort          |

---

## Group 3: Frontend / React / Next.js

Load khi làm task frontend: React components, Next.js pages, UI/UX.

**Agents:** `dv-frontend-developer`

### Async & Data Fetching

| File                                | Purpose                                      |
| ----------------------------------- | -------------------------------------------- |
| `async-suspense-boundaries.md`      | Strategic Suspense boundaries                |
| `server-parallel-fetching.md`       | Parallel RSC data fetching                   |
| `server-cache-react.md`             | Per-request deduplication with React.cache() |
| `server-cache-lru.md`               | Cross-request LRU caching                    |
| `server-serialization.md`           | Minimize serialization at RSC boundaries     |
| `server-dedup-props.md`             | Avoid duplicate serialization in RSC props   |
| `server-after-nonblocking.md`       | Use after() for non-blocking operations      |
| `server-auth-actions.md`            | Authenticate Server Actions                  |
| `client-swr-dedup.md`               | SWR for automatic deduplication              |
| `client-event-listeners.md`         | Deduplicate global event listeners           |
| `client-localstorage-schema.md`     | Version and minimize localStorage data       |
| `client-passive-event-listeners.md` | Passive event listeners for scroll           |

### Re-render Optimization

| File                                    | Purpose                                 |
| --------------------------------------- | --------------------------------------- |
| `rerender-memo.md`                      | Extract to memoized components          |
| `rerender-memo-with-default-value.md`   | Default non-primitive values in memo    |
| `rerender-simple-expression-in-memo.md` | Don't wrap simple expressions           |
| `rerender-derived-state.md`             | Subscribe to derived boolean state      |
| `rerender-derived-state-no-effect.md`   | Calculate derived state during render   |
| `rerender-functional-setstate.md`       | Use functional setState updates         |
| `rerender-lazy-state-init.md`           | Lazy state initialization               |
| `rerender-dependencies.md`              | Narrow effect dependencies              |
| `rerender-transitions.md`               | useTransition for non-urgent updates    |
| `rerender-use-ref-transient-values.md`  | useRef for transient values             |
| `rerender-defer-reads.md`               | Defer state reads to usage point        |
| `rerender-move-effect-to-event.md`      | Put interaction logic in event handlers |

### Bundle & Performance

| File                          | Purpose                                     |
| ----------------------------- | ------------------------------------------- |
| `bundle-barrel-imports.md`    | Avoid barrel file imports (import directly) |
| `bundle-dynamic-imports.md`   | Dynamic imports for heavy components        |
| `bundle-conditional.md`       | Conditional module loading                  |
| `bundle-preload.md`           | Preload based on user intent                |
| `bundle-defer-third-party.md` | Defer non-critical third-party libs         |

### Rendering Patterns

| File                                      | Purpose                                    |
| ----------------------------------------- | ------------------------------------------ |
| `rendering-hoist-jsx.md`                  | Hoist static JSX elements                  |
| `rendering-conditional-render.md`         | Explicit conditional rendering             |
| `rendering-content-visibility.md`         | CSS content-visibility for long lists      |
| `rendering-activity.md`                   | Activity component for show/hide           |
| `rendering-usetransition-loading.md`      | useTransition over manual loading states   |
| `rendering-animate-svg-wrapper.md`        | Animate SVG wrapper (GPU acceleration)     |
| `rendering-svg-precision.md`              | Optimize SVG precision                     |
| `rendering-hydration-no-flicker.md`       | Prevent hydration mismatch without flicker |
| `rendering-hydration-suppress-warning.md` | Suppress expected hydration mismatches     |

### Advanced React Patterns

| File                             | Purpose                                 |
| -------------------------------- | --------------------------------------- |
| `advanced-event-handler-refs.md` | Store event handlers in refs            |
| `advanced-init-once.md`          | Initialize app once, not per mount      |
| `advanced-use-latest.md`         | useEffectEvent for stable callback refs |
| `js-hoist-regexp.md`             | Hoist RegExp creation                   |
| `js-tosorted-immutable.md`       | Use toSorted() for immutability         |
| `js-batch-dom-css.md`            | Avoid layout thrashing                  |
| `js-cache-storage.md`            | Cache localStorage/cookie reads         |

---

## Group 4: Database / Query Optimization

Load khi làm task database: schema, query, index, migration.

**Agents:** `dv-db-optimizer`

> Reference: `.claude/skills/supabase-postgres-best-practices/SKILL.md`
> Reference: `.claude/skills/database/SKILL.md`

---

## Quick Reference by Agent

| Agent                    | Load Groups                           |
| ------------------------ | ------------------------------------- |
| `dv-backend-developer`   | Group 1 + Group 2                     |
| `dv-code-reviewer`       | Group 1 + Group 2 + Group 3 + Group 4 |
| `dv-refactor-specialist` | Group 1 + Group 2                     |
| `dv-debugger`            | Group 1 + Group 2                     |
| `dv-frontend-developer`  | Group 1 + Group 3                     |
| `dv-test-writer`         | Group 1 + Group 2                     |
| `dv-db-optimizer`        | Group 1 + Group 4                     |
