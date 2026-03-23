---
name: saga
description: Implement and maintain distributed transaction orchestration with libs/src/ddd/saga, including SagaDefinition, SagaStep, reply header contract, idempotency, and compensation flow. Use when building or debugging saga orchestrators, participants, Kafka reply consumers, or cross-service consistency flows.
---

# Saga Skill (DDD + Kafka)

Use this skill for saga orchestration in `domain-driven-design`.

## Source Of Truth

Always align implementation with:

- `libs/src/ddd/saga/saga-definition.abstract.ts`
- `libs/src/ddd/saga/saga-step.builder.ts`
- `libs/src/ddd/saga/saga-manager.ts`
- `libs/src/ddd/saga/saga-message.parser.ts`
- `libs/src/ddd/saga/kafka-message-publisher.adapter.ts`
- `libs/src/ddd/saga/README.md`
- `src/application/order/saga/order-placement.saga.ts`
- `src/application/order/saga/order-placement-saga-reply.consumer.ts`
- `src/application/order/saga/order-placement-saga-participant.consumer.ts`

## When To Apply

Apply immediately when user asks to:

- add/update saga flow, step, compensation
- add participant command/reply handling
- troubleshoot saga not progressing or compensating
- define/validate reply headers contract
- handle idempotency for create commands

## Mandatory Conventions

1. **Use saga core abstractions only**
   - Orchestrator extends `SagaDefinition<TData extends Record<string, unknown>>`.
   - Steps use `SagaStep.create<TData>('StepName')`.
   - Start orchestration via `SagaManager.create(...)`.

2. **Stateless routing by headers**
   - Required command headers:
     - `command_reply_saga_id`
     - `command_reply_saga_type`
     - `command_reply_type`
     - `command_reply_reply_to`
     - `command_reply_destination`
   - Participant must echo these headers in reply.

3. **Reply outcome controls state**
   - `reply_outcome = SUCCESS` => forward to next step.
   - `reply_outcome = FAILURE` => `SagaManager` enters compensation path.

4. **Compensation explicit per side-effect step**
   - Remote step with side effect must define `compensate`.
   - If no compensation needed: `return null` or `{ command: null }`.
   - Local rollback is allowed with `{ isLocal: true }`.

5. **Idempotency mandatory**
   - `idempotencyId` is required in `SagaManager.create`.
   - For order-like flows, use `clientRef`.
   - Avoid duplicate aggregate writes by checking existing saga (`findByIdempotency`) before new write.

6. **Infrastructure boundary**
   - `libs/src/ddd/saga` must not define env key names.
   - `src/infrastructure/**` maps `ConfigService` keys to typed saga module options.

## Implementation Workflow

### Step 1: Define saga data model

- Create `MySagaData` in orchestrator file.
- Include business fields and technical fields (reservation IDs, rollback markers).
- Keep all cross-step mutable state in `TData`.

### Step 2: Implement orchestrator

- Create `MySaga extends SagaDefinition<MySagaData>`.
- Set `readonly sagaType`.
- Implement `steps()` with predictable sequence:
  1. optional local tracking step
  2. remote command steps
  3. local finalize step
- In each step:
  - `invoke`: build outgoing command
  - `handleReply`: merge returned data to `TData`
  - `compensate`: reverse side effects
  - `handleCompensationReply`: update rollback state if needed
- Add lifecycle logs in `emitCompleted` and `emitCompensated`.

### Step 3: Register saga module

- Register saga definition in domain/infrastructure module via:
  - `SagaModule.forKafka(...)`, or
  - `SagaModule.forKafkaAsync(...)` (preferred when config comes from infrastructure mapping layer).
- Ensure saga is included in `sagas: [MySaga]`.

### Step 4: Add reply consumer

- Create consumer extending `KafkaSagaReplyConsumerBase`.
- Subscribe topic `${sagaType}-reply`.
- Delegate handling to `processKafkaMessage(value, context)`.

### Step 5: Add participant consumer(s)

- Subscribe to command topics (e.g. `payment`, `inventory-service`).
- Parse command envelope `{ commandType, payload }`.
- Execute side effect, then publish reply with:
  - echoed `command_reply_*` headers
  - `reply_outcome`
  - `reply_type`
  - optional `data` payload
- Missing required saga headers => warn + skip (do not publish invalid reply).

### Step 6: Start saga from use case

- Use:
  - `sagaManager.findByIdempotency(...)` (optional pre-check)
  - `sagaManager.create({ sagaType, initialData, idempotencyId })`
- Pass stable business idempotency key (e.g. `clientRef`).

## Required Header And Trace Fields

Saga command publish headers must include:

- `command_reply_saga_id`
- `command_reply_saga_type`
- `command_reply_type`
- `command_reply_reply_to`
- `command_reply_destination`
- `sessionId` (and `session_id` for backward compatibility)
- `metadata` (trace metadata)

## OrderPlacement Reference Mapping

Use `OrderPlacementSaga` as implementation reference:

- Orchestrator: `order-placement.saga.ts`
- Reply consumer: `order-placement-saga-reply.consumer.ts`
- Participant: `order-placement-saga-participant.consumer.ts`
- Reply contract: `libs/src/ddd/saga/contracts/order-placement-saga-reply.contract.ts`

## Done Checklist

- [ ] Saga definition registered successfully at startup.
- [ ] Reply topic format is `${sagaType}-reply`.
- [ ] Participant replies echo all required saga headers.
- [ ] `reply_outcome` and `reply_type` are semantically correct.
- [ ] Compensation path is reverse-order and complete.
- [ ] Idempotency key prevents duplicate orchestration.
- [ ] Logs include sagaId, step name/index, outcome, and error stack.

## Additional Reference

Read detailed architecture and sequence diagrams in `@.claude/skills/saga/README.md`.
