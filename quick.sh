#!/usr/bin/env zsh

# Quick Go Tutorial Commands
cd /home/mvt/Repositories/Go/go-tutorial

case $1 in
    "run")
        echo "🏃 Chạy project..."
        go run main.go
        ;;
    "watch")
        echo "👀 Chạy watch mode với Air..."
        air
        ;;
    "build")
        echo "🔨 Building project..."
        mkdir -p bin
        go build -o bin/main main.go
        echo "✅ Build thành công! File: bin/main"
        ;;
    "test")
        echo "🧪 Testing project..."
        go test -v ./...
        ;;
    "fmt")
        echo "🎨 Formatting code..."
        go fmt ./...
        echo "✅ Code đã được format!"
        ;;
    "clean")
        echo "🧹 Cleaning build files..."
        rm -rf bin/ tmp/
        go clean
        echo "✅ Cleaned!"
        ;;
    *)
        echo "🚀 Go Tutorial Project - Quick Commands"
        echo "======================================"
        echo "Usage: $0 [run|watch|build|test|fmt|clean]"
        echo ""
        echo "Commands:"
        echo "  run    - Chạy project"
        echo "  watch  - Chạy với Air (auto-reload)"
        echo "  build  - Build project"
        echo "  test   - Chạy tests"
        echo "  fmt    - Format code"
        echo "  clean  - Clean build files"
        echo ""
        echo "Examples:"
        echo "  $0 run"
        echo "  $0 watch"
        echo "  $0 build"
        ;;
esac

