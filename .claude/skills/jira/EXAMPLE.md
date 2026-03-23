# jira-skill — EXAMPLES

File này chứa các ví dụ minh họa cách áp dụng **jira-skill** trong các tình huống thực tế của dự án Data Visualizer.

## Ví dụ 1: Parse progress.md và phát hiện dependency chưa thỏa mãn

**Input** (trích từ progress.md):

```markdown
## Backlog — Sprint Plan

Sprint 2 — Table Editor: Schema Management
36 | Schema listing API (GET /api/schemas) | P0
37 | Schema selector dropdown | P0 | related_to: 36
38 | Index CRUD API | P1 | related_to: 36
40 | Collapsible Property Panel | P1 | related_to: 37
```
