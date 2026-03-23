#!/usr/bin/env bash
# ============================================================================
# pre-context-loader.sh
# Hook Type: PreToolUse (matcher: "Write|Edit")
# Purpose: Nhắc Agent đọc required context trước khi viết code
# Exit: 0 = passed (hoặc warning message), 2 = skipped (non-code file)
# ============================================================================

set -euo pipefail

HOOK_NAME="[Guard:ContextLoader]"
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# Input: file path being written/edited
FILE_PATH="${TOOL_INPUT:-${1:-}}"

if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Skip non-code files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]]; then
    exit 2
fi

# --- Determine which layer is being modified ---------------------------------
LAYER=""
if [[ "$FILE_PATH" == *"/domain/"* ]]; then
    LAYER="domain"
elif [[ "$FILE_PATH" == *"/application/"* ]]; then
    LAYER="application"
elif [[ "$FILE_PATH" == *"/infrastructure/"* ]]; then
    LAYER="infrastructure"
elif [[ "$FILE_PATH" == *"/presentation/"* ]]; then
    LAYER="presentation"
elif [[ "$FILE_PATH" == *"/libs/"* ]]; then
    LAYER="libs"
elif [[ "$FILE_PATH" == *"/frontend/"* ]]; then
    LAYER="frontend"
fi

# --- Quick reminders based on layer ------------------------------------------
if [[ -n "$LAYER" ]]; then
    echo ""
    echo "📚 $HOOK_NAME — Editing $LAYER layer"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    case "$LAYER" in
        domain)
            echo "  📖 Required reading:"
            echo "     • libs/src/ddd/domain/ — Base classes (BaseEntity, BaseAggregateRoot)"
            echo "     • .claude/PATTERNS.md — Domain patterns"
            echo "  ⛔ Domain MUST NOT import any other layer"
            echo "  ✅ Pure domain logic only: Entities, VOs, Domain Events, Repository Ports"
            ;;
        application)
            echo "  📖 Required reading:"
            echo "     • libs/src/ddd/application/ — BaseCommand, BaseQuery"
            echo "     • .claude/skills/use-case-layer/SKILL.md"
            echo "  ⛔ Application MUST NOT import Presentation or ORM entities"
            echo "  ✅ Use-cases must extend BaseCommand (write) or BaseQuery (read)"
            ;;
        infrastructure)
            echo "  📖 Required reading:"
            echo "     • libs/src/ddd/infrastructure/ — BaseRepositoryTypeORM"
            echo "     • .claude/PATTERNS.md — Infrastructure patterns"
            echo "  ⛔ Infrastructure MUST NOT import Application or Presentation"
            echo "  ✅ Repository impl, ORM entities, HTTP clients, Messaging"
            ;;
        presentation)
            echo "  📖 Required reading:"
            echo "     • .claude/PATTERNS.md — Controller/DTO patterns"
            echo "  ⛔ Presentation MUST NOT import Domain directly or ORM entities"
            echo "  ✅ Controllers, DTOs, Guards, Pipes, Subscribers"
            ;;
        frontend)
            echo "  📖 Required reading:"
            echo "     • .claude/skills/vercel-react-best-practices/SKILL.md"
            echo "     • .claude/skills/ui-ux-pro-max/SKILL.md"
            echo "  ✅ React/Next.js following Vercel best practices"
            ;;
        libs)
            echo "  📖 Required reading:"
            echo "     • libs/src/ddd/ — DDD base classes"
            echo "  ⚠️  Changes to libs/ affect ALL modules. Be careful!"
            ;;
    esac

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

exit 0
