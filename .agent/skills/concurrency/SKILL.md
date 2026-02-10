---
name: Go Concurrency Patterns
description: Patterns for concurrent execution, worker pools, and pipelines
---

## Concepts
- Worker pool
- errgroup (fan-out/fan-in)
- Pipeline
- Semaphore rate limiting
- Timeout & cancellation
- Query Builder specific: auto-refresh, CSV import progress

## Example

```go
// ✅ GOOD: errgroup for parallel execution
g, ctx := errgroup.WithContext(ctx)
g.SetLimit(10)

for _, card := range cards {
    card := card
    g.Go(func() error {
        return executeCard(ctx, card)
    })
}

g.Wait()
```
