## 1. Định dạng mã

- Sử dụng `go fmt` hoặc `gofumpt` để định dạng mã.
- Chạy `goimports` để quản lý import.

## 2. Quy tắc đặt tên

- Tên package ngắn gọn, rõ ràng, không dùng số nhiều (ví dụ: `user` thay vì `users`).
- Tên biến và hàm sử dụng camelCase, ngắn gọn và mô tả rõ ràng.

## 3. Kiểm tra chất lượng mã

- Sử dụng `golangci-lint` với cấu hình `.golangci.yml`.
- Kiểm tra mã trước khi commit bằng pre-commit hook.

## 4. Tham khảo

- [Google Go Style Guide](https://google.github.io/styleguide/go/)
- [Uber Go Style Guide](https://github.com/uber-go/guide/blob/master/style.md)
