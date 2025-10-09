# 👀 Hướng dẫn sử dụng Watch Mode

## 🚀 Bắt đầu nhanh

1. **Mở terminal và chuyển đến thư mục project:**
   ```bash
   cd /home/mvt/Repositories/Go/go-tutorial
   ```

2. **Chạy watch mode:**
   ```bash
   make watch
   ```
   hoặc
   ```bash
   air
   ```

3. **Mở file code trong editor và bắt đầu code!**

## 🎯 Demo tính năng Watch

### Test 1: Thay đổi main.go
1. Mở file `main.go`
2. Thay đổi dòng 11: `"🚀 Go Tutorial Project đang chạy!"` thành `"🔥 Hot Reload đang hoạt động!"`
3. Save file (Ctrl+S)
4. Xem Air tự động rebuild và restart!

### Test 2: Thay đổi utils/helper.go
1. Mở file `utils/helper.go`
2. Thay đổi function `GreetUser` để trả về message khác
3. Save file
4. Xem ứng dụng tự động cập nhật!

### Test 3: Thêm file mới
1. Tạo file mới `calculator.go` trong thư mục gốc
2. Thêm function tính toán
3. Import và sử dụng trong `main.go`
4. Air sẽ tự động detect và rebuild!

## 📁 Các file được watch

Air sẽ theo dõi các file có extension:
- `.go` - Go source files
- `.html` - HTML templates
- `.tpl` - Template files
- `.tmpl` - Template files

## 🚫 Các file/thư mục bị ignore

- `tmp/` - Thư mục build
- `vendor/` - Dependencies
- `testdata/` - Test data
- `*_test.go` - Test files

## ⚙️ Cấu hình Air

File `.air.toml` chứa tất cả cấu hình:
- **Delay**: 1000ms trước khi rebuild
- **Include/Exclude**: Các file được theo dõi
- **Build command**: `go build -o ./tmp/main .`
- **Log**: Ghi lỗi vào `build-errors.log`

## 🛠️ Troubleshooting

### Air không chạy được
```bash
# Kiểm tra Air đã được cài đặt chưa
which air

# Cài đặt lại Air
go install github.com/air-verse/air@latest
```

### Build lỗi
```bash
# Kiểm tra Go modules
go mod tidy

# Kiểm tra syntax
go vet ./...
```

### Không detect thay đổi
- Đảm bảo file có extension được support
- Kiểm tra file không nằm trong exclude list
- Restart Air nếu cần

## 🎉 Tips & Tricks

1. **Sử dụng Makefile**: `make watch` thay vì `air`
2. **Multiple terminals**: Mở terminal riêng cho Air và editor
3. **Log monitoring**: Xem `build-errors.log` khi có lỗi
4. **Hot reload**: Thay đổi nhỏ sẽ reload nhanh hơn

## 📝 Lệnh hữu ích

```bash
# Chạy watch mode
make watch

# Chạy thông thường
make run

# Build
make build

# Format code
make fmt

# Clean
make clean

# Test
make test
```

Happy coding! 🚀

