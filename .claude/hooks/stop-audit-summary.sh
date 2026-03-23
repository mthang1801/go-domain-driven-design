#!/usr/bin/env bash
# ============================================================================
# stop-audit-summary.sh
# Hook Type: Stop (matcher: "*")
# Purpose: Tổng hợp tất cả thay đổi trong session, generate audit summary
# Exit: 0 always (informational only)
# ============================================================================

set -euo pipefail

HOOK_NAME="[StopHook:AuditSummary]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 $HOOK_NAME — Session Audit ($TIMESTAMP)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# --- List modified files (git-based) ------------------------------------------
cd "$PROJECT_ROOT"

MODIFIED_FILES=$(git diff --name-only 2>/dev/null || echo "")
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null || echo "")

echo ""
echo "📂 Files Modified (unstaged):"
if [[ -n "$MODIFIED_FILES" ]]; then
    echo "$MODIFIED_FILES" | sed 's/^/   • /'
    MODIFIED_COUNT=$(echo "$MODIFIED_FILES" | wc -l)
    echo "   Total: $MODIFIED_COUNT file(s)"
else
    echo "   (none)"
fi

echo ""
echo "📂 Files Staged:"
if [[ -n "$STAGED_FILES" ]]; then
    echo "$STAGED_FILES" | sed 's/^/   • /'
else
    echo "   (none)"
fi

echo ""
echo "📂 New Files (untracked):"
if [[ -n "$UNTRACKED_FILES" ]]; then
    echo "$UNTRACKED_FILES" | head -20 | sed 's/^/   • /'
    UNTRACKED_COUNT=$(echo "$UNTRACKED_FILES" | wc -l)
    if [[ $UNTRACKED_COUNT -gt 20 ]]; then
        echo "   ... and $((UNTRACKED_COUNT - 20)) more"
    fi
else
    echo "   (none)"
fi

# --- Layer analysis ----------------------------------------------------------
echo ""
echo "🏗️  Layer Analysis:"

for layer in domain application infrastructure presentation; do
    LAYER_FILES=$(echo "$MODIFIED_FILES" | grep "src/$layer/" 2>/dev/null || true)
    if [[ -n "$LAYER_FILES" ]]; then
        LAYER_COUNT=$(echo "$LAYER_FILES" | wc -l)
        echo "   [$layer] $LAYER_COUNT file(s) modified"
    fi
done

FRONTEND_FILES=$(echo "$MODIFIED_FILES" | grep "frontend/" 2>/dev/null || true)
if [[ -n "$FRONTEND_FILES" ]]; then
    FRONTEND_COUNT=$(echo "$FRONTEND_FILES" | wc -l)
    echo "   [frontend] $FRONTEND_COUNT file(s) modified"
fi

LIBS_FILES=$(echo "$MODIFIED_FILES" | grep "libs/" 2>/dev/null || true)
if [[ -n "$LIBS_FILES" ]]; then
    LIBS_COUNT=$(echo "$LIBS_FILES" | wc -l)
    echo "   [libs] $LIBS_COUNT file(s) modified ⚠️  (shared library!)"
fi

# --- Reminders ---------------------------------------------------------------
echo ""
echo "📝 Reminders:"

# Check if CHANGELOG needs updating
if [[ -n "$MODIFIED_FILES" ]]; then
    HAS_CHANGELOG_UPDATE=$(echo "$MODIFIED_FILES" | grep -c "CHANGELOG" || echo "0")
    if [[ "$HAS_CHANGELOG_UPDATE" -eq 0 ]]; then
        echo "   ⚠️  CHANGELOG.md not updated — consider updating changelogs/CHANGELOG.md"
    fi
fi

# Check if tests exist for modified files
MODIFIED_SRC=$(echo "$MODIFIED_FILES" | grep "\.ts$" | grep -v "\.spec\." | grep -v "\.test\." | grep -v "\.d\.ts$" || true)
if [[ -n "$MODIFIED_SRC" ]]; then
    MISSING_TESTS=0
    while IFS= read -r src_file; do
        spec_file="${src_file%.ts}.spec.ts"
        if [[ ! -f "$PROJECT_ROOT/$spec_file" ]]; then
            MISSING_TESTS=$((MISSING_TESTS + 1))
        fi
    done <<< "$MODIFIED_SRC"

    if [[ $MISSING_TESTS -gt 0 ]]; then
        echo "   ⚠️  $MISSING_TESTS modified file(s) have no corresponding .spec.ts test"
    fi
fi

# Pre-commit checklist
echo ""
echo "✅ Before committing:"
echo "   1. pnpm format"
echo "   2. pnpm lint"
echo "   3. pnpm test"
echo "   4. Update changelogs/CHANGELOG.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

exit 0
