---
name: idempotency-key
description: 'Implementation guide for Idempotency Keys in NestJS to prevent duplicate requests.'
---

# Idempotency Key Pattern

## Overview

The Idempotency Key pattern ensures that multiple identical requests from a client (e.g., due to network retries, double-clicks) result in only a single execution of the operation on the server. This is critical for mutating operations like creating orders, processing payments, or triggering complex aggregations.

## Implementation Guidelines

### 1. Request Header

Clients MUST send a unique identifier in the `Idempotency-Key` HTTP header for all mutating API requests (`POST`, `PUT`, `PATCH`, `DELETE`). UUIDv4 is recommended.

### 2. NestJS Interceptor/Guard

Implement an `IdempotencyInterceptor` or use an existing implementation to capture the `Idempotency-Key` and the request payload.

### 3. State Management (Redis)

Store the idempotency state in a fast, distributed cache like Redis.
Use a multi-state machine for each key:

- `PENDING`: Request is currently being processed. If another request with the same key arrives, return `409 Conflict` (or wait and return the cached response).
- `COMPLETED`: Request finished successfully. Store the HTTP status and response body. Return this cached response for subsequent identical requests.
- `FAILED`: Request failed due to a server error or validation. Typically, you may allow the key to be retried by abandoning the state, or returning the cached `400/500` response depending on business rules.

### 4. TTL (Time to Live)

Idempotency keys should not be stored forever. A standard TTL is 24 hours.

## Example Usage in NestJS

```typescript
import { Controller, Post, UseInterceptors, Body } from '@nestjs/common';
import { IdempotencyInterceptor } from '@infrastructure/idempotency';

@Controller('data-builder')
export class DataBuilderController {
    @Post('create-view')
    @UseInterceptors(IdempotencyInterceptor)
    async createView(@Body() payload: CreateViewDto) {
        // Business logic runs exactly once per Idempotency-Key
        return this.service.create(payload);
    }
}
```

## Anti-Patterns

- **Do not use for `GET` requests**: `GET` requests are idempotent by nature and usually rely on HTTP caching, not manual idempotency keys.
- **Do not ignore payload changes**: If an `Idempotency-Key` matches, but the payload is completely different, return `400 Bad Request` or `422 Unprocessable Entity` indicating an idempotency mismatch.
