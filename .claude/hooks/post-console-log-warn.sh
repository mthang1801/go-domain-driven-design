#!/usr/bin/env bash
# ============================================================================
# post-console-log-warn.sh
# Hook Type: PostToolUse (matcher: "Edit|Write")
# Purpose: Cảnh báo console.log trong production code (non-blocking)
# Exit: 0 = clean/warning, 2 = skipped
# ============================================================================

set -euo pipefail

HOOK_NAME="[PostHook:ConsoleLog]"

FILE_PATH="${TOOL_OUTPUT_PATH:-${1:-}}"

if [[ -z "$FILE_PATH" ]]; then
    exit 2
fi

# Only check TS/JS
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]]; then
    exit 2
fi

# Skip test files, scripts, and config files
if [[ "$FILE_PATH" == *".spec."* ]] || \
   [[ "$FILE_PATH" == *".test."* ]] || \
   [[ "$FILE_PATH" == *"__test__"* ]] || \
   [[ "$FILE_PATH" == *"scripts/"* ]] || \
   [[ "$FILE_PATH" == *"node_modules"* ]] || \
   [[ "$FILE_PATH" == *"/dist/"* ]]; then
    exit 2
fi

# Check for console.log
CONSOLE_LINES=$(grep -n 'console\.log' "$FILE_PATH" 2>/dev/null || true)

if [[ -n "$CONSOLE_LINES" ]]; then
    CONSOLE_COUNT=$(echo "$CONSOLE_LINES" | wc -l)
    echo ""
    echo "⚠️  $HOOK_NAME Found $CONSOLE_COUNT console.log(s) in $(basename "$FILE_PATH")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$CONSOLE_LINES" | sed 's/^/  /'
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  💡 Use structured logging (Logger) instead of console.log"
    echo "  📖 Reference: .claude/rules/code-style-guide.md"
    echo ""
fi

# Also check for console.error, console.warn if not using NestJS Logger
CONSOLE_OTHERS=$(grep -n 'console\.\(error\|warn\|info\|debug\)' "$FILE_PATH" 2>/dev/null || true)

if [[ -n "$CONSOLE_OTHERS" ]]; then
    echo "  ℹ️  Also found console.error/warn/info/debug — consider using NestJS Logger"
fi

exit 0
