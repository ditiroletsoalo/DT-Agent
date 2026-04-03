#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  AI Assistant — macOS setup script (venv version)
#  Run once:  bash setup.sh
#  Then run:  bash run.sh
# ─────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║        AI Assistant — Setup              ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── 1. Check Python ──────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo "❌  Python 3 not found."
    echo "    Install via Homebrew:  brew install python"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
echo "✅  Python $PYTHON_VERSION found"

# ── 2. Create virtual environment ────────────────────────────
echo ""
echo "🐍  Creating virtual environment..."
python3 -m venv .venv
echo "✅  Virtual environment created (.venv/)"

# ── 3. Install packages inside venv ──────────────────────────
echo ""
echo "📦  Installing packages into venv..."
.venv/bin/pip install --upgrade pip --quiet
.venv/bin/pip install -r requirements.txt --quiet
echo "✅  Packages installed"

# ── 4. API Key ───────────────────────────────────────────────
echo ""
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "🔑  ANTHROPIC_API_KEY is not set."
    echo ""
    echo "    Get your key at: https://console.anthropic.com/settings/keys"
    echo ""
    read -rp "    Paste your API key here (sk-ant-...): " KEY
    echo ""

    if [ -z "$KEY" ]; then
        echo "⚠️   No key entered. You can set it later:"
        echo "    export ANTHROPIC_API_KEY='sk-ant-...'"
    else
        PROFILE="$HOME/.zshrc"
        [ -f "$HOME/.bash_profile" ] && PROFILE="$HOME/.bash_profile"
        echo "export ANTHROPIC_API_KEY='$KEY'" >> "$PROFILE"
        export ANTHROPIC_API_KEY="$KEY"
        echo "✅  Key saved to $PROFILE"
    fi
else
    echo "✅  ANTHROPIC_API_KEY already set"
fi

# ── 5. macOS permissions reminder ────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ⚠️   macOS Permissions Required (one-time setup)"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  1. Accessibility    → System Settings > Privacy & Security"
echo "                        > Accessibility > add Terminal"
echo ""
echo "  2. Screen Recording → System Settings > Privacy & Security"
echo "                        > Screen Recording > add Terminal"
echo ""
echo "═══════════════════════════════════════════════════════"

# ── 6. Create run.sh ─────────────────────────────────────────
cat > run.sh << 'EOF'
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
EOF
 
chmod +x run.sh

echo ""
echo "✅  Setup complete!"
echo ""
echo "   Start the assistant with:"
echo "   bash /Users/ditiroletsoalo/Documents/DT_Agent/files/run.sh"
echo ""