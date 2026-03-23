# Data Visualizer Builder for Nestjs - Project Specification

> **Version:** 1.0.0
> **Last Updated:** 2026-02-25
> **Platform:** NestJS 11.x + DDD Architecture
> **Reference:** Data Visualization Module

## 1. Overview

Data Visualizer Builder for NestJS is a comprehensive module designed to manage data visualization effectively. It provides a drag-and-drop query builder, dynamic schema discovery, robust runtime query execution, and fine-grained permission controls to allow end-users to create and consume custom data views safely.

### Core Objectives

1. **Schema Discovery** - Automatically detect whitelisted tables and their foreign key relationships (JOINs).
2. **Visual Query Builder** - Empower admins to build complex queries via a drag-and-drop interface with field aliasing, filtering, and sorting.
3. **Runtime Engine** - Dynamically execute the generated configurations against the database using a robust, paginated query builder.
4. **Data Export** - Provide out-of-the-box export functionality (Excel/CSV) for generated views.
5. **Security & Permissions** - Protect views using granular access controls (Public, Private, Route-level, or Role-specific).
6. **Data Import** - Fast, stream-based CSV import utilizing BullMQ queue with local saga compensation (rollback on fail).
7. **Future AI Agent Integration** - Integrate an AI Agent allowing users to prompt using natural language, which the AI will securely convert into SQL and query the database.

---

## 2. Development Standards & Skills

### 2.1 Backend Architecture Standards (DDD)

- **Domain-Driven Design (DDD)**: Separate logic into `domain`, `application`, `infrastructure`, and `interface` layers.
- **Type Safety**: Enforce strict TypeScript types, DTOs with `class-validator`.
- **Error Handling**: Use custom domain exceptions (`common/exceptions`), intercepted globally.
- **Code Style**: Format via Prettier, lint via ESLint (NestJS strict rules).

### 2.2 UI/UX Design Standards & Frontend Integration (`skill:frontend-patterns`)

- **Primary Tech Stack (React/Next.js)**: Implement the frontend as a dedicated client application using React and Next.js, strictly following the `vercel-react-best-practices` skill.
- **Backend Server-Side Rendering Option**: If views must be embedded directly in the NestJS backend, use Handlebars (`.hbs`) as per the `server-side-render` skill (extending `BaseAssetsModule` and `AssetsBaseController`).
- **UI/UX Integration (`skill:ui-ux`, `skill:frontend-design`, `skill:ui-ux-pro-max`)**: Strictly implement the Data Visualizer application using the **Metabase Design System** discovered and documented in `.claude/skills/ui-ux/components`. Ensure exact reproduction of `Top Header`, `Left Sidebar`, and padding/margin properties defined for the grid canvas view. Incorporate aesthetic principles from `frontend-design` and ensure accessibility and quality through `web-design-guidelines`. Use `design-md` to synthesize further Stitch models if needed.
- **Client-Side Reactivity**: Embedded Vanilla JS or Vue.js/React.js via CDN within the SSR template for the Visual Builder canvas. Use JS for implementing interactive states (Dropdowns, Active menus, Disabled Opacity configurations).
- **Theme Constraints**: Emulate the authentic Metabase dark/light mode context. Ensure strict adherence to: Font `Lato, sans-serif`, Color Primary `#509EE3` (Picton Blue), and large inner padding `24px` combined with a clean `8px` border radius for Data Cards. No general Tailwind generic presets; only explicitly styled components following the `.claude/skills/ui-ux` metadata.

### 2.3 NestJS Specifics (`skill:nestjs-module`)

- Export functionality through bounded contexts.
- Use CQRS patterns (Commands/Queries) for complex view generation.
- Dependency injection following SOLID principles.

---

## 3. Feature Specifications

### 3.1 Schema Discovery & Whitelisting

- Expose an API to fetch the current database schema.
- Support a strict whitelist of tables (e.g., `tblclients`, `tblinvoices`) to prevent exposing sensitive internal tables (e.g., `users`, `passwords`).
- Auto-detect relationships based on foreign keys for smart JOIN suggestions.

### 3.2 Visual Query Builder

- **Field Selection**: Drag fields from the available schema out to the canvas.
- **Aliasing**: Allow users to set custom, user-friendly labels for columns.
- **Filtering & Conditions**: Dynamic operators (`=`, `<`, `>`, `LIKE`, `IN`, `BETWEEN`).
- **Grouping & Sorting**: Define `ORDER BY` and `GROUP BY` logic visually.

