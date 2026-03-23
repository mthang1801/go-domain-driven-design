# 10 - Notifications & Event Hooks

> **Priority:** Low | **Complexity:** Low
> **Estimated Time:** 2 days

## Summary | Tóm tắt

**EN:** Define hooks and notification pathways to inform admins/users when asynchronous tasks (like a large Stream Pipeline Import or a Heavy Export) have completed.

**VI:** Xác lập các Webhooks và Event nhằm thông báo trực tiếp đến Quản trị viên khi các tác vụ nặng chạy song song (ví dụ Stream Pipeline cho CSV Import hoặc chạy lệnh trích xuất nặng) hoàn thành.

---

## Proposed Changes | Các thay đổi đề xuất

### 10.1 Domain Events

**Files:** `src/domain/data-builder/events/`

**EN:**

- Document standard `BaseDomainEvents` fired on View Creation, View Deletion.
- Leverage the `@ddd/domain` Core Domain Event Dispatcher setup in memory whenever an aggregate is saved.

**VI:**

- Viết các file Domain Event (vd `ViewCreatedEvent`) được bắn khi tạo View mới.
- Khai thác Domain Event Dispatcher (từ DDD core) trên bộ nhớ ảo khi repository được `.save()`.

### 10.2 Server-Sent Events (SSE)

**File:** `src/presentation/portal/data-builder/gateways/import.gateway.ts`

**EN:**

- Push real-time progress events from the Import Engine queue updates back via Server-Sent Events (SSE) or WebSockets to display progress bars dynamically in the frontend UI.

**VI:**

- Push event thời gian thực về phần trăm file xử lý của công cụ Import Engine qua Server-Sent Events (SSE) hoặc WebSockets tới UI.

## Verification | Xác minh

- Progress bar updates dynamically on frontend without explicit user polling requests.
