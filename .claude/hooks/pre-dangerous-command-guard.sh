#!/usr/bin/env bash
# ============================================================================
# pre-dangerous-command-guard.sh
# Hook Type: PreToolUse (matcher: "Bash")
# Purpose: Block dangerous commands that require explicit user confirmation
# Exit: 0 = safe, 1 = BLOCKED (dangerous command detected)
# ============================================================================

set -euo pipefail

# --- Configuration -----------------------------------------------------------
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK_NAME="[Guard:DangerousCommand]"

# Input: command string from $TOOL_INPUT or first argument
COMMAND_INPUT="${TOOL_INPUT:-${1:-}}"

if [[ -z "$COMMAND_INPUT" ]]; then
    exit 0 # Nothing to check
fi

# --- Dangerous Patterns (BLOCK immediately) ----------------------------------
EXTREMELY_DANGEROUS=(
    "rm -rf"
    "rm -r"
    "rm "
    "unlink"
    "shred"
    "wipe"
    "mkfs"
    "dd if="
    "> /dev/"
)

HIGH_DANGER=(
    "rmdir"
    "cp --remove-destination"
    "git push --force"
    "git push -f"
    "git reset --hard"
    "git clean -fd"
    "drop database"
    "drop table"
    "truncate table"
    "DELETE FROM"
)

INDIRECT_DANGER=(
    "npm publish"
    "npx publish"
    "pnpm publish"
    "yarn publish"
    "docker rmi"
    "docker system prune"
    "kubectl delete"
)

# --- Check Function ----------------------------------------------------------
check_patterns() {
    local level="$1"
    shift
    local patterns=("$@")
    
    for pattern in "${patterns[@]}"; do
        if echo "$COMMAND_INPUT" | grep -qi "$pattern"; then
            echo ""
            echo "🚨 $HOOK_NAME [$level] BLOCKED"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  Command: $COMMAND_INPUT"
            echo "  Pattern: $pattern"
            echo "  Level:   $level"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  ⛔ This command requires EXPLICIT user confirmation."
            echo "  💡 Ask the user before proceeding."
            echo ""
            return 1
        fi
    done
    return 0
}

# --- Execute Checks ----------------------------------------------------------
check_patterns "EXTREMELY_DANGEROUS" "${EXTREMELY_DANGEROUS[@]}" || exit 1
check_patterns "HIGH_DANGER" "${HIGH_DANGER[@]}" || exit 1
check_patterns "INDIRECT_DANGER" "${INDIRECT_DANGER[@]}" || exit 1

# --- Warning-only Patterns (don't block) -------------------------------------
WARNING_PATTERNS=(
    "mv "
    "install "
    "chmod "
    "chown "
)

for pattern in "${WARNING_PATTERNS[@]}"; do
    if echo "$COMMAND_INPUT" | grep -qi "$pattern"; then
        echo "⚠️  $HOOK_NAME [WARNING] Potentially risky: $pattern"
        echo "   Command: $COMMAND_INPUT"
    fi
done

# All checks passed
exit 0
