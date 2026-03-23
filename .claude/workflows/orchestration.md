---
description: Workflow: Orchestration
---

### 1. Plan Node Default

- Bắt buộc vào chế độ lặp kế hoạch (PLANNING mode) cho bất kỳ task phức tạp nào (có từ 3 bước trở lên hoặc liên quan cấu trúc).
- Lập tức **DỪNG LẠI và Re-plan** nếu gặp lỗi dây chuyền - không cố đấm ăn xôi.
- Đọc file `docs/plan/progress.md` để nắm được Context hiện tại, lấy Task ID / Bug ID tương ứng trước khi làm.

### 2. Subagent Strategy & Role Delegation

- Phân tách công việc cho các agent chuyên trách (vd: `dv-frontend-developer`, `dv-backend-developer`).
- Dùng công cụ `browser_subagent` để tự động giả lập người dùng quyét lỗi UI/UX trên localhost.
- Mỗi agent chỉ thực hiện 1 scope công việc duy nhất để tránh phình to context.

### 3. Verification Before Done (BẮT BUỘC)

- Không bao giờ đánh dấu Done khi chưa chứng minh code hoạt động.
- Chạy các lệnh kiểm thử chuẩn (vd: `pnpm format`, `pnpm lint`, `pnpm test`).
- Kiểm tra lại kiến trúc (DDD, Code style, Exception Handling) theo tài liệu dự án để đảm bảo "Staff Engineer standard".

### 4. Git Workflow & Version Control

- Áp dụng chặt chẽ `git-workflow-skill`: KHÔNG push trực tiếp lên `main`/`develop`.
- Sau khi Verification thành công, tự động tạo Branch name và Commit message chuẩn **Conventional Commits** (kèm Task ID lấy từ progress.md).

### 5. Autonomous Bug Fixing

- Khi nhận 1 bug, tự động tìm Root Cause thông qua Logs, Errors, Test failures và tự động Code Fix.
- Không hỏi người dùng cách fix trừ khi rủi ro (Risk) quá cao hoặc ảnh hưởng requirement gốc.
- Nếu gặp lỗi lạ, tra cứu thư mục `.claude/skills` để tìm giải pháp thay vì đoán mò.

### 6. Database Connection Handling

- Khi tiến hành xử lý connect multi database, change database hoặc các task, bug, refactor liên quan đến `docs/modules/database-connections`, BẮT BUỘC phải đọc các script connect trong thư mục `.claude/scripts` (vd: `access-mysql.sh`, `access-mongodb.sh`, `access-supabase.sh`) trước khi thực hiện để nắm rõ thông tin kết nối và conventions.

## Task Management (Sự dụng AI Artifacts)

1. **Plan First**: Ghi thiết kế kỹ thuật vào `implementation_plan.md` và xin user duyệt.
2. **Breakdown Task**: Liệt kê các công việc (checklist) vào `task.md`.
3. **Execute & Track**: Cập nhật trạng thái `task.md` liên tục (chuyển [ ] sang [x]) trong chế độ EXECUTION.
4. **Update Progress Log**: Nếu tìm được bug hoặc hoàn thiện task, cập nhật vào file tracking báo cáo tổng trong `docs/plan/progress.md`.
5. **Document Results**: Tóm tắt quá trình, chụp màn hình/kết quả test và ghi vào file `walkthrough.md`.

## Core Principles

- **Simplicity First**: Làm mọi thứ đơn giản và gọn gàng nhất. Thay đổi ít code nhất có thể.
- **No Laziness**: Tìm Root Cause thay vì fix tạm (workaround).
- **Demand Elegance**: Nếu một logic đang phức tạp thái quá, hãy tạm dừng và cấu trúc lại sao cho thanh lịch.
