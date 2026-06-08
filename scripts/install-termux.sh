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

# ── Step 1: Dependencies ───────────────────────────
step 1 "Installing dependencies"

echo "  Updating packages..."
echo ""

pkg update -y 2>&1 | tail -3
pkg upgrade -y 2>&1 | tail -3

echo ""
echo "  Installing: python, git"
echo ""

pkg install -y python git 2>&1 | tail -5

ok "python installed"
ok "git installed"

# ── Step 2: Install Hermes (official method) ───────
step 2 "Installing Hermes-Agent"

echo "  Using official Hermes installer..."
echo "  This uses venv + pip (Termux compatible)..."
echo ""

curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup

ok "Hermes-Agent installed"

# ── Step 3: Setup ──────────────────────────────────
step 3 "Running Hermes setup"

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
