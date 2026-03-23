#!/usr/bin/env bash
# ============================================================================
# git-pre-commit.sh
# Purpose: Git pre-commit hook for AI-assisted projects
#          Copy to .git/hooks/pre-commit
# Usage:   cp .claude/hooks/git-pre-commit.sh .git/hooks/pre-commit
#          chmod +x .git/hooks/pre-commit
# Exit: 0 = all checks passed, 1 = failed
# ============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo "🔒 Pre-commit guardrails running..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FAILED=0

# --- 1. Format check ----------------------------------------------------------
echo "  [1/5] Checking format..."
if ! pnpm format:check 2>/dev/null; then
    echo "  ❌ Format check failed. Run: pnpm format"
    FAILED=1
fi

# --- 2. Lint check -----------------------------------------------------------
echo "  [2/5] Running linter..."
if ! pnpm lint 2>/dev/null; then
    echo "  ❌ Lint check failed. Run: pnpm lint --fix"
    FAILED=1
fi

# --- 3. Security scan (staged files only) ------------------------------------
echo "  [3/5] Security scan..."
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ts|tsx|js|jsx)$' || true)

for file in $STAGED_FILES; do
    if [[ -f "$file" ]]; then
        # Check for hardcoded secrets
        if grep -qE "(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16})" "$file"; then
            echo "  ❌ SECURITY: Hardcoded credential found in $file"
            FAILED=1
        fi

        # Check for console.log in production code (warning only)
        if [[ ! "$file" == *".spec."* ]] && [[ ! "$file" == *".test."* ]]; then
            if grep -q 'console\.log' "$file"; then
                echo "  ⚠️  console.log found in $file (consider removing)"
            fi
        fi
    fi
done

# --- 4. TypeScript check -----------------------------------------------------
echo "  [4/5] TypeScript type check..."
if ! pnpm tsc:check 2>/dev/null; then
    echo "  ⚠️  TypeScript errors found (non-blocking for now)"
    # FAILED=1  # Uncomment to make blocking
fi

# --- 5. Mirror audit ---------------------------------------------------------
echo "  [5/5] Mirror audit..."
MIRROR_RELATED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '^(\.(agents|claude)/|tools/agents-claude-mirror|package\.json$)' || true)

if [[ -n "$MIRROR_RELATED_FILES" ]]; then
    if ! pnpm run agents:claude:audit >/dev/null 2>&1; then
        echo "  ❌ Mirror audit failed. Run: pnpm run agents:claude:sync"
        echo "     Re-run audit with: pnpm run agents:claude:audit"
        FAILED=1
    fi
else
    echo "  ⏭️  Mirror audit skipped (no staged mirror-related files)"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $FAILED -eq 1 ]]; then
    echo "❌ Pre-commit checks FAILED. Fix issues above before committing."
    echo "   tip: Use 'git commit --no-verify' to skip (USE WITH CAUTION)"
    exit 1
fi

echo "✅ All pre-commit checks passed!"
echo ""
exit 0
