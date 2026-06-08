#!/bin/sh
# ============================================
#   Hermes-Agent Installer for Termux
#   Run: sh install-termux.sh
# ============================================

set -e

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
D='\033[0m'

header() {
    clear
    echo ""
    echo "  ${C}+---------------------------------------+${D}"
    echo "  ${C}|${W}" ' _   _                                ' "${C}|${D}"
    echo "  ${C}|${W}" '| | | | ___ _  _  ___   ___  ___  ' "${C}|${D}"
    echo "  ${C}|${W}" '| |_| |/ _ \ '\''| '\''_ ` _ \ / _ \/ | ' "${C}|${D}"
    echo "  ${C}|${W}" '|  _  |  / |  | | | | | |  /\__ \ ' "${C}|${D}"
    echo "  ${C}|${W}" '|_| |_|\___|_|  |_| |_| |_|\___||___/ ' "${C}|${D}"
    echo "  ${C}|${W}" '                                       ' "${C}|${D}"
    echo "  ${C}|${W}  📱 Mobile Installer v0.16.0          ${C}|${D}"
    echo "  ${C}|${W}  🤖 by NousResearch                   ${C}|${D}"
    echo "  ${C}+---------------------------------------+${D}"
    echo ""
}

step() {
    echo ""
    echo "  ${B}--- Step $1: $2 ---${D}"
    echo ""
}

ok()   { echo "  ${G}v${D} $1"; }
warn() { echo "  ${Y}!${D} $1"; }
fail() { echo "  ${R}x${D} $1"; exit 1; }

header

# ── Check Termux ───────────────────────────────────
if [ -d "/data/data/com.termux" ]; then
    ok "Running in Termux"
else
    warn "Does not look like Termux. Might still work."
fi

# ── Step 1: System packages ────────────────────────
step 1 "Installing system packages"

echo "  Updating packages..."
echo ""

pkg update -y 2>&1 | tail -3
pkg upgrade -y 2>&1 | tail -3

echo ""
echo "  Installing build tools..."
echo ""

pkg install -y python git clang rust make pkg-config libffi openssl ca-certificates curl 2>&1 | tail -10

ok "Build tools installed"

# ── Step 2: Install Hermes ─────────────────────────
step 2 "Installing Hermes-Agent"

HERMES_HOME="$HOME/.hermes"
INSTALL_DIR="$HERMES_HOME/hermes-agent"

if [ -d "$INSTALL_DIR/.git" ]; then
    ok "Hermes repo already cloned"
    cd "$INSTALL_DIR"
    git pull 2>&1 | tail -3
else
    echo "  Cloning Hermes repository..."
    git clone --depth 1 https://github.com/NousResearch/hermes-agent.git "$INSTALL_DIR" 2>&1 | tail -3
    cd "$INSTALL_DIR"
    ok "Repository cloned"
fi

# ── Step 3: Create venv ────────────────────────────
step 3 "Setting up Python environment"

if [ -d "venv" ]; then
    ok "Virtual environment already exists"
else
    echo "  Creating virtual environment..."
    python -m venv venv
    ok "Virtual environment created"
fi

source venv/bin/activate

echo "  Upgrading pip..."
pip install --upgrade pip setuptools wheel >/dev/null 2>&1

ok "pip ready"

# ── Step 4: Install dependencies ───────────────────
step 4 "Installing dependencies"

# Prebuild psutil for Android
echo "  Checking Android compatibility..."
if python -c 'import sys; raise SystemExit(0 if sys.platform == "android" else 1)' 2>/dev/null; then
    echo "  Android detected: patching psutil..."
    if [ -f "scripts/install_psutil_android.py" ]; then
        python scripts/install_psutil_android.py --pip "pip" 2>&1 | tail -3
        ok "psutil patched"
    else
        warn "psutil patch script not found, trying anyway..."
    fi
fi

echo "  Installing hermes-agent..."
echo "  This takes a few minutes..."
echo ""

# Try termux-all first, then termux, then base
if pip install -e '.[termux-all]' -c constraints-termux.txt 2>&1 | tail -5; then
    ok "Hermes installed (full Termux profile)"
elif pip install -e '.[termux]' -c constraints-termux.txt 2>&1 | tail -5; then
    ok "Hermes installed (basic Termux profile)"
elif pip install -e '.' -c constraints-termux.txt 2>&1 | tail -5; then
    ok "Hermes installed (base profile)"
else
    fail "Installation failed. Try manually: cd $INSTALL_DIR && pip install -e '.[termux]' -c constraints-termux.txt"
fi

# ── Step 5: Setup ──────────────────────────────────
step 5 "Running Hermes setup"

echo "  This will ask you for:"
echo "    - API key (get one free at https://openrouter.ai)"
echo "    - Model preference"
echo "    - Other settings"
echo ""

hermes setup

# ── Done ───────────────────────────────────────────
header

echo "  ${G}Installation complete!${D}"
echo ""
echo "  ${W}Try it now:${D}"
echo ""
echo "    ${C}hermes${D}"
echo ""
echo "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}"
echo ""
