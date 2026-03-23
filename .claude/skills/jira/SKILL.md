---
name: jira
description: Jira-style task, backlog, and dependency management for Data Visualizer. Use this skill whenever the work involves `progress.md`, `backlog.md`, sprint planning, task dependencies, blockers, status transitions, or choosing the next task based on readiness and priority, even if the user does not explicitly mention Jira.
---

# jira-skill — Jira-style Task & Dependency Management cho Data Visualizer

## Mục đích

- Duy trì lịch sử task đầy đủ (không tự động xóa hoặc thay thế Sprint cũ bằng tóm tắt).
- Xây dựng và quản lý **dependency graph** giữa task, bug, changelogs (giống Jira: depends_on, blocks, related_to, epic_link).
- Tự động gợi ý thứ tự thực hiện dựa trên dependencies + priority + progress.
- Hỗ trợ cập nhật progress.md với định dạng chuẩn (giữ lịch sử, thêm liên kết).
- Tích hợp với DV-Orchestrator để khi lập plan: ưu tiên task "ready to start" (dependencies đã done).

## Quy tắc cốt lõi (Mandatory)

1. **Không bao giờ xóa task cũ** — Sprint cũ phải giữ nguyên danh sách task, chỉ thêm trạng thái "DONE" hoặc "Moved to Sprint X".
2. **Liên kết tham chiếu**:
    - `depends_on`: Task này phải chờ task kia hoàn thành (blocking).
    - `blocks`: Task này chặn task kia.
    - `related_to`: Liên quan nhưng không blocking (ví dụ: bug fix liên quan feature).
    - `epic_link`: Nhóm task vào Epic (ví dụ: Epic "Table Editor Schema Management").
3. **Trạng thái task** (giống Jira):
    - To Do / In Progress / Done / Blocked / Review Needed
4. **Cập nhật progress.md**:
    - Giữ bảng Completed nguyên vẹn (thêm dòng mới nếu cần).
    - In Progress: Chỉ liệt kê task đang active.
    - Bugs Found: Giữ nguyên bảng, thêm cột "Related Tasks" (ví dụ: #B2 related to #44, #45).
    - **BẮT BUỘC GÁN AGENT**: Các cột `Assignee` và `Reporter` không được để trống. Phải gán tên agent cụ thể (ví dụ `@dv-backend-developer` cho Assignee, `@dv-orchestrator` cho Reporter).
5. **Dependency resolution**:
    - Task chỉ được đưa vào plan nếu tất cả `depends_on` đều Done.
    - Nếu có Blocked → ưu tiên fix blocker trước (gợi ý dv-debugger hoặc dv-refactor-specialist).

## Cách sử dụng skill trong agent

Khi agent được giao task liên quan đến backlog/progress:

1. Đọc progress.md và backlog.md (dùng code_execution nếu cần parse bảng markdown).
2. Xây dựng dependency graph (dùng dict hoặc networkx nếu có tool).
3. Gợi ý task tiếp theo:
    - Ưu tiên: Blocked task có blocker Done → fix blocker.
    - Sau đó: Task có priority cao nhất mà dependencies đã Done.
    - Cuối: Review nếu có code mới.
4. Khi hoàn thành task:
    - Cập nhật progress.md: thêm dòng vào Completed, chuyển từ In Progress sang Done.
    - Thêm liên kết: "Related to #XX", "Blocks #YY", "Depends on #ZZ".

## Output format khi dùng skill (cho orchestrator hoặc agent)

Khi skill được gọi, trả về YAML bổ sung vào plan:

```yaml
jira_update:
    current_epic: 'Sprint 2 - Table Editor Schema Management'
    recommended_next:
        - task_id: 36
          title: 'Schema listing API (GET /api/schemas)'
          status: 'To Do'
          priority: 'P0'
          depends_on: []
          blocks: [37, 40]
    blockers:
        - bug_id: B2
          related_tasks: [44, 45]
          status: 'Open'
    progress_suggestion:
        - 'Cập nhật progress.md: Task 36 → In Progress'
```
