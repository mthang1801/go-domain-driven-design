---
description: Quy trình làm việc của Hệ thống 10 AI Agents (Agentic Team Workflow)
---

# Agentic Team Workflow

Tài liệu này định nghĩa quy trình phối hợp hoạt động của hệ sinh thái 10 AI Agents trong toàn bộ vòng đời phát triển phần mềm (SDLC) của dự án. Mục tiêu là tối đa hoá tính tự động, giữ vững chất lượng code, hướng dẫn developer và đảm bảo sự ổn định của hệ thống.

---

## Danh Sách 10 AI Agents Chuyên Trách

1. **Onboarding Agent**: Trợ lý hướng dẫn thành viên mới, setup môi trường và giải thích kiến trúc dự án.
2. **Wiki-AI**: Agent tích hợp RAG, đóng vai trò như bộ não toàn thư của công ty để trả lời các câu hỏi về domain, logic và tài liệu nội bộ.
3. **PR Describer**: Trợ lý tự động viết mô tả cho Pull Request dựa trên code diff và commit messages.
4. **Test Generator**: Trợ lý đọc code mới/thay đổi và tự động sinh Unit Tests và Integration Tests.
5. **Doc Generator**: Trợ lý tự động sinh và cập nhật 8 loại tài liệu từ PRD/Code (API Docs, Technical Specs, v.v.).
6. **Code Reviewer**: Trợ lý tự động review PR, phát hiện lỗi logic, anti-pattern, và vi phạm convention.
7. **Security Scanner**: Trợ lý tự động quét mã nguồn để đảm bảo không có lỗ hổng bảo mật (Injection, rò rỉ secret, CVE trên package...).
8. **DB Migration**: Trợ lý review các thay đổi liên quan đến Database Schema (Prisma/TypeORM/Supabase), đảm bảo hiệu năng và không lock table.
9. **Monitoring Agent**: Trợ lý giám sát sức khỏe hệ thống (logs, metrics) trên server theo thời gian thực.
10. **Incident Agent**: Trợ lý phát hiện sự cố, chẩn đoán nguyên nhân gốc rễ (root cause) dựa trên cảnh báo từ Monitoring, và đưa ra gợi ý fix lỗi hoặc rollback.

---

## Luồng Quy Trình Hoạt Động (End-to-End Flow)

### Phase 1: Chuẩn Bị & Bắt Đầu Code (Discovery & Development)

- **(1) Khám phá kiến thức:** Lập trình viên mới có thể chat với **Onboarding Agent** để làm quen với cấu trúc thư mục, lệnh khởi chạy, các skills/công cụ đang có.
- **(2) Tra cứu nghiệp vụ:** Trong lúc code nghiệp vụ phức tạp, developer có thể hỏi **Wiki-AI** để tra cứu luồng hoạt động cũ, quy trình nghiệp vụ đã quy định từ trước thay vì phải tốn thời gian lùng sục tài liệu rải rác.

### Phase 2: Tạo Pull Request & Bổ Sung Tự Động (PR Creation & Augmentation)

- **(3) Bắt đầu PR:** Developer hoàn thành code và push lên nhánh mới. Ngay lập tức, hệ thống kích hoạt **PR Describer** để tổng hợp diff thành một PR Description mạch lạc, chuyên nghiệp.
- **(4) Bao phủ Code (Coverage):** **Test Generator** tự động chạy qua những đoạn code chưa có test tương ứng để sinh mã Unit/Integration Test, có thể đính kèm dưới dạng các đề xuất commit (suggestions).
- **(5) Cập nhật Tài Liệu:** Tính năng mới sẽ được **Doc Generator** đọc và đồng bộ hóa lại các API Docs, User Manual và Technical Architecture để tài liệu luôn sát với code nhất.

### Phase 3: Review & Đánh Giá An Toàn (Review & Validation)

Khi nhánh bắt đầu được review, các Agent sẽ hoạt động song song để kiểm tra từng khía cạnh:

- **(6) Review Chất Lượng Code:** **Code Reviewer** kiểm duyệt thiết kế (ví dụ: vi phạm Clean Architecture / DDD, vòng lặp thừa thãi).
- **(7) Review Database:** Nếu PR chạm vào cơ sở dữ liệu, **DB Migration Agent** kiểm tra các file migrate. Việc thêm cột, xoá cột, đánh index hay đổi kiểu dữ liệu sẽ được Agent xem xét kỹ để ngăn ngừa downtime hoặc deadlocks.
- **(8) Review Bảo Mật:** **Security Scanner** kiểm tra các lỗ hổng như không check quyền, input validation thiếu, hoặc dependency bị lỗi bảo mật.

=> Nếu có lỗi hoặc rủi ro, các Agents sẽ commment trực tiếp vào dòng code sai trong Pull Request để developer kịp thời điều chỉnh trước khi Merge.

### Phase 4: Vận Hành & Ứng Cứu Sự Cố (Production & Maintenance)

- **(9) Theo dõi chủ động:** Tính năng được đưa lên môi trường hoạt động. **Monitoring Agent** túc trực phân tích các logs và metric (CPU, Ram, Latency, Error rate).
- **(10) Khắc phục tự động:** Nhận thấy traffic tăng vọt đồng thời Error code 5xx gia tăng, **Monitoring Agent** cảnh báo cho **Incident Agent**. **Incident Agent** lập tức kết nối log lỗi tới commit gần nhất, chẩn đoán lỗi xảy ra ở module nào, và gợi ý 1 đoạn fix code nhanh hoặc chạy lệnh rollback để hệ thống phục hồi bình thường.

---

## Tiêu Chuẩn Thực Thi (Execution Standards)

- Các Agent hoạt động ở môi trường Pipeline (CI/CD) hoặc thông qua local hooks.
- Đối với nhóm Agent (PR Describer, Test Generator, Doc Generator, Code Reviewer, Security Scanner, DB Migration): KHÔNG thực hiện tự động merge nhánh. Luôn đóng vai trò người đánh giá/người đề xuất (Reviewer/Suggester) cần xác nhận của Human.
- Incident Agent sẽ được cấp quyền theo cấp độ nguy hiểm (Group 1 vs Group 2 actions ở AGENTS.md), gửi qua Slack hoặc cảnh báo trung tâm trước khi thực hiện fix.
