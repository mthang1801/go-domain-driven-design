# 🪝 Agent Hooks — Guardrail System

> **Platform**: Antigravity / Cursor / Claude Code / Any AI Agent
> **Mục đích**: Tự động kiểm tra trước/sau khi Agent xử lý và trả lời

## Overview

Hooks là các script tự động chạy ở các thời điểm khác nhau trong lifecycle của Agent:

```text
┌──────────────────────────────────────────────────────────────┐
│                    AGENT LIFECYCLE                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  User Request → [PreToolUse] → Tool Execution                │
│                                     ↓                        │
│                              [PostToolUse] → Response Build   │
│                                                    ↓          │
│                                              [Notification]   │
│                                                    ↓          │
│                                               [Stop]          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Hook Types

| Hook           | Timing                 | Purpose                                            |
| -------------- | ---------------------- | -------------------------------------------------- |
| `PreToolUse`   | Trước khi dùng tool    | Validate, block dangerous commands, inject context |
| `PostToolUse`  | Sau khi tool chạy xong | Auto-format, lint, type-check, security scan       |
| `Notification` | Khi cần thông báo      | Alert user về issues, warnings                     |
| `Stop`         | Khi session kết thúc   | Audit, extract patterns, summary                   |

## Hook Scripts

| Script                           | Hook Type   | Description                                  |
| -------------------------------- | ----------- | -------------------------------------------- |
| `pre-dangerous-command-guard.sh` | PreToolUse  | Block `rm -rf`, `git push --force`, etc.     |
| `pre-context-loader.sh`          | PreToolUse  | Nhắc đọc required context trước khi code     |
| `pre-layer-boundary-check.sh`    | PreToolUse  | Kiểm tra DDD layer violations trước khi viết |
| `post-prettier-format.sh`        | PostToolUse | Auto-format TS/JS files sau khi edit         |
| `post-eslint-check.sh`           | PostToolUse | Chạy ESLint trên file vừa sửa                |
| `post-typescript-check.sh`       | PostToolUse | Chạy tsc type check trên file vừa sửa        |
| `post-security-scan.sh`          | PostToolUse | Scan secrets, hardcoded keys                 |
| `post-console-log-warn.sh`       | PostToolUse | Cảnh báo `console.log` trong production code |
| `stop-audit-summary.sh`          | Stop        | Tổng hợp changes, generate audit log         |
| `stop-changelog-reminder.sh`     | Stop        | Nhắc update CHANGELOG nếu có code changes    |

## Configuration

### Claude Code (`settings.json`)

```json
{
  "hooks": {
    "PreToolUse": [...],
    "PostToolUse": [...],
    "Stop": [...]
  }
}
```

Xem `.claude/hooks/settings-hooks.json` để copy vào `~/.claude/settings.json`.

### Cursor / Antigravity

Hooks chạy thủ công hoặc tích hợp qua git hooks:

- `.git/hooks/pre-commit` → format + lint + security + mirror audit
- `.git/hooks/commit-msg` → validate commit message format

## Quick Start

```bash
# Cấp quyền thực thi cho tất cả hooks
chmod +x .claude/hooks/*.sh

# Test một hook cụ thể
.claude/hooks/post-prettier-format.sh src/app.module.ts

# Install git hooks
cp .claude/hooks/git-pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Nếu sửa các file liên quan mirror tree
pnpm run agents:claude:sync
pnpm run agents:claude:audit
```

## Exit Codes

| Code | Meaning                                                                    |
| ---- | -------------------------------------------------------------------------- |
| `0`  | Hook passed — tiếp tục bình thường                                         |
| `1`  | Hook failed — block action (cho PreToolUse) hoặc warning (cho PostToolUse) |
| `2`  | Hook skipped — không áp dụng cho file/command này                          |
