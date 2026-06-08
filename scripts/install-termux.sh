#!/bin/sh
# ============================================
#   Hermes-Agent Full Installer for Termux
#   Sets up Ubuntu + XFCE + Hermes
#   User only inputs what's needed
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
#   START
# ============================================

header

if [ -d "/data/data/com.termux" ]; then
    ok "Running in Termux"
else
    warn "Does not look like Termux. Might still work."
fi

# ============================================
#   USER INPUT (only what's needed)
# ============================================

echo "  ${W}I need a few things from you:${D}"
echo ""
echo "  1. API Key for AI models"
echo "     Get one free at: https://openrouter.ai"
echo ""
printf "  API Key (starts with sk-or-...): "
read API_KEY

echo ""
echo "  2. Choose your AI model:"
echo ""
echo "     ${G}1)${D} Mimo v2.5      Free         Good for starters"
echo "     ${G}2)${D} Claude Sonnet4  ~\$3/1M      Best quality"
echo "     ${G}3)${D} GPT-4o-mini     ~\$0.15/1M   Fast and cheap"
echo "     ${G}4)${D} Gemini Flash    Free tier    Google models"
echo ""
printf "  Pick [1-4] (default: 1): "
read MODEL_CHOICE

case "${MODEL_CHOICE:-1}" in
    1) MODEL="xiaomi/mimo-v2.5" ;;
    2) MODEL="anthropic/claude-sonnet-4" ;;
    3) MODEL="openai/gpt-4o-mini" ;;
    4) MODEL="google/gemini-2.0-flash-001" ;;
    *) MODEL="xiaomi/mimo-v2.5" ;;
esac

echo ""
echo "  ${W}OK! Here's the plan:${D}"
echo ""
echo "    API Key: ${C}${API_KEY:0:10}...${D}"
echo "    Model:   ${C}$MODEL${D}"
echo ""
echo "  I will now install everything automatically:"
echo "    1. Termux packages"
echo "    2. Ubuntu 24.04 (via PRoot)"
echo "    3. XFCE4 Desktop"
echo "    4. Hermes-Agent"
echo ""
echo "  ${Y}This takes 10-15 minutes. Don't close the app.${D}"
echo ""
printf "  Press Enter to start..."
read _

# ============================================
#   STEP 1: Termux packages
# ============================================

step 1 "Setting up Termux"

log "Updating packages..."
pkg update -y 2>&1 | tail -3
pkg upgrade -y 2>&1 | tail -3

log "Installing required packages..."
pkg install -y proot-distro git curl wget x11-repo termux-x11-nightly pulseaudio 2>&1 | tail -5

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

# Create user
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

log "Installing XFCE4 and dependencies..."
proot-distro login ubuntu -- bash -c "apt install -y xfce4 xfce4-goodies dbus-x11" 2>&1 | tail -5

log "Cleaning up login managers..."
proot-distro login ubuntu -- bash -c "for f in \$(find /usr -type f -iname '*login1*'); do rm -rf \$f; done" 2>&1 | tail -3

ok "XFCE4 installed"

# ============================================
#   STEP 5: Install build tools
# ============================================

step 5 "Installing build tools"

log "Installing compilers and libraries..."
proot-distro login ubuntu -- bash -c "apt install -y python3 python3-pip python3-venv git curl build-essential libffi-dev libssl-dev pkg-config" 2>&1 | tail -5

ok "Build tools installed"

# ============================================
#   STEP 6: Install Hermes
# ============================================

step 6 "Installing Hermes-Agent"

log "Running official Hermes installer..."
proot-distro login ubuntu -- bash -c "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup" 2>&1 | tail -20

# Configure Hermes
log "Configuring Hermes..."
proot-distro login ubuntu -- bash -c "mkdir -p ~/.hermes && echo 'OPENROUTER_API_KEY=$API_KEY' > ~/.hermes/.env" 2>&1 | tail -3
proot-distro login ubuntu -- bash -c "cat > ~/.hermes/config.yaml << 'CFGEOF'
model:
  default: $MODEL
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions

agent:
  max_turns: 10
CFGEOF" 2>&1 | tail -3

ok "Hermes-Agent installed and configured"

# ============================================
#   STEP 7: Create launchers
# ============================================

step 7 "Creating launchers"

mkdir -p "$PREFIX/bin"

# Hermes launcher
cat > "$PREFIX/bin/hermes" << 'HERMES_LAUNCHER'
#!/bin/sh
proot-distro login ubuntu -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes $*"
HERMES_LAUNCHER
chmod +x "$PREFIX/bin/hermes"

# Ubuntu shell launcher
cat > "$PREFIX/bin/ubuntu" << 'UBUNTU_LAUNCHER'
#!/bin/sh
proot-distro login ubuntu
UBUNTU_LAUNCHER
chmod +x "$PREFIX/bin/ubuntu"

# XFCE launcher
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
