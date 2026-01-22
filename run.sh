#!/usr/bin/env zsh

# Go Tutorial Project Runner Script
# Sử dụng zsh để chạy project

echo "🚀 Go Tutorial Project - Zsh Runner"
echo "=================================="

# Set working directory
cd /home/mvt/Repositories/Go/go-tutorial

# Check if we're in the right directory
if [[ ! -f "go.mod" ]]; then
    echo "❌ Không tìm thấy go.mod. Đang ở sai thư mục?"
    exit 1
fi

echo "📁 Working directory: $(pwd)"
echo "🔧 Go version: $(go version)"

# Function to run the project
run_project() {
    echo "🏃 Chạy project..."
    go run main.go
}

# Function to run with air (watch mode)
run_watch() {
    echo "👀 Chạy watch mode với Air..."
    if command -v air &> /dev/null; then
        air
    else
        echo "❌ Air chưa được cài đặt. Cài đặt với: go install github.com/air-verse/air@latest"
        exit 1
    fi
}

# Function to build project
build_project() {
    echo "🔨 Building project..."
    mkdir -p bin
    go build -o bin/main main.go
    if [[ $? -eq 0 ]]; then
        echo "✅ Build thành công! File: bin/main"
    else
        echo "❌ Build thất bại!"
        exit 1
    fi
}

# Function to test project
test_project() {
    echo "🧪 Testing project..."
    go test -v ./...
}

# Function to format code
format_code() {
    echo "🎨 Formatting code..."
    go fmt ./...
    echo "✅ Code đã được format!"
}

# Function to clean build files
clean_project() {
    echo "🧹 Cleaning build files..."
    rm -rf bin/ tmp/
    go clean
    echo "✅ Cleaned!"
}

# Main menu
show_menu() {
    echo ""
    echo "Chọn một tùy chọn:"
    echo "1) Chạy project"
    echo "2) Chạy watch mode (Air)"
    echo "3) Build project"
    echo "4) Test project"
    echo "5) Format code"
    echo "6) Clean build files"
    echo "7) Exit"
    echo ""
}

# Handle user input
handle_input() {
    printf "Nhập lựa chọn (1-7): "
    if ! read -r choice; then
        echo ""
        echo "👋 Tạm biệt!"
        exit 0
    fi
    
    case $choice in
        1)
            run_project
            ;;
        2)
            run_watch
            ;;
        3)
            build_project
            ;;
        4)
            test_project
            ;;
        5)
            format_code
            ;;
        6)
            clean_project
            ;;
        7)
            echo "👋 Tạm biệt!"
            exit 0
            ;;
        *)
            echo "❌ Lựa chọn không hợp lệ!"
            ;;
    esac
}

# Check if argument provided
if [[ $# -gt 0 ]]; then
    case $1 in
        "run")
            run_project
            ;;
        "watch")
            run_watch
            ;;
        "build")
            build_project
            ;;
        "test")
            test_project
            ;;
        "fmt")
            format_code
            ;;
        "clean")
            clean_project
            ;;
        *)
            echo "❌ Argument không hợp lệ!"
            echo "Sử dụng: $0 [run|watch|build|test|fmt|clean]"
            exit 1
            ;;
    esac
else
    # Interactive mode
    while true; do
        show_menu
        handle_input
        echo ""
        printf "Nhấn Enter để tiếp tục..."
        if ! read -r _; then
            echo ""
            echo "👋 Tạm biệt!"
            exit 0
        fi
    done
fi
