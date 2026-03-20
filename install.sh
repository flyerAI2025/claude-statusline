#!/usr/bin/env bash
set -euo pipefail

DEST="$HOME/.claude/statusline-command.sh"
SETTINGS="$HOME/.claude/settings.json"
SL='{"statusLine":{"type":"command","command":"bash ~/.claude/statusline-command.sh"}}'

echo "Installing claude-statusline..."
command -v jq &>/dev/null || { echo "Error: jq required (brew install jq)"; exit 1; }

mkdir -p "$HOME/.claude"
cp "$(cd "$(dirname "$0")" && pwd)/claude-statusline.sh" "$DEST"
chmod +x "$DEST"

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak"
  tmp=$(mktemp)
  jq ". * $SL" "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
else
  echo "$SL" | jq . > "$SETTINGS"
fi

echo "Done! Restart Claude Code to activate."
echo "  Script: $DEST"
echo "  Config: $SETTINGS"
[ -f "$SETTINGS.bak" ] && echo "  Backup: $SETTINGS.bak"
