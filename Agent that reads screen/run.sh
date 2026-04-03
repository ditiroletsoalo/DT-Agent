#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

[ -f "$HOME/.zshrc" ]        && source "$HOME/.zshrc" 2>/dev/null
[ -f "$HOME/.bash_profile" ] && source "$HOME/.bash_profile" 2>/dev/null

echo ""
echo "🚀  Starting AI Assistant..."
echo "    Press ⌘ + Shift + Space anywhere to open."
echo "    Press Ctrl+C here to quit."
echo ""
.venv/bin/python assistant.py
