#!/usr/bin/env bash
# ============================================================================
# post-security-scan.sh
# Hook Type: PostToolUse (matcher: "Edit|Write")
# Purpose: Scan cho secrets, hardcoded credentials, và security issues
# Exit: 0 = clean, 1 = SECURITY ISSUE FOUND (blocking)
# ============================================================================

set -euo pipefail

HOOK_NAME="[PostHook:SecurityScan]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

FILE_PATH="${TOOL_OUTPUT_PATH:-${1:-}}"

if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Only check code files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx|json|env|yml|yaml)$ ]]; then
    exit 0
fi

# Skip test files, node_modules
if [[ "$FILE_PATH" == *".spec."* ]] || \
   [[ "$FILE_PATH" == *".test."* ]] || \
   [[ "$FILE_PATH" == *"__test__"* ]] || \
   [[ "$FILE_PATH" == *"node_modules"* ]]; then
    exit 0
fi

# --- Security Patterns to Detect ---------------------------------------------
ISSUES_FOUND=0

check_security() {
    local pattern="$1"
    local severity="$2"
    local description="$3"

    if grep -qnE "$pattern" "$FILE_PATH" 2>/dev/null; then
        if [[ $ISSUES_FOUND -eq 0 ]]; then
            echo ""
            echo "🔒 $HOOK_NAME SECURITY SCAN"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  File: $FILE_PATH"
            echo ""
        fi

        matching_lines=$(grep -nE "$pattern" "$FILE_PATH" | head -3)
        echo "  [$severity] $description"
        echo "$matching_lines" | sed 's/^/     /'
        echo ""
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
}

# --- CRITICAL: Hardcoded secrets ---------------------------------------------
check_security \
    "(api[_-]?key|apikey|secret[_-]?key|password|passwd|token|auth[_-]?token)\s*[:=]\s*['\"][^'\"]{8,}" \
    "CRITICAL" \
    "Possible hardcoded secret/API key"

check_security \
    "sk-[a-zA-Z0-9]{20,}" \
    "CRITICAL" \
    "OpenAI-style API key detected"

check_security \
    "ghp_[a-zA-Z0-9]{36}" \
    "CRITICAL" \
    "GitHub personal access token detected"

check_security \
    "eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}" \
    "CRITICAL" \
    "JWT token detected in source code"

check_security \
    "AKIA[0-9A-Z]{16}" \
    "CRITICAL" \
    "AWS Access Key ID detected"

# --- HIGH: Dangerous patterns -------------------------------------------------
check_security \
    "eval\s*\(" \
    "HIGH" \
    "eval() usage — potential code injection"

check_security \
    "innerHTML\s*=" \
    "HIGH" \
    "innerHTML assignment — potential XSS"

check_security \
    "dangerouslySetInnerHTML" \
    "HIGH" \
    "dangerouslySetInnerHTML — potential XSS"

check_security \
    "new Function\s*\(" \
    "HIGH" \
    "Dynamic function creation — potential code injection"

# --- MEDIUM: Suspicious patterns ----------------------------------------------
check_security \
    "process\.env\.\w+\s*\|\|\s*['\"][^'\"]{8,}" \
    "MEDIUM" \
    "Hardcoded fallback for env var (consider removing default)"

check_security \
    "disable.*csrf|csrf.*disable" \
    "MEDIUM" \
    "CSRF protection may be disabled"

check_security \
    "cors.*origin.*['\"]\\*['\"]" \
    "MEDIUM" \
    "CORS origin set to wildcard '*'"

if [[ $ISSUES_FOUND -gt 0 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  🔒 Total security issues: $ISSUES_FOUND"
    echo "  📖 Reference: .claude/skills/security-review/SKILL.md"
    echo "  💡 Fix CRITICAL issues before committing!"
    echo ""

    # Block on CRITICAL issues
    if grep -qE "(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16})" "$FILE_PATH" 2>/dev/null; then
        echo "  🚨 BLOCKING: Hardcoded credentials detected. Remove them immediately."
        exit 1
    fi
fi

exit 0
