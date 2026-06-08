#!/bin/sh
# ============================================
#   Hermes-Agent Installer for Termux
#   Uses the official Hermes installer
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

# ── Step 1: Update packages ────────────────────────
echo ""
echo "  ${B}--- Updating packages ---${D}"
echo ""

pkg update -y 2>&1 | tail -3
pkg upgrade -y 2>&1 | tail -3

ok "Packages updated"

# ── Step 2: Install Hermes ─────────────────────────
echo ""
echo "  ${B}--- Installing Hermes-Agent ---${D}"
echo ""
echo "  This uses the official Hermes installer."
echo "  It will:"
echo "    - Install system dependencies"
echo "    - Clone the repository"
echo "    - Set up Python environment"
echo "    - Install all packages"
echo "    - Run the setup wizard"
echo ""
echo "  Get your API key at: https://openrouter.ai"
echo ""

curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# ── Done ───────────────────────────────────────────
echo ""
echo "  ${G}Done!${D}"
echo ""
echo "  ${W}Try:${D} ${C}hermes${D}"
echo ""
