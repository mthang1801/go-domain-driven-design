#!/bin/bash

# format-code.sh - Script để format code Go theo chuẩn gofmt
# Sử dụng: ./format-code.sh [options]

set -e

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Biến cấu hình
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GO_FILES=$(find "$PROJECT_ROOT" -name "*.go" -not -path "*/vendor/*" -not -path "*/tmp/*" -not -path "*/bin/*")
BACKUP_DIR="$PROJECT_ROOT/tmp/backup-$(date +%Y%m%d-%H%M%S)"

# Hàm hiển thị help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Hiển thị help này"
    echo "  -c, --check         Chỉ kiểm tra format, không sửa"
    echo "  -f, --fix           Sửa format tự động (default)"
    echo "  -b, --backup        Tạo backup trước khi format"
    echo "  -v, --verbose       Hiển thị chi tiết"
    echo "  -d, --dry-run       Chạy thử không thay đổi file"
    echo ""
    echo "Examples:"
    echo "  $0                  # Format tất cả file Go"
    echo "  $0 --check          # Kiểm tra format"
    echo "  $0 --backup         # Format với backup"
    echo "  $0 --dry-run        # Xem những gì sẽ được thay đổi"
}

# Hàm log
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Hàm kiểm tra Go tools
check_go_tools() {
    log "Kiểm tra Go tools..."
    
    if ! command -v go &> /dev/null; then
        log_error "Go không được cài đặt hoặc không có trong PATH"
        exit 1
    fi
    
    if ! command -v gofmt &> /dev/null; then
        log_error "gofmt không được cài đặt"
        exit 1
    fi
    
    if ! command -v goimports &> /dev/null; then
        log_warning "goimports không được cài đặt, đang cài đặt..."
        go install golang.org/x/tools/cmd/goimports@latest
    fi
    
    if ! command -v golangci-lint &> /dev/null; then
        log_warning "golangci-lint không được cài đặt, đang cài đặt..."
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    fi
    
    log_success "Tất cả Go tools đã sẵn sàng"
}

# Hàm tạo backup
create_backup() {
    if [ "$BACKUP" = true ]; then
        log "Tạo backup tại $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        
        for file in $GO_FILES; do
            relative_path=$(realpath --relative-to="$PROJECT_ROOT" "$file")
            backup_file="$BACKUP_DIR/$relative_path"
            mkdir -p "$(dirname "$backup_file")"
            cp "$file" "$backup_file"
        done
        
        log_success "Backup đã được tạo tại $BACKUP_DIR"
    fi
}

# Hàm format code
format_code() {
    local files_to_format=()
    local needs_formatting=0
    
    log "Đang kiểm tra format cho $(echo $GO_FILES | wc -w) file Go..."
    
    for file in $GO_FILES; do
        if [ "$VERBOSE" = true ]; then
            log "Kiểm tra: $file"
        fi
        
        # Kiểm tra gofmt
        if ! gofmt -s -d "$file" | grep -q .; then
            if [ "$VERBOSE" = true ]; then
                log "✓ gofmt OK: $file"
            fi
        else
            if [ "$VERBOSE" = true ]; then
                log "✗ gofmt cần sửa: $file"
            fi
            files_to_format+=("$file")
            needs_formatting=1
        fi
        
        # Kiểm tra goimports
        if ! goimports -d "$file" | grep -q .; then
            if [ "$VERBOSE" = true ]; then
                log "✓ goimports OK: $file"
            fi
        else
            if [ "$VERBOSE" = true ]; then
                log "✗ goimports cần sửa: $file"
            fi
            files_to_format+=("$file")
            needs_formatting=1
        fi
    done
    
    if [ $needs_formatting -eq 0 ]; then
        log_success "Tất cả file đã được format đúng!"
        return 0
    fi
    
    if [ "$CHECK_ONLY" = true ]; then
        log_warning "Có $(echo "${files_to_format[@]}" | wc -w) file cần format:"
        for file in "${files_to_format[@]}"; do
            echo "  - $file"
        done
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        log "DRY RUN - Các file sẽ được format:"
        for file in "${files_to_format[@]}"; do
            echo "  - $file"
            if [ "$VERBOSE" = true ]; then
                echo "    gofmt diff:"
                gofmt -s -d "$file" | sed 's/^/      /'
                echo "    goimports diff:"
                goimports -d "$file" | sed 's/^/      /'
            fi
        done
        return 0
    fi
    
    # Thực hiện format
    log "Đang format $(echo "${files_to_format[@]}" | wc -w) file..."
    
    for file in "${files_to_format[@]}"; do
        log "Formatting: $file"
        
        # Format với gofmt
        gofmt -s -w "$file"
        
        # Format với goimports
        goimports -w "$file"
    done
    
    log_success "Đã format xong tất cả file!"
}

# Hàm chạy linter
run_linter() {
    if [ "$CHECK_ONLY" = false ] && [ "$DRY_RUN" = false ]; then
        log "Chạy golangci-lint..."
        if golangci-lint run; then
            log_success "Linter passed!"
        else
            log_warning "Linter tìm thấy một số vấn đề"
        fi
    fi
}

# Hàm cleanup
cleanup() {
    if [ "$BACKUP" = true ] && [ -d "$BACKUP_DIR" ]; then
        log "Backup được lưu tại: $BACKUP_DIR"
    fi
}

# Parse arguments
CHECK_ONLY=false
BACKUP=false
VERBOSE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -f|--fix)
            CHECK_ONLY=false
            shift
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log "Bắt đầu format code Go..."
    
    check_go_tools
    create_backup
    format_code
    run_linter
    cleanup
    
    log_success "Hoàn thành!"
}

# Trap để cleanup khi exit
trap cleanup EXIT

# Chạy main function
main
