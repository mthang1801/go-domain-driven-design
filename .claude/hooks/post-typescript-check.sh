#!/usr/bin/env bash
# ============================================================================
# post-typescript-check.sh
# Hook Type: PostToolUse (matcher: "Edit|Write")
# Purpose: Chạy TypeScript type check trên file vừa sửa
# Exit: 0 = passed/warning, 2 = skipped
# ============================================================================

set -euo pipefail

HOOK_NAME="[PostHook:TypeScript]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE_PATH="${TOOL_OUTPUT_PATH:-${1:-}}"

if [[ -z "$FILE_PATH" ]]; then
    exit 2
fi

# Only check TS files
if [[ ! "$FILE_PATH" =~ \.tsx?$ ]]; then
    exit 2
fi

# Skip node_modules, dist
if [[ "$FILE_PATH" == *"node_modules"* ]] || [[ "$FILE_PATH" == *"/dist/"* ]]; then
    exit 2
fi

# Run tsc on the specific file (non-blocking)
# Use --noEmit to just type-check without producing output
TSC_OUTPUT=$(cd "$PROJECT_ROOT" && npx tsc --noEmit --pretty false 2>&1 | grep "$(basename "$FILE_PATH")" | head -10 || true)

if [[ -z "$TSC_OUTPUT" ]]; then
    echo "✅ $HOOK_NAME No type errors in: $(basename "$FILE_PATH")"
else
    TSC_ERROR_COUNT=$(echo "$TSC_OUTPUT" | wc -l)
    echo ""
    echo "⚠️  $HOOK_NAME Type errors found ($(basename "$FILE_PATH"))"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$TSC_OUTPUT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Total: $TSC_ERROR_COUNT type error(s)"
    echo "  💡 Run: pnpm tsc:check"
    echo ""
fi

exit 0
