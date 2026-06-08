#!/bin/sh
# ============================================
#   Hermes-Agent Installer for Termux
#   Installs Ubuntu via PRoot, then Hermes on it
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
step 1 "Installing Termux dependencies"

echo "  Updating packages..."
pkg update -y 2>&1 | tail -3
pkg upgrade -y 2>&1 | tail -3

echo ""
echo "  Installing proot-distro..."
pkg install -y proot-distro 2>&1 | tail -3

ok "proot-distro installed"

# ── Step 2: Install Ubuntu ─────────────────────────
step 2 "Installing Ubuntu 24.04"

DISTRO_PATH="$HOME/ubuntu"

if [ -d "$DISTRO_PATH" ]; then
    ok "Ubuntu already installed"
else
    echo "  Downloading Ubuntu 24.04 (Noble)..."
    echo "  This takes a few minutes..."
    echo ""

    proot-distro install ubuntu 2>&1 | tail -10

    ok "Ubuntu installed"
fi

# ── Step 3: Setup Ubuntu ───────────────────────────
step 3 "Setting up Ubuntu"

echo "  Updating Ubuntu..."
proot-distro login ubuntu -- bash -c "apt update && apt upgrade -y" 2>&1 | tail -5

echo ""
echo "  Installing dependencies in Ubuntu..."
proot-distro login ubuntu -- bash -c "apt install -y python3 python3-pip python3-venv git curl build-essential libffi-dev libssl-dev" 2>&1 | tail -5

ok "Ubuntu ready"

# ── Step 4: Install Hermes in Ubuntu ───────────────
step 4 "Installing Hermes-Agent in Ubuntu"

echo "  Running official Hermes installer inside Ubuntu..."
echo ""

proot-distro login ubuntu -- bash -c "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash" 2>&1 | tail -20

ok "Hermes-Agent installed"

# ── Step 5: Create launcher ────────────────────────
step 5 "Creating launcher"

cat > "$PREFIX/bin/hermes" << 'LAUNCHER'
#!/bin/sh
exec proot-distro login ubuntu -- bash -c "source ~/.bashrc && hermes $*"
LAUNCHER
chmod +x "$PREFIX/bin/hermes"

ok "Launcher created: 'hermes' command available"

# ── Done ───────────────────────────────────────────
header

echo "  ${G}Installation complete!${D}"
echo ""
echo "  ${W}Try it now:${D}"
echo ""
echo "    ${C}hermes${D}"
echo ""
echo "  ${W}Or enter Ubuntu directly:${D}"
echo ""
echo "    ${C}proot-distro login ubuntu${D}"
echo ""
echo "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}"
echo ""
