#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)/claude-statusline.sh"
DEST="$HOME/.claude/statusline-command.sh"
SETTINGS="$HOME/.claude/settings.json"
SL='{"statusLine":{"type":"command","command":"bash ~/.claude/statusline-command.sh"}}'

echo "Installing claude-statusline..."
command -v jq &>/dev/null || { echo "Error: jq required (brew install jq)"; exit 1; }
[ -f "$SRC" ] || { echo "Error: claude-statusline.sh not found"; exit 1; }

mkdir -p "$HOME/.claude"
cp "$SRC" "$DEST"
chmod +x "$DEST"

if [ -f "$SETTINGS" ]; then
  jq empty "$SETTINGS" 2>/dev/null || { echo "Error: $SETTINGS is not valid JSON"; exit 1; }
  cp "$SETTINGS" "$SETTINGS.bak"
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  jq --argjson sl "$SL" '. * $sl' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
else
  echo "$SL" | jq . > "$SETTINGS"
fi

echo "Done! Restart Claude Code to activate."
echo "  Script: $DEST"
echo "  Config: $SETTINGS"
[ -f "$SETTINGS.bak" ] && echo "  Backup: $SETTINGS.bak"
