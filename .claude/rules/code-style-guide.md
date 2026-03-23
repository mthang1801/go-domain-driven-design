---
trigger: always_on
---

# NestJS/TypeScript Code Style Guide

Hướng dẫn code style chuẩn cho dự án NestJS + DDD (TypeScript).

## 🎯 Mục tiêu

Đảm bảo code TypeScript trong dự án tuân thủ:
- **Prettier**: Format code
- **ESLint**: Lint, quality, rules
- **TypeScript**: Type safety

## 📁 Cấu trúc file

```
domain-driven-design/
├── .editorconfig        # Cấu hình editor
├── .prettierrc          # Cấu hình Prettier
├── eslint.config.js     # ESLint rules
├── package.json         # Scripts (lint/format/test)
└── .git/hooks/pre-commit # Git hook kiểm tra trước commit
```

## 🚀 Cách sử dụng

### 1. Cài đặt tools cần thiết

```bash
npm install
```

### 2. Format code

```bash
# Format code
npm run format

# Kiểm tra format (không sửa)
npm run format:check
```

### 3. Chạy linter

```bash
npm run lint
```

### 4. Kiểm tra toàn bộ

```bash
# Format + Lint + Test
npm run format && npm run lint && npm test
```

## 🔧 Cấu hình

### .prettierrc
- Cấu hình format (indent, quotes, trailing commas)
- Độ dài dòng tối đa: 120 ký tự

### eslint.config.js
- Cấu hình rules cho TypeScript/NestJS
- Bật strict rules và exclude một số pattern

### .editorconfig
- Cấu hình editor để tự động format
- Thiết lập indentation cho các loại file khác nhau
- Đảm bảo consistency giữa các editor

## 🎨 Code Style Rules

### 1. Formatting
- Indent 4 spaces (theo project)
- Max line length 120
- Format bằng Prettier, không format tay

### 2. Imports
- Nhóm imports: Node.js, third-party, local
- Sắp xếp alphabetically trong mỗi nhóm
- Không để unused imports

### 3. Naming
- camelCase: variables/functions
- PascalCase: class/interface/type
- Tên ngắn gọn, có nghĩa

### 4. Comments
- Comment ngắn, tập trung vào "why"
- Tránh comment hiển nhiên

### 5. Error Handling
- Không throw raw `Error` trong application/domain
- Dùng exception chuẩn trong `libs/src/common/exceptions`
- Log lỗi tập trung tại interceptor

## 🔄 Git Hooks

### Pre-commit Hook
Tự động chạy khi commit:
1. Format (Prettier)
2. Lint (ESLint)
3. Tests (optional)
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

### Pre-commit hook không hoạt động
```bash
# Kiểm tra quyền thực thi
ls -la .git/hooks/pre-commit

# Cài đặt lại quyền
chmod +x .git/hooks/pre-commit
```

## 📚 Tài liệu tham khảo

- [NestJS Docs](https://docs.nestjs.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [ESLint](https://eslint.org/)
- [Prettier](https://prettier.io/)

## 🤝 Đóng góp

Khi đóng góp code:
1. Đảm bảo tuân thủ code style guide này
2. Chạy `npm run format && npm run lint` trước khi commit
3. Viết tests cho code mới
4. Cập nhật documentation nếu cần

---

**Lưu ý**: Hệ thống này được thiết kế để đảm bảo code quality và consistency. Hãy sử dụng thường xuyên để duy trì chuẩn code trong dự án.