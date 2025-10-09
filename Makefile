# Go Tutorial Project Makefile

.PHONY: help run build watch clean test fmt vet format check-style lint install-tools test-build

# Default target
help:
	@echo "🚀 Go Tutorial Project Commands:"
	@echo "  make run           - Chạy ứng dụng Go"
	@echo "  make build         - Build ứng dụng"
	@echo "  make watch         - Chạy với Air (auto-reload khi có thay đổi)"
	@echo "  make test          - Chạy tests"
	@echo "  make fmt           - Format code với go fmt"
	@echo "  make format        - Format code với gofmt + goimports"
	@echo "  make check-style   - Kiểm tra code style"
	@echo "  make lint          - Chạy linter (golangci-lint)"
	@echo "  make vet           - Kiểm tra code với go vet"
	@echo "  make install-tools - Cài đặt các tools cần thiết"
	@echo "  make test-build    - Test build và format system"
	@echo "  make clean         - Xóa các file build"

# Chạy ứng dụng
run:
	@echo "🏃 Chạy ứng dụng Go..."
	go run ./cmd/api

# Build ứng dụng
build:
	@echo "🔨 Building ứng dụng..."
	go build -buildvcs=false -o bin/main ./cmd/api
	@echo "✅ Build thành công! File: bin/main"

# Test build và format system
test-build:
	@echo "🧪 Testing build và format system..."
	@./test-build.sh

# Chạy với Air (watch mode)
watch:
	@echo "👀 Bắt đầu watch mode với Air..."
	@echo "📝 Air sẽ tự động rebuild khi bạn save file .go"
	air

# Chạy tests
test:
	@echo "🧪 Chạy tests..."
	go test -v ./...

# Format code với go fmt (basic)
fmt:
	@echo "🎨 Formatting code với go fmt..."
	go fmt ./...

# Format code với gofmt + goimports (advanced)
format:
	@echo "🎨 Formatting code với gofmt + goimports..."
	@./format-code.sh --fix

# Kiểm tra code style
check-style:
	@echo "🔍 Kiểm tra code style..."
	@./format-code.sh --check

# Chạy linter
lint:
	@echo "🔍 Chạy golangci-lint..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "⚠️  golangci-lint chưa được cài đặt. Chạy 'make install-tools' để cài đặt."; \
	fi

# Kiểm tra code
vet:
	@echo "🔍 Kiểm tra code với go vet..."
	go vet ./...

# Cài đặt các tools cần thiết
install-tools:
	@echo "📦 Cài đặt các tools cần thiết..."
	@echo "Installing goimports..."
	go install golang.org/x/tools/cmd/goimports@latest
	@echo "Installing golangci-lint..."
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@echo "Installing air..."
	go install github.com/cosmtrek/air@latest
	@echo "✅ Tất cả tools đã được cài đặt!"

# Clean build files
clean:
	@echo "🧹 Cleaning build files..."
	rm -rf bin/ tmp/
	go clean

# Install dependencies
deps:
	@echo "📦 Cài đặt dependencies..."
	go mod tidy
	go mod download

