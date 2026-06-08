#!/bin/sh
# ============================================
#   Hermes-Agent Full Installer for Termux
#   Sets up Ubuntu + XFCE + Hermes
#   Usage: bash install-termux.sh <API_KEY> [MODEL_NUMBER]
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
    echo "  ${C}|${W}  📱 Full Installer v0.16.0             ${C}|${D}"
    echo "  ${C}|${W}  🤖 Ubuntu + XFCE + Hermes            ${C}|${D}"
    echo "  ${C}+---------------------------------------+${D}"
    echo ""
}

step() {
    echo ""
    echo "  ${B}=== Step $1: $2 ===${D}"
    echo ""
}

ok()   { echo "  ${G}v${D} $1"; }
warn() { echo "  ${Y}!${D} $1"; }
fail() { echo "  ${R}x${D} $1"; exit 1; }
log()  { echo "  $1"; }

# ============================================
#   CHECK: must be run with bash, not sh
# ============================================

if [ -z "$BASH_VERSION" ]; then
    echo ""
    echo "  ${R}Error: This script must be run with bash, not sh.${D}"
    echo ""
    echo "  ${W}Use:${D}"
    echo ""
    echo "    bash <(curl -fsSL https://raw.githubusercontent.com/amirghm/hermes-agent-mobile/main/scripts/install-termux.sh) YOUR_API_KEY"
    echo ""
    exit 1
fi

# ============================================
#   GET INPUT
# ============================================

API_KEY="$1"
MODEL_NUM="${2:-1}"

if [ -z "$API_KEY" ]; then
    header
    echo "  ${R}Usage:${D}"
    echo ""
    echo "    bash install-termux.sh YOUR_API_KEY [MODEL_NUMBER]"
    echo ""
    echo "  ${W}Examples:${D}"
    echo ""
    echo "    bash install-termux.sh ***"
    echo "    bash install-termux.sh *** 2"
    echo ""
    echo "  ${W}Models:${D}"
    echo "    1 = Mimo v2.5 (Free)"
    echo "    2 = Claude Sonnet 4 (approx 3 dollar/1M)"
    echo "    3 = GPT-4o-mini (approx 0.15 dollar/1M)"
    echo "    4 = Gemini Flash (Free tier)"
    echo ""
    echo "  ${W}Get API key:${D} https://openrouter.ai"
    echo ""
    exit 1
fi

case "$MODEL_NUM" in
    1) MODEL="xiaomi/mimo-v2.5" ;;
    2) MODEL="anthropic/claude-sonnet-4" ;;
    3) MODEL="openai/gpt-4o-mini" ;;
    4) MODEL="google/gemini-2.0-flash-001" ;;
    *) MODEL="xiaomi/mimo-v2.5" ;;
esac

# ============================================
#   START
# ============================================

header

if [ -d "/data/data/com.termux" ]; then
    ok "Running in Termux"
else
    warn "Does not look like Termux. Might still work."
fi

echo ""
echo "  ${W}Plan:${D}"
echo ""
echo "    API Key: ***..."
echo "    Model:   ${MODEL}"
echo ""
echo "  Installing:"
echo "    1. Termux packages"
echo "    2. Ubuntu 24.04"
echo "    3. XFCE4 Desktop"
echo "    4. Hermes-Agent"
echo ""
echo "  ${Y}This takes 10-15 minutes.${D}"

# ============================================
#   STEP 1: Termux packages
# ============================================

step 1 "Setting up Termux"

log "Updating packages..."
pkg update -y 2>&1 | tail -3
pkg upgrade -y 2>&1 | tail -3

log "Installing x11-repo first..."
pkg install -y x11-repo 2>&1 | tail -3

log "Installing proot-distro..."
pkg install -y proot-distro 2>&1 | tail -3

log "Installing remaining packages..."
pkg install -y git curl wget termux-x11-nightly pulseaudio 2>&1 | tail -5

ok "Termux packages installed"

# ============================================
#   STEP 2: Install Ubuntu
# ============================================

step 2 "Installing Ubuntu 24.04"

if proot-distro login ubuntu -- echo "ok" >/dev/null 2>&1; then
    ok "Ubuntu already installed"
else
    log "Downloading Ubuntu 24.04..."
    proot-distro install ubuntu 2>&1 | tail -10

    if proot-distro login ubuntu -- echo "ok" >/dev/null 2>&1; then
        ok "Ubuntu installed"
    else
        fail "Ubuntu installation failed"
    fi
