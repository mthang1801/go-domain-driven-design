#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  Verify documentation site in Firefox
#
#  Opens multiple pages sequentially for visual QA testing.
#  Useful for checking table layouts, icons, and rendering
#  differences between Firefox and Chromium.
#
#  Usage:
#    ./verify-firefox.sh                    # verify localhost:6868
#    ./verify-firefox.sh production         # verify Vercel deployment
# ────────────────────────────────────────────────────────────────

set -euo pipefail

MODE="${1:-local}"

if [[ "$MODE" == "production" || "$MODE" == "prod" ]]; then
    BASE_URL="https://mvt-documents.vercel.app"
else
    BASE_URL="http://localhost:6868"
fi

# Key pages to verify (covers tables, icons, mermaid, code blocks)
PAGES=(
    "#system-design%2FREADME.md"
    "#docker%2FREADME.md"
    "#k8s%2Ffundamental%2FREADME.md"
    "#linux-command%2FREADME.md"
    "#go%2FREADME.md"
    "#leet-codes%2FREADME.md"
    "#system-design%2F19-ddd-clean-architecture.md"
)

# Detect Firefox
if command -v firefox &>/dev/null; then
    FIREFOX="firefox"
elif command -v firefox-esr &>/dev/null; then
    FIREFOX="firefox-esr"
else
    echo "❌ Firefox not found."
    exit 1
fi

echo "🦊 Firefox QA Verification — $BASE_URL"
echo "════════════════════════════════════════"

for page in "${PAGES[@]}"; do
    URL="${BASE_URL}/${page}"
    echo "  📄 Opening: $URL"
    "$FIREFOX" --new-tab "$URL" 2>/dev/null &
    sleep 1
done

echo ""
echo "✅ Opened ${#PAGES[@]} pages. Check each tab for:"
echo "   • Table # column alignment (no number splitting)"
echo "   • Sidebar icons (Go, Drizzle, LeetCodes should show SVG icons)"
echo "   • Mermaid diagrams render as SVG charts"
echo "   • Code block syntax highlighting"
