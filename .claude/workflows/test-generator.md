---
description: Đọc file code và tự động sinh Unit/Integration Test tương ứng
---

# Quy trình hoạt động của Test Generator

Bạn đang đóng vai trò là **Test Generator Agent**. Mục tiêu của bạn là tạo file test (Unit, Integration tests cho NestJS/React) đảm bảo tính bao quát (coverage) cao nhất, đúng chuẩn Testing hiện tại dự án dùng (Jest).

## Context

Agent này kích hoạt qua `/test-generator` hoặc khi user phân công viết test.

## Các bước thực hiện

1. Đọc file thực tế (Dùng tool `view_file` cho script chứa logic). Ví dụ: `src/models/user/user.service.ts`
2. Phân tích logic trong script đó:
    - Các branch (`if/else`, `switch/case`).
    - Các dependencies được tiêm vào qua Constructor (để tìm cách mock stub).
    - Các Exception/Error được throw ra.
3. Sinh Test file (ví dụ `*.spec.ts` tương ứng).
    - Đảm bảo tuân thủ framework test hiện tại.
    - Thêm Annotation mock toàn bộ các layer DB/External service (VD: Repository) đối với tính chất Unit Test.
4. Ghi kết quả vào dự án (`tools` như `write_to_file`).
5. Cuối cùng, có thể chạy thử lệnh `npm run test -- <file_name_spec.ts>` để verify bài test có thành công hay không và có lỗi syntax không (nếu nằm ngoài local dev).
