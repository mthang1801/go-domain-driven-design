#!/usr/bin/env bash
# ============================================================================
# post-eslint-check.sh
# Hook Type: PostToolUse (matcher: "Edit|Write")
# Purpose: Chạy ESLint check trên file vừa sửa (warning only, non-blocking)
# Exit: 0 = passed/warning, 2 = skipped
# ============================================================================

set -euo pipefail

HOOK_NAME="[PostHook:ESLint]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE_PATH="${TOOL_OUTPUT_PATH:-${1:-}}"

if [[ -z "$FILE_PATH" ]]; then
    exit 2
fi

# Only check TS/JS files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]]; then
    exit 2
fi

# Skip node_modules, dist
if [[ "$FILE_PATH" == *"node_modules"* ]] || [[ "$FILE_PATH" == *"/dist/"* ]]; then
    exit 2
fi

# Check if eslint is available
if ! command -v npx &> /dev/null; then
    exit 2
fi

# Run ESLint (non-blocking — report only)
LINT_OUTPUT=$(cd "$PROJECT_ROOT" && npx eslint "$FILE_PATH" --no-error-on-unmatched-pattern --format compact 2>/dev/null || true)

if [[ -z "$LINT_OUTPUT" ]] || [[ "$LINT_OUTPUT" == *"0 problems"* ]]; then
    echo "✅ $HOOK_NAME Clean: $(basename "$FILE_PATH")"
else
    ERROR_COUNT=$(echo "$LINT_OUTPUT" | grep -c "Error" || echo "0")
    WARN_COUNT=$(echo "$LINT_OUTPUT" | grep -c "Warning" || echo "0")

    echo ""
    echo "⚠️  $HOOK_NAME Issues found in $(basename "$FILE_PATH")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Errors:   $ERROR_COUNT"
    echo "  Warnings: $WARN_COUNT"
    echo ""
    # Show first 10 issues
    echo "$LINT_OUTPUT" | head -10
    echo ""
    echo "  💡 Run: pnpm lint --fix $(basename "$FILE_PATH")"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

exit 0
