#!/bin/bash
# ============================================
#   Hermes-Agent Full Installer for Termux
#   Sets up Debian + XFCE + Hermes
#   Usage: bash install-termux.sh
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
    echo -e "  ${C}+---------------------------------------+${D}"
    echo -e "  ${C}|${W}" ' _   _                                ' "${C}|${D}"
    echo -e "  ${C}|${W}" '| | | | ___ _  _  ___   ___  ___  ' "${C}|${D}"
    echo -e "  ${C}|${W}" '| |_| |/ _ \ '\''| '\''_ ` _ \ / _ \\/ | ' "${C}|${D}"
    echo -e "  ${C}|${W}" '|  _  |  / |  | | | | | |  /\__ \ ' "${C}|${D}"
    echo -e "  ${C}|${W}" '|_| |_|\___|_|  |_| |_| |_|\___||___/ ' "${C}|${D}"
    echo -e "  ${C}|${W}" '                                       ' "${C}|${D}"
    echo -e "  ${C}|${W}  📱 Full Installer v1.1               ${C}|${D}"
    echo -e "  ${C}|${W}  🤖 Debian + XFCE + Hermes            ${C}|${D}"
    echo -e "  ${C}+---------------------------------------+${D}"
    echo ""
}

step() {
    echo ""
    echo -e "  ${B}=== Step $1: $2 ===${D}"
    echo ""
}

ok()   { echo -e "  ${G}v${D} $1"; }
warn() { echo -e "  ${Y}!${D} $1"; }
fail() { echo -e "  ${R}x${D} $1"; exit 1; }
log()  { echo "  $1"; }

# ============================================
#   CHECK: must be run with bash, not sh
# ============================================

if [ -z "$BASH_VERSION" ]; then
    echo ""
    echo -e "  ${R}Error: This script must be run with bash, not sh.${D}"
    echo ""
    echo -e "  ${W}Use:${D}"
    echo ""
    echo "    bash <(curl -fsSL https://raw.githubusercontent.com/amirghm/hermes-agent-mobile/main/scripts/install-termux.sh)"
    echo ""
    exit 1
fi

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
echo -e "  ${W}Installing:${D}"
echo ""
echo "    1. Termux packages"
echo "    2. Debian (lightweight Linux)"
echo "    3. XFCE4 Desktop"
echo "    4. Hermes-Agent"
echo ""
echo -e "  ${Y}This takes 5-10 minutes.${D}"
echo ""
echo -e "  ${W}After install, run:${D}"
echo "    ${C}hermes${D}  to start Hermes"
echo "    ${C}hermes setup${D}  to configure API key & model"
echo ""

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
#   STEP 2: Install Debian
# ============================================

step 2 "Installing Debian"

if proot-distro login debian -- echo "ok" >/dev/null 2>&1; then
    ok "Debian already installed"
else
    log "Downloading Debian..."
    proot-distro install debian 2>&1 | tail -10

    if proot-distro login debian -- echo "ok" >/dev/null 2>&1; then
        ok "Debian installed"
    else
        fail "Debian installation failed"
    fi
fi

# ============================================
#   STEP 3: Setup Debian
# ============================================

step 3 "Setting up Debian"

log "Updating Debian..."
proot-distro login debian -- bash -c "apt update && apt upgrade -y" 2>&1 | tail -5

log "Installing base tools..."
proot-distro login debian -- bash -c "apt install -y sudo nano adduser" 2>&1 | tail -3

if proot-distro login debian -- id hermes >/dev/null 2>&1; then
    ok "User 'hermes' exists"
else
    log "Creating user 'hermes'..."
    proot-distro login debian -- bash -c "adduser --disabled-password --gecos '' hermes" 2>&1 | tail -3
    proot-distro login debian -- bash -c "usermod -aG sudo hermes" 2>&1 | tail -3
    proot-distro login debian -- bash -c "echo 'hermes ALL=(ALL:ALL) ALL' >> /etc/sudoers" 2>&1 | tail -3
    ok "User 'hermes' created"
fi

# ============================================
#   STEP 4: Install XFCE4 Desktop
# ============================================

step 4 "Installing XFCE4 Desktop"

log "Installing XFCE4..."
proot-distro login debian -- bash -c "apt install -y xfce4 xfce4-goodies dbus-x11" 2>&1 | tail -5

log "Cleaning up login managers..."
proot-distro login debian -- bash -c 'for f in $(find /usr -type f -iname "*login1*"); do rm -rf $f; done' 2>&1 | tail -3

ok "XFCE4 installed"

# ============================================
#   STEP 5: Install build tools
# ============================================

step 5 "Installing build tools"

proot-distro login debian -- bash -c "apt install -y python3 python3-pip python3-venv git curl build-essential libffi-dev libssl-dev pkg-config" 2>&1 | tail -5

ok "Build tools installed"

# ============================================
#   STEP 6: Install Hermes (skip setup)
# ============================================

step 6 "Installing Hermes-Agent"

log "Running official Hermes installer..."
proot-distro login debian -- bash -c "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup" 2>&1 | tail -20

ok "Hermes-Agent installed"

# ============================================
#   STEP 7: Create launchers
# ============================================

step 7 "Creating launchers"

mkdir -p "$PREFIX/bin"

cat > "$PREFIX/bin/hermes" << 'HERMES_LAUNCHER'
#!/bin/sh
proot-distro login debian -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes $*"
HERMES_LAUNCHER
chmod +x "$PREFIX/bin/hermes"

cat > "$PREFIX/bin/debian" << 'DEBIAN_LAUNCHER'
#!/bin/sh
proot-distro login debian
DEBIAN_LAUNCHER
chmod +x "$PREFIX/bin/debian"

cat > "$PREFIX/bin/startxfce" << 'XFCE_LAUNCHER'
#!/bin/sh
echo "Starting XFCE4 Desktop..."
echo "Open Termux X11 app to see the desktop."
termux-x11 :0 &
sleep 2
proot-distro login debian -- bash -c "export DISPLAY=:0; dbus-launch startxfce4"
XFCE_LAUNCHER
chmod +x "$PREFIX/bin/startxfce"

ok "Launchers created"

# ============================================
#   DONE
# ============================================

header

echo -e "  ${G}Everything installed!${D}"
echo ""
echo -e "  ${W}Commands:${D}"
echo ""
echo "    ${C}hermes${D}          ${W}Start Hermes chat${D}"
echo "    ${C}hermes setup${D}     ${W}Configure API key & model${D}"
echo "    ${C}debian${D}          ${W}Enter Debian shell${D}"
echo "    ${C}startxfce${D}       ${W}Start XFCE4 desktop${D}"
echo ""
echo -e "  ${W}Desktop:${D}"
echo "    1. Install Termux X11 from F-Droid"
echo "    2. Run ${C}startxfce${D}"
echo "    3. Open Termux X11 app"
echo ""
echo -e "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}"
echo ""
