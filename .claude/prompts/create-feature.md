# Create Complete Feature

Use this prompt to create a complete feature from scratch.

## Prompt Template
```
Create a complete {{FEATURE_NAME}} feature for the {{CONTEXT}} bounded context.

Requirements:
1. Domain Layer:
   - {{AGGREGATE_NAME}} aggregate with properties: {{PROPERTIES}}
   - Value objects: {{VALUE_OBJECTS}}
   - Domain events: {{EVENTS}}
   - Repository interface (port)

2. Application Layer:
   - Create{{Entity}}UseCase
   - Update{{Entity}}UseCase
   - Delete{{Entity}}UseCase
   - Get{{Entity}}Query
   - List{{Entity}}Query

3. Infrastructure:
   - {{Entity}}Repository extending BaseRepositoryTypeORM
   - {{Entity}}OrmEntity with TypeORM decorators
   - Database migration

4. Presentation:
   - {{Entity}}Controller with all CRUD endpoints
   - DTOs: Create{{Entity}}Dto, Update{{Entity}}Dto, {{Entity}}ResponseDto
   - Swagger documentation

5. Tests:
   - Unit tests for aggregate
   - Integration tests for use cases
   - E2E tests for endpoints

Follow rules.md and use patterns from .claude/PATTERNS.md
```

## Example Usage
```
Create a complete Dashboard feature for the dashboard bounded context.

Requirements:
1. Domain Layer:
   - Dashboard aggregate with properties: name, description, visibility, autoRefreshInterval, filters, layoutConfig
   - Value objects: DashboardName, RefreshInterval
   - Domain events: DashboardCreated, DashboardUpdated, CardAddedToDashboard, CardRemovedFromDashboard
   - Repository interface (port)

2. Application Layer:
   - CreateDashboardUseCase
   - UpdateDashboardUseCase
   - DeleteDashboardUseCase
   - AddCardToDashboardUseCase
   - RemoveCardFromDashboardUseCase
   - GetDashboardQuery
   - ListDashboardsQuery

3. Infrastructure:
   - DashboardRepository extending BaseRepositoryTypeORM
   - DashboardOrmEntity with TypeORM decorators
   - Database migration for dashboards and dashboard_cards tables

4. Presentation:
   - DashboardController with all CRUD endpoints
   - DTOs: CreateDashboardDto, UpdateDashboardDto, AddCardDto, DashboardResponseDto
   - Swagger documentation

5. Tests:
   - Unit tests for Dashboard aggregate
   - Integration tests for all use cases
   - E2E tests for all endpoints

Follow rules.md and use patterns from .claude/PATTERNS.md
```