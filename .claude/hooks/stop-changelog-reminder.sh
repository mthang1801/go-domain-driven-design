#!/usr/bin/env bash
# ============================================================================
# stop-changelog-reminder.sh
# Hook Type: Stop (matcher: "*")
# Purpose: Nhắc update CHANGELOG nếu có code changes chưa ghi chú
# Exit: 0 always (informational only)
# ============================================================================

set -euo pipefail

HOOK_NAME="[StopHook:ChangelogReminder]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

cd "$PROJECT_ROOT"

# Get all modified files
ALL_CHANGED=$(git diff --name-only 2>/dev/null || echo "")
ALL_STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
ALL_FILES=$(echo -e "$ALL_CHANGED\n$ALL_STAGED" | sort -u | grep -v '^$' || true)

if [[ -z "$ALL_FILES" ]]; then
    exit 0 # No changes, nothing to remind
fi

# Check if any source code was modified (not just docs/config)
CODE_CHANGES=$(echo "$ALL_FILES" | grep -E '\.(ts|tsx|js|jsx)$' | grep -v 'node_modules' || true)

if [[ -z "$CODE_CHANGES" ]]; then
    exit 0 # Only doc/config changes, no reminder needed
fi

# Check if changelog was updated
CHANGELOG_UPDATED=$(echo "$ALL_FILES" | grep -ci 'changelog\|changes/' || echo "0")

if [[ "$CHANGELOG_UPDATED" -eq 0 ]]; then
    CODE_COUNT=$(echo "$CODE_CHANGES" | wc -l)
    echo ""
    echo "📝 $HOOK_NAME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $CODE_COUNT code file(s) modified but CHANGELOG not updated."
    echo ""
    echo "  Modified code files:"
    echo "$CODE_CHANGES" | head -10 | sed 's/^/    • /'
    echo ""
    echo "  📖 Please update:"
    echo "    • changelogs/CHANGELOG.md"
    echo "    • changelogs/changes/<slug>/tasks.md"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

exit 0
