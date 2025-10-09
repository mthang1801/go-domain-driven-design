# 🐚 Hướng dẫn sử dụng Zsh với Go Tutorial Project

## 🚀 Cách sử dụng nhanh

### 1. Sử dụng script zsh (Khuyến nghị)

```bash
# Chạy project
./run.sh run

# Chạy watch mode với Air
./run.sh watch

# Build project
./run.sh build

# Test project
./run.sh test

# Format code
./run.sh fmt

# Clean build files
./run.sh clean
```

### 2. Sử dụng Makefile (nếu không có vấn đề với GVM)

```bash
make run
make watch
make build
make test
make fmt
make clean
```

### 3. Chạy trực tiếp với Go

```bash
# Chạy project
go run main.go

# Build project
go build -o bin/main main.go

# Chạy Air
air
```

## 🎯 Demo Watch Mode với Zsh

### Bước 1: Khởi động Watch Mode

```bash
cd /home/mvt/Repositories/Go/go-tutorial
./run.sh watch
```

### Bước 2: Test Auto-reload

1. Mở file `main.go` trong editor
2. Thay đổi dòng 11: `"🚀 Go Tutorial Project đang chạy!"` thành `"🔥 Hot Reload với Zsh!"`
3. Save file (Ctrl+S)
4. Xem Air tự động rebuild và restart!

### Bước 3: Test với utils package

1. Mở file `utils/helper.go`
2. Thay đổi function `GreetUser`:
   ```go
   func GreetUser(name string) string {
       return fmt.Sprintf("🎉 Chào mừng %s đến với Zsh + Go!", strings.Title(name))
   }
   ```
3. Save file và xem magic! ✨

## 🛠️ Troubleshooting Zsh

### Vấn đề với GVM

Nếu gặp lỗi `GVM_DEBUG: parameter not set`:

```bash
# Sử dụng script zsh thay vì Makefile
./run.sh run

# Hoặc unset GVM_DEBUG
unset GVM_DEBUG
```

### Air không hoạt động

```bash
# Kiểm tra Air
which air

# Cài đặt lại Air
go install github.com/air-verse/air@latest

# Test Air
./run.sh watch
```

### Go modules issues

```bash
# Clean và reinstall modules
go clean -modcache
go mod tidy
go mod download
```

## 🎨 Zsh Tips & Tricks

### 1. Aliases hữu ích

Thêm vào `~/.zshrc`:

```bash
# Go Tutorial aliases
alias gorun='cd /home/mvt/Repositories/Go/go-tutorial && ./run.sh run'
alias gowatch='cd /home/mvt/Repositories/Go/go-tutorial && ./run.sh watch'
alias gobuild='cd /home/mvt/Repositories/Go/go-tutorial && ./run.sh build'
```

### 2. Zsh functions

Thêm vào `~/.zshrc`:

```bash
# Go Tutorial function
gotutorial() {
    cd /home/mvt/Repositories/Go/go-tutorial
    case $1 in
        "run") ./run.sh run ;;
        "watch") ./run.sh watch ;;
        "build") ./run.sh build ;;
        "test") ./run.sh test ;;
        "fmt") ./run.sh fmt ;;
        "clean") ./run.sh clean ;;
        *) ./run.sh ;;
    esac
}
```

Sau đó sử dụng:

```bash
gotutorial run
gotutorial watch
gotutorial build
```

### 3. Zsh plugins (nếu sử dụng Oh My Zsh)

```bash
# Thêm vào ~/.zshrc
plugins=(git golang)
```

## 📁 Cấu trúc project với Zsh

```
go-tutorial/
├── main.go              # Entry point
├── utils/
│   └── helper.go        # Utility functions
├── .air.toml           # Air configuration
├── Makefile            # Make commands
├── run.sh              # Zsh runner script ⭐
├── go.mod              # Go modules
├── README.md           # Main documentation
├── WATCH_GUIDE.md      # Watch mode guide
├── ZSH_GUIDE.md        # Zsh guide (this file)
└── bin/                # Build output
    └── main            # Compiled binary
```

## 🎉 Quick Commands

```bash
# Quick start
./run.sh watch

# Quick run
./run.sh run

# Quick build
./run.sh build

# Interactive menu
./run.sh
```

## 🔧 Advanced Zsh Usage

### 1. Background processes

```bash
# Chạy Air trong background
./run.sh watch &

# Kill background Air
pkill air
```

### 2. Zsh completion

```bash
# Auto-complete cho run.sh
compdef '_values "commands" run watch build test fmt clean' ./run.sh
```

### 3. Zsh history

```bash
# Xem history của Go commands
history | grep go

# Xem history của run.sh
history | grep run.sh
```

Happy coding với Zsh! 🐚🚀