### 3.3 Runtime Engine

- Parse the saved JSON view configuration and map it safely to SQL using QueryBuilder (e.g., TypeORM or Knex) to prevent SQL injection.
- Support cursor-based or offset-based pagination.
- Apply runtime context variables (e.g., filter by `current_user_id`).
- **AI Agent Support:** Feature intelligence, optimizing complex SQL runtimes dynamically.

### 3.4 Data Visualizer Studio (7 Core Modules)

This system incorporates 7 fundamental components inspired by Supabase Studio UX but using Metabase Design System:

1. **Dashboard & Project Overview**: Realtime stats and empty states. **AI Agent Support:** Recommends overviews and highlights actionable metrics.
2. **Table Editor**: Spreadsheet-like data editing with virtualization. **AI Agent Support:** Smart autocomplete for new columns, data type suggestions, and schema validations.
3. **SQL Editor**: Full Monaco IDE experience. **AI Agent Support (Natural Language to SQL):** Integrates an LLM to convert user natural language prompts directly into properly formatted, safe SQL queries, alongside query explanations and syntax correction.
4. **Database Management**: Roles, RLS, triggers via Saga Orchestrator. **AI Agent Support:** Identifies missing indexes and suggests RLS policies based on natural language constraints.
5. **Storage**: Drag-n-drop file uploading using multipart streaming and S3 outbound ports. **AI Agent Support:** Automatically classifies uploaded media and summarizes documents.
6. **Logs & Alerts**: Real-time console terminal via OpenTelemetry & SSE. **AI Agent Support:** Scans stack traces for anomalies and suggests fixes for frequent errors.
7. **Project Settings**: Safe configuration and billing overviews. **AI Agent Support:** Audits setup for security misconfigurations and cost optimization.

Every module must integrate its corresponding **AI Agent** seamlessly into its workspace to boost developer and admin productivity.

### 3.5 Security & Permission Management

- Define visibility per view: Public, Private (Owner only), or Shared with specific IAM Roles.
- Route-level security: Each saved view gets a unique identifier/slug.

### 3.5 Data Export

- Stream large datasets to Excel/CSV to avoid memory max-outs.

---

## 4. User Workflow

1. **Initiate**: Admin accesses Data Builder -> Builder to create a new view.
2. **Select Data**:
    - Choose a **Base Table** (e.g., `tblclients`) from the whitelist.
    - Add related tables (e.g., `tblinvoices`). System auto-detects JOIN condition (e.g., `tblclients.userid = tblinvoices.clientid`).
3. **Design View**:
    - Drag fields from the left panel to the canvas.
    - Set aliases for user-friendly column headers.
    - Apply filters (e.g., `date > 2026-01-01`).
    - Define sorting and grouping logic.
4. **Preview & Refine**:
    - Click **Preview** to see sample data and verify logic.
    - Adjust JOIN types (LEFT/INNER) if records are missing.
5. **Save & Share**:
    - Save the view with a unique route (e.g., `high-value-clients`).
    - Set permissions: Public, Private, or specific Roles.
6. **Consume**:
    - Staff accesses the view via Data Builder -> Views or direct URL.
    - Data is loaded via Runtime Engine (paginated).
    - User can **Export** result to Excel/CSV for further analysis.

### Workflow Diagram

- **Dependencies:** `SortableJS`, `React.js` or Vanilla JS, `SweetAlert2` (For Visual Builder UI)

```text
    [ CONFIG TRACK ]           [ SYSTEM BRAIN ]              [ PERSISTENCE ]
  (Design & Discovery)         (Central Engine)              (Data & State)

+------------------+       +------------------+
| Schema Discovery | <---> | Runtime Engine   | <---------+
| (Whitelisting)   |       | (Query Builder)  |           |
+------------------+       +------------------+           | (Scanning & Executing)
        ^   |                      ^   |                  v
        |   | (Feedback)           |   |        +--------------------+
        |   v                      |   v        | PostgreSQL DB      |
+------------------+       +------------------+ | (polydb_views &    |
|  Visual Builder  | <---> | Views Registry   |<+ Actual DB Tables)  |
| (Drag & Drop UI) |       | (Saved Configs)  | +--------------------+
+------------------+       +------------------+           ^
        ^                          |   |                  |
        | (Design)                 |   | (Results/Export) |
        |                          |   v                  |
+---------------+          +------------------+           | (CSV Import via
| Administrator |          | End User         | ----------+  stream-pipeline
+---------------+          +------------------+              & BullMQ Saga)
                                   ^
                                   | (Natural Language Prompt)
                       +----------------------+
                       | AI Agent (NL to SQL) |
                       +----------------------+
```

