#!/usr/bin/env bash
# ============================================================================
# pre-layer-boundary-check.sh
# Hook Type: PreToolUse (matcher: "Write|Edit")
# Purpose: Kiểm tra DDD layer boundary violations TRƯỚC khi viết code
#          Phát hiện import sai chiều (domain import infra, v.v.)
# Exit: 0 = ok, 1 = violation found
# ============================================================================

set -euo pipefail

HOOK_NAME="[Guard:LayerBoundary]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Input: file path + content (from $TOOL_INPUT or arguments)
FILE_PATH="${1:-}"
CONTENT="${2:-}"

if [[ -z "$FILE_PATH" ]] || [[ -z "$CONTENT" ]]; then
    exit 0 # Not enough info to check
fi

# Skip non-TS files
if [[ ! "$FILE_PATH" =~ \.ts$ ]]; then
    exit 0
fi

# --- Determine current layer -------------------------------------------------
CURRENT_LAYER=""
if [[ "$FILE_PATH" == *"/src/domain/"* ]]; then
    CURRENT_LAYER="domain"
elif [[ "$FILE_PATH" == *"/src/application/"* ]]; then
    CURRENT_LAYER="application"
elif [[ "$FILE_PATH" == *"/src/infrastructure/"* ]]; then
    CURRENT_LAYER="infrastructure"
elif [[ "$FILE_PATH" == *"/src/presentation/"* ]]; then
    CURRENT_LAYER="presentation"
fi

if [[ -z "$CURRENT_LAYER" ]]; then
    exit 0 # Not in a DDD layer
fi

# --- Define violation rules ---------------------------------------------------
# Layer Dependencies (One-way only):
#   Presentation → Application → Domain ← Infrastructure
#
# FORBIDDEN imports:
#   Domain: CANNOT import Application, Infrastructure, Presentation
#   Application: CANNOT import Presentation, ORM entities
#   Infrastructure: CANNOT import Application, Presentation
#   Presentation: CANNOT import Domain directly, ORM entities, Infrastructure

VIOLATIONS_FOUND=0

check_import() {
    local forbidden_pattern="$1"
    local violation_desc="$2"

    if echo "$CONTENT" | grep -qE "$forbidden_pattern"; then
        if [[ $VIOLATIONS_FOUND -eq 0 ]]; then
            echo ""
            echo "🚨 $HOOK_NAME VIOLATION DETECTED"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  File:  $FILE_PATH"
            echo "  Layer: $CURRENT_LAYER"
            echo ""
        fi
        echo "  ⛔ $violation_desc"
        echo "     Pattern: $forbidden_pattern"
        matching_lines=$(echo "$CONTENT" | grep -nE "$forbidden_pattern" | head -5)
        echo "     Lines:"
        echo "$matching_lines" | sed 's/^/       /'
        echo ""
        VIOLATIONS_FOUND=$((VIOLATIONS_FOUND + 1))
    fi
}

case "$CURRENT_LAYER" in
    domain)
        check_import "from.*['\"].*/(application|infrastructure|presentation)/" \
            "Domain MUST NOT import Application, Infrastructure, or Presentation"
        check_import "from.*['\"].*\.orm\.entity" \
            "Domain MUST NOT import ORM entities"
        check_import "from.*['\"]typeorm['\"]" \
            "Domain MUST NOT import TypeORM directly"
        ;;
    application)
        check_import "from.*['\"].*/(presentation)/" \
            "Application MUST NOT import Presentation layer"
        check_import "from.*['\"].*\.orm\.entity" \
            "Application MUST NOT import ORM entities"
        check_import "from.*['\"]typeorm['\"]" \
            "Application SHOULD NOT import TypeORM directly (use repository ports)"
        ;;
    infrastructure)
        check_import "from.*['\"].*/(application|presentation)/" \
            "Infrastructure MUST NOT import Application or Presentation"
        ;;
    presentation)
        check_import "from.*['\"].*\.orm\.entity" \
            "Presentation MUST NOT import ORM entities"
        check_import "from.*['\"].*/(infrastructure)/" \
            "Presentation MUST NOT import Infrastructure directly"
        ;;
esac

if [[ $VIOLATIONS_FOUND -gt 0 ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Total violations: $VIOLATIONS_FOUND"
    echo "  📖 Reference: .claude/agents/architecture.md"
    echo "  📖 Layer diagram: Presentation → Application → Domain ← Infrastructure"
    echo ""
    exit 1
fi

exit 0
