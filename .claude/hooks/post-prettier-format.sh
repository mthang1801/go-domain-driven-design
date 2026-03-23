#!/usr/bin/env bash
# ============================================================================
# post-prettier-format.sh
# Hook Type: PostToolUse (matcher: "Edit|Write")
# Purpose: Auto-format TS/JS/JSON files sau khi edit/write bằng Prettier
# Exit: 0 = formatted successfully, 2 = skipped (not applicable)
# ============================================================================

set -euo pipefail

HOOK_NAME="[PostHook:Prettier]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Input: file path from $TOOL_OUTPUT_PATH or first argument
FILE_PATH="${TOOL_OUTPUT_PATH:-${1:-}}"

if [[ -z "$FILE_PATH" ]]; then
    exit 2
fi

# Only format supported file types
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx|json|css|scss|html|md)$ ]]; then
    exit 2
fi

# Skip node_modules, dist, coverage
if [[ "$FILE_PATH" == *"node_modules"* ]] || \
   [[ "$FILE_PATH" == *"/dist/"* ]] || \
   [[ "$FILE_PATH" == *"/coverage/"* ]]; then
    exit 2
fi

# Check if prettier is available
if ! command -v npx &> /dev/null; then
    echo "⚠️  $HOOK_NAME npx not found, skipping format"
    exit 2
fi

# Run prettier
if npx prettier --write "$FILE_PATH" 2>/dev/null; then
    echo "✅ $HOOK_NAME Formatted: $(basename "$FILE_PATH")"
else
    echo "⚠️  $HOOK_NAME Format failed for: $(basename "$FILE_PATH") (non-blocking)"
fi

exit 0
