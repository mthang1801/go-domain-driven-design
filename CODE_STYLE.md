# Go Code Style Guide

Hướng dẫn sử dụng code style chuẩn với gofmt trong dự án Go Tutorial.

## 🎯 Mục tiêu

Đảm bảo code Go trong dự án tuân thủ các chuẩn:
- **gofmt**: Format code theo chuẩn Go
- **goimports**: Tự động sắp xếp và quản lý imports
- **golangci-lint**: Kiểm tra code quality và style

## 📁 Cấu trúc file

```
go-tutorial/
├── .gofmt.yaml          # Cấu hình gofmt
├── .golangci.yaml       # Cấu hình linter
├── .editorconfig        # Cấu hình editor
├── format-code.sh       # Script format code
├── Makefile            # Build commands
└── .git/hooks/pre-commit # Git hook kiểm tra trước commit
```

## 🚀 Cách sử dụng

### 1. Cài đặt tools cần thiết

```bash
make install-tools
```

Hoặc cài đặt thủ công:
```bash
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

### 2. Format code

#### Sử dụng Makefile (khuyến nghị)
```bash
# Format code với gofmt + goimports
make format

# Chỉ kiểm tra format (không sửa)
make check-style

# Format cơ bản với go fmt
make fmt
```

#### Sử dụng script trực tiếp
```bash
# Format tất cả file
./format-code.sh --fix

# Kiểm tra format
./format-code.sh --check

# Format với backup
./format-code.sh --backup

# Xem chi tiết
./format-code.sh --verbose

# Chạy thử (không thay đổi file)
./format-code.sh --dry-run
```

### 3. Chạy linter

```bash
make lint
```

### 4. Kiểm tra toàn bộ

```bash
# Format + Lint + Test
make format && make lint && make test
```

## 🔧 Cấu hình

### .gofmt.yaml
- Cấu hình các quy tắc format cho gofmt
- Thiết lập độ dài dòng tối đa: 120 ký tự
- Sử dụng tab cho indentation
- Tự động simplify code

### .golangci.yaml
- Cấu hình các linter được sử dụng
- Thiết lập rules cho từng linter
- Loại trừ một số file/pattern không cần kiểm tra

### .editorconfig
- Cấu hình editor để tự động format
- Thiết lập indentation cho các loại file khác nhau
- Đảm bảo consistency giữa các editor

## 🎨 Code Style Rules

### 1. Formatting
- Sử dụng tab cho indentation (4 spaces)
- Độ dài dòng tối đa: 120 ký tự
- Tự động simplify code expressions
- Loại bỏ dấu ngoặc đơn không cần thiết

### 2. Imports
- Nhóm imports: standard library, third-party, local
- Sắp xếp imports alphabetically trong mỗi nhóm
- Tự động loại bỏ unused imports

### 3. Naming
- Sử dụng camelCase cho variables và functions
- Sử dụng PascalCase cho exported types và functions
- Tên ngắn gọn nhưng có ý nghĩa

### 4. Comments
- Mỗi exported function/type phải có comment
- Comment bắt đầu bằng tên của function/type
- Sử dụng // cho single line comments

### 5. Error Handling
- Luôn kiểm tra và xử lý errors
- Sử dụng fmt.Errorf() cho custom errors
- Return errors thay vì panic

## 🔄 Git Hooks

### Pre-commit Hook
Tự động chạy khi commit:
1. Kiểm tra và format code với gofmt + goimports
2. Chạy linter (golangci-lint)
3. Chạy tests (optional)
4. Từ chối commit nếu có lỗi

### Cách hoạt động
```bash
git add .
git commit -m "feat: add new feature"
# Pre-commit hook sẽ tự động chạy
```

## 📋 Checklist trước khi commit

- [ ] Code đã được format với `make format`
- [ ] Linter passed với `make lint`
- [ ] Tests passed với `make test`
- [ ] Comments đầy đủ cho exported functions/types
- [ ] Error handling đúng cách
- [ ] Naming conventions được tuân thủ

## 🛠️ Troubleshooting

### Lỗi "command not found"
```bash
# Cài đặt lại tools
make install-tools
```

### Lỗi linter
```bash
# Xem chi tiết lỗi
golangci-lint run --verbose

# Sửa lỗi cụ thể
golangci-lint run --fix
```

### Pre-commit hook không hoạt động
```bash
# Kiểm tra quyền thực thi
ls -la .git/hooks/pre-commit

# Cài đặt lại quyền
chmod +x .git/hooks/pre-commit
```

## 📚 Tài liệu tham khảo

- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Effective Go](https://golang.org/doc/effective_go.html)
- [gofmt Documentation](https://golang.org/cmd/gofmt/)
- [golangci-lint Documentation](https://golangci-lint.run/)

## 🤝 Đóng góp

Khi đóng góp code:
1. Đảm bảo tuân thủ code style guide này
2. Chạy `make format && make lint` trước khi commit
3. Viết tests cho code mới
4. Cập nhật documentation nếu cần

---

**Lưu ý**: Hệ thống này được thiết kế để đảm bảo code quality và consistency. Hãy sử dụng thường xuyên để duy trì chuẩn code trong dự án.
