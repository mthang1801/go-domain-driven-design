# 12 - Data Visualizer Studio (8 Core Modules)

## Objective

To implement the 8 Core Studio Modules designed for the Data Visualizer Builder platform, emulating the optimized UX patterns of Supabase Studio while strictly interpreting the layout through the **Metabase Design System** (`.claude/skills/ui-ux-pro-max`).

## Core Principles

1. **Frontend Architecture**: Built using `Next.js` Application Router and React, following the **Vercel React Best Practices**. Elimination of waterfalls through `React.Suspense`.
2. **Backend Architecture**: All CRUD and advanced logic goes through the `Domain-Driven Design (DDD)` structure in `src/`.
3. **AI Ubiquity**: Every module integrates an AI assist panel specific to the functionality.

---

## The 8 Core Modules

### 1. Dashboard & Project Overview

- **Functionality**: Global snapshot of the project operations, database sizes, and active connections.
- **Backend**: Employs CQRS query controllers and Redis Cache.
- **Frontend**: Data cards separated into individually suspended components.
- **AI Integration**: AI actively generates a weekly written summary of anomalies and system growth.

### 2. Table Editor

- **Functionality**: Spreadsheet-like (Excel) view of database tables. Allows inline cell editing and schema alterations via a secondary sidebar.
    - **Sample Data Generation**: Ability to generate a full sample dataset mirroring Metabase's Sample Database (`Accounts`, `Products`, `Orders`, `Reviews`, `People`, `Invoices`). The generated data **must have strict foreign key relations** representing a realistic Entity-Relationship schema (e.g. `Orders` belongs to `Accounts` and `Products`, `Invoices` belong to `Orders`). The UI provides a live progress bar to track the background job's status.
    - **Visual Query Builder (Metabase Notebook style)**: Allows users to interactively analyze table data using visual transformation blocks instead of raw SQL. Includes features such as:
        - `Filter`: Build conditional where clauses.
        - `Summarize`: Group by columns and apply aggregate functions (Count, Sum, Avg).
        - `Join data`: Visually construct JOINs utilizing inferred foreign key relations.
        - `Custom column`: Create derived columns using math or string formulas.
        - `Sort` and `Row limit`: Configure ordering and pagination limit visually.
        - `Visualize`: A primary action button to render the resulting query into charts.
- **Backend**: Audit-log event sourcing and Postgres Metadata extraction. Background worker processing for heavy data seeding.
- **Frontend**: Utilizes `@tanstack/react-table` for highly performant Data Grid rendering and virtualized long scrolling. `Valtio` controls row-level optimistic updates. Displays loading progress bars for worker tasks. Integrates a visual notebook-style toolbar mimicking Metabase's data exploration UX.
- **AI Integration**: Identifies column data patterns, detects anomalies in user changes before submitting via Idempotency key interceptor.

### 3. SQL Editor

- **Functionality**: A rich text editor for writing raw SQL, saving snippets, and managing executions. Also acts as an advanced entrypoint for the visual Query Builder (converting SQL queries back-and-forth between visual blocks like Filter/Summarize when possible).
- **Backend**: Sandboxed Resilience execution. Safe block filters that reject DROP operations if user lacks permissions.
- **Frontend**: Integrates `Monaco Editor` via dynamic imports. Includes the familiar notebook-style `Editor` toggle allowing users to switch between raw SQL and visual step-by-step transformation blocks (Join, Filter, Summarize).
- **AI Integration (Natural Language to SQL)**: Users can type e.g., "Show me top 5 users who bought laptops last month", and the integrated LLM Agent interprets it based on the whitelisted schema context, generating the SQL query output and pasting it into Monaco.

### 4. Database Management

- **Functionality**: Advanced configuration of PostgreSQL Roles, Policies (RLS), and Triggers.
- **Backend**: Uses Saga Orchestrator to ensure consistency (e.g. creating role and validating DB grants atomically).
- **Frontend**: Forms built with `React Hook Form` and `Zod`.
- **AI Integration**: Validates and suggests optimized RLS policy rules before submission by understanding natural language safety requirements.

### 5. Storage

- **Functionality**: Interfacing with S3 APIs (AWS, Minio) to display and manage media.
- **Backend**: Clean Architecture Outbound ports pointing to S3 gateways.
- **Frontend**: `SortableJS` powered interactions and multi-part streaming components.
- **AI Integration**: Provides image generation suggestions or auto-tagging for imported documents.

### 6. Logs & Alerts

- **Functionality**: Continuous streams of application and database logs mimicking an integrated console.
- **Backend**: Taps into OpenTelemetry instrumentation traces.
- **Frontend**: Polling mechanism / Server-Sent Events parsing streaming chunks safely.
- **AI Integration**: An "Explain Error" button alongside high-severity logs that uses AI to break down the cause and outline remediation steps.

### 7. Project Settings

- **Functionality**: Application API Keys, general preferences, SSO configs.
- **Backend**: Strong Configuration validators.
- **Frontend**: Minimalist UI toggles and layout forms respecting Dark and Light themes cleanly.
- **AI Integration**: Audits the current settings and provides a "Security Score" utilizing LLM reviews against known misconfigurations.

### 8. Data Models (Semantic Layer)

- **Functionality**: Allows saving curated, simplified, and pre-joined queries (virtual tables) for non-technical users to access instead of raw schemas. Built upon the `Visual Query Builder` results. Mirrors Metabase's Models view.
- **Backend**: Models are serialized as JSON queries or SQL views, saving caching metadata and column configurations in PostgreSQL entities or an explicit Semantic Layer mapping.
- **Frontend**: A Model Browser grid mirroring `/browse/models` in Metabase, presenting Models as distinct cards with descriptions, owner, and dataset status. Clicking a model opens the `Table Editor` interface to interact with the pre-processed data.
- **AI Integration**: Suggests semantic data descriptions and auto-detects column classifications (e.g. tagging a calculated total as "Currency/Revenue"). Translates complex natural language intents into a saved Model pipeline.

## Metabase UI/UX Rules

- **Color**: Main action color is **Picton Blue (`#509EE3`)**.
- **Typography**: Header and body default to `Lato`.
- **Card Styling**: Inner padding `24px`, Radius `8px`, thin flat borders instead of intense shadow depths.
