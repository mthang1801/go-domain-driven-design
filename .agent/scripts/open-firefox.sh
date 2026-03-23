#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  Open a URL in Firefox (for browser testing / verification)
#
#  Usage:
#    ./open-firefox.sh <url>
#    ./open-firefox.sh http://localhost:6868
#    ./open-firefox.sh https://mvt-documents.vercel.app
# ────────────────────────────────────────────────────────────────

set -euo pipefail

URL="${1:-http://localhost:6868}"

# Detect Firefox binary
if command -v firefox &>/dev/null; then
    FIREFOX="firefox"
elif command -v firefox-esr &>/dev/null; then
    FIREFOX="firefox-esr"
elif [[ -x /usr/lib/firefox/firefox ]]; then
    FIREFOX="/usr/lib/firefox/firefox"
elif [[ -x /snap/bin/firefox ]]; then
    FIREFOX="/snap/bin/firefox"
else
    echo "❌ Firefox not found. Install with: sudo dnf install firefox"
    exit 1
fi

echo "🦊 Opening Firefox → $URL"

# Open in new tab if Firefox is already running, otherwise launch new instance
if pgrep -x firefox >/dev/null 2>&1; then
    "$FIREFOX" --new-tab "$URL" &
else
    "$FIREFOX" "$URL" &
fi

echo "✅ Firefox opened"