---

## 5. Database Schema (Entities)

### 5.1 Tables & Indexes Design (`skill:supabase-postgres-best-practices`)

Follow `supabase-postgres-best-practices` to ensure properly configured connection management, indexes, optimized query conditions (avoiding large IN loops, etc.), and efficient RLS rules if applicable.

```typescript
// Proposed structure mapping
// Domain Entities extending BaseEntity (libs/src/ddd/domain)
- DashboardViewEntity extends BaseEntity
  - id: UniqueEntityId
  - name: string
  - slug: string
  - baseTable: string
  - isPublic: boolean
  - createdBy: string
  - createdAt: Date
  - columns: ViewColumnEntity[]
  - filters: ViewFilterEntity[]
  - joins: ViewJoinEntity[]
  - permissions: ViewPermissionEntity[]

- ViewColumnEntity extends BaseEntity
  - id: UniqueEntityId
  - viewId: UniqueEntityId
  - tableName: string
  - columnName: string
  - alias: string
  - sortOrder: number
  - isVisible: boolean

- ViewFilterEntity extends BaseEntity
  - id: UniqueEntityId
  - viewId: UniqueEntityId
  - tableName: string
  - columnName: string
  - operator: string // ValueObject
  - value: string
  - logic: string // AND/OR ValueObject

- ViewJoinEntity extends BaseEntity
  - id: UniqueEntityId
  - viewId: UniqueEntityId
  - targetTable: string
  - joinType: string // INNER/LEFT ValueObject
  - condition: string

- ViewPermissionEntity extends BaseEntity
  - id: UniqueEntityId
  - viewId: UniqueEntityId
  - roleId: string
  - userId: string
```

## 6. File Structure (NestJS DDD)

```text
data-visualizer/
├── src/
│   ├── presentation/
│   │   └── portal/
│   │       └── data-builder/
│   │           ├── controllers/ (REST endpoints)
│   │           └── dtos/
│   ├── application/
│   │   └── data-builder/
│   │       ├── use-cases/ (extend BaseCommand/BaseQuery)
│   │       ├── sagas/ (e.g. DataBuilderImportSaga)
│   │       ├── strategies/ (e.g. DataBuilderImportStrategy)
│   │       └── services/ (Runtime Engine)
│   ├── domain/
│   │   └── data-builder/
│   │       ├── entities/ (extend BaseEntity)
│   │       ├── value-objects/
│   │       ├── events/ (extend BaseDomainEvents)
│   │       └── repositories/ (RepositoryPorts)
│   ├── infrastructure/
│   │   ├── persistence/
│   │   │   ├── typeorm/ (extend BaseRepositoryTypeORM)
│   │   └── exporters/ (CSV/Excel)
│   └── app.module.ts
├── package.json
└── .claude/
    ├── project.md
    ├── AGENTS.heraspec.md
    └── specs/
```

## 7. Development Roadmap

### Phase 1: Core Foundation & Schema

- Setup NestJS DDD module structure
- Implement schema discovery service and whitelist management
- Create base entities and repositories

### Phase 2: Visual Builder API

- CRUD APIs for saving view configurations
- Endpoint to test/preview view queries
- DTO validation for complex condition logic

### Phase 3: Runtime Engine

- Secure query compilation (SQL Builder)
- Pagination and sorting execution
- Caching implementation for heavy views

### Phase 4: Permissions & Export

- Access control interceptors/guards
- Excel/CSV streaming endpoints
- User testing and documentation

### Phase 5: Future AI Expansion (Natural Language to SQL & Autonomous Capabilities)

- Integrate an AI Agent that understands user intent through natural language prompts.
- Translate natural language queries into secure, optimized SQL based on the whitelisted schema.
- Leverage external generative pipelines (`skill:agent-tools`, `skill:agent-browser`, `skill:nano-banana`, etc.) where visualization generation requires richer context or autonomous crawling of external APIs.
- Dynamically execute AI-generated queries and present visual results or exportable data.
