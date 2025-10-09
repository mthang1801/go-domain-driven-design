# 🚀 Go Tutorial Project

Project Go với tính năng **auto-reload** sử dụng Air.

## ✨ Tính năng

- 🔄 **Auto-reload**: Tự động rebuild và restart khi có thay đổi code
- 🛠️ **Hot reload**: Không cần dừng và chạy lại ứng dụng
- 📁 **Cấu trúc project**: Tổ chức code theo best practices
- 🎯 **Makefile**: Các lệnh tiện ích để phát triển

## 🚀 Cách sử dụng

### 1. Chạy với Watch Mode (Khuyến nghị)
```bash
make watch
```
hoặc
```bash
air
```

### 2. Chạy thông thường
```bash
make run
```

### 3. Build ứng dụng
```bash
make build
```

### 4. Chạy tests
```bash
make test
```

### 5. Format code
```bash
make fmt
```

## 📁 Cấu trúc project

```
go-tutorial/
├── main.go              # Entry point
├── utils/
│   └── helper.go        # Utility functions
├── .air.toml           # Cấu hình Air
├── Makefile            # Build commands
├── go.mod              # Go modules
└── README.md           # Documentation
```

## 🔧 Cấu hình Air

File `.air.toml` chứa cấu hình cho Air:
- **Watch**: Theo dõi các file `.go`, `.html`, `.tpl`
- **Exclude**: Bỏ qua thư mục `tmp`, `vendor`, `testdata`
- **Build**: Tự động build khi có thay đổi
- **Delay**: 1 giây delay trước khi rebuild

## 🎯 Demo

1. Chạy `make watch`
2. Mở file `main.go` hoặc `utils/helper.go`
3. Thay đổi code và save
4. Xem Air tự động rebuild và restart ứng dụng!

## 📝 Lưu ý

- Air sẽ tạo thư mục `tmp/` để chứa file build
- Logs sẽ được ghi vào `build-errors.log`
- Sử dụng `make clean` để xóa các file build

