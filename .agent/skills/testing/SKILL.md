---
name: Go Testing Strategies
description: Testing patterns including unit, integration, and E2E tests
---

## Strategy
- Testing pyramid (70/20/10)
- testcontainers for integration tests
- Mocking with testify
- Benchmarking
- Race detection
- Coverage targets (>75%)

## Examples

```go
// ✅ GOOD: Integration test with testcontainers
func TestIntegration(t *testing.T) {
    ctx := context.Background()
    
    // Start PostgreSQL in Docker
    pgContainer, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: testcontainers.ContainerRequest{
            Image: "postgres:15",
            Env: map[string]string{
                "POSTGRES_USER": "user",
                "POSTGRES_PASSWORD": "password",
                "POSTGRES_DB": "testdb",
            },
        },
    })
    
    // ... setup database, run migrations, test repository
}
```

```go
// ✅ Integration test with real PostgreSQL
func TestRepository_Save(t *testing.T) {
    pgContainer, _ := postgres.RunContainer(ctx, ...)
    defer pgContainer.Terminate(ctx)
    
    db, _ := sql.Open("postgres", connString)
    repo := NewUserRepositoryImpl(db)
    
    err := repo.Save(ctx, user)
    assert.NoError(t, err)
}
```

## Performance Targets

| Metric | Target | Achieved via |
|--------|--------|-------------|
| Query execution | <50ms P99 | Connection pooling, caching |
| Dashboard (5 cards) | <250ms | Parallel execution |
| CSV import | 50k rows/sec | Streaming + COPY |
| Memory (10GB CSV) | <50MB | Streaming |
| Concurrent users | 5000+ | Worker pools |