fi

# ============================================
#   STEP 3: Setup Ubuntu
# ============================================

step 3 "Setting up Ubuntu"

log "Updating Ubuntu..."
proot-distro login ubuntu -- bash -c "apt update && apt upgrade -y" 2>&1 | tail -5

log "Installing base tools..."
proot-distro login ubuntu -- bash -c "apt install -y sudo nano adduser" 2>&1 | tail -3

if proot-distro login ubuntu -- id hermes >/dev/null 2>&1; then
    ok "User 'hermes' exists"
else
    log "Creating user 'hermes'..."
    proot-distro login ubuntu -- bash -c "adduser --disabled-password --gecos '' hermes" 2>&1 | tail -3
    proot-distro login ubuntu -- bash -c "usermod -aG sudo hermes" 2>&1 | tail -3
    proot-distro login ubuntu -- bash -c "echo 'hermes ALL=(ALL:ALL) ALL' >> /etc/sudoers" 2>&1 | tail -3
    ok "User 'hermes' created"
fi

# ============================================
#   STEP 4: Install XFCE4 Desktop
# ============================================

step 4 "Installing XFCE4 Desktop"

log "Installing XFCE4..."
proot-distro login ubuntu -- bash -c "apt install -y xfce4 xfce4-goodies dbus-x11" 2>&1 | tail -5

log "Cleaning up login managers..."
proot-distro login ubuntu -- bash -c 'for f in $(find /usr -type f -iname "*login1*"); do rm -rf $f; done' 2>&1 | tail -3

ok "XFCE4 installed"

# ============================================
#   STEP 5: Install build tools
# ============================================

step 5 "Installing build tools"

proot-distro login ubuntu -- bash -c "apt install -y python3 python3-pip python3-venv git curl build-essential libffi-dev libssl-dev pkg-config" 2>&1 | tail -5

ok "Build tools installed"

# ============================================
#   STEP 6: Install Hermes
# ============================================

step 6 "Installing Hermes-Agent"

log "Running official Hermes installer..."
proot-distro login ubuntu -- bash -c "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup" 2>&1 | tail -20

log "Configuring Hermes..."
proot-distro login ubuntu -- bash -c "mkdir -p ~/.hermes && echo 'OPENROUTER_API_KEY=*** > ~/.hermes/.env"
proot-distro login ubuntu -- bash -c "cat > ~/.hermes/config.yaml << CFGEOF
model:
  default: ${MODEL}
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions

agent:
  max_turns: 10
CFGEOF"

ok "Hermes-Agent installed and configured"

# ============================================
#   STEP 7: Create launchers
# ============================================

step 7 "Creating launchers"

mkdir -p "$PREFIX/bin"

cat > "$PREFIX/bin/hermes" << 'HERMES_LAUNCHER'
#!/bin/sh
proot-distro login ubuntu -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes $*"
HERMES_LAUNCHER
chmod +x "$PREFIX/bin/hermes"

cat > "$PREFIX/bin/ubuntu" << 'UBUNTU_LAUNCHER'
#!/bin/sh
proot-distro login ubuntu
UBUNTU_LAUNCHER
chmod +x "$PREFIX/bin/ubuntu"

cat > "$PREFIX/bin/startxfce" << 'XFCE_LAUNCHER'
#!/bin/sh
echo "Starting XFCE4 Desktop..."
echo "Open Termux X11 app to see the desktop."
termux-x11 :0 &
sleep 2
proot-distro login ubuntu -- bash -c "export DISPLAY=:0; dbus-launch startxfce4"
XFCE_LAUNCHER
chmod +x "$PREFIX/bin/startxfce"

ok "Launchers created"

# ============================================
#   DONE
# ============================================

header

echo "  ${G}Everything installed!${D}"
echo ""
echo "  ${W}Commands:${D}"
echo ""
echo "    ${C}hermes${D}          ${W}Start Hermes chat${D}"
echo "    ${C}ubuntu${D}          ${W}Enter Ubuntu shell${D}"
echo "    ${C}startxfce${D}       ${W}Start XFCE4 desktop${D}"
echo ""
echo "  ${W}Desktop:${D}"
echo "    1. Install Termux X11 from F-Droid"
echo "    2. Run ${C}startxfce${D}"
echo "    3. Open Termux X11 app"
echo ""
echo "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}"
echo ""
