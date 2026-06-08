#!/bin/bash
# ============================================
#   Hermes-Agent Full Installer for Termux
#   Sets up Debian + Fluxbox + Hermes
#   Usage: bash install-termux.sh
# ============================================

set -e

# ANSI colors using printf format
R='\e[1;31m'
G='\e[1;32m'
Y='\e[1;33m'
B='\e[1;34m'
C='\e[1;36m'
W='\e[1;37m'
D='\e[0m'

header() {
    clear
    printf "\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "  ${C}|${W} _   _                                ${C}|${D}\n"
    printf "  ${C}|${W}|| | | | ___ _  _  ___   ___  ___  ${C}|${D}\n"
    printf "  ${C}|${W}|| |_| |/ _ \\ | '_ \` _ \\ / _ \\/ | ${C}|${D}\n"
    printf "  ${C}|${W}||  _  |  / |  | | | | | |  /\\__ \\ ${C}|${D}\n"
    printf "  ${C}|${W}||_| |_|\\___|_|  |_| |_| |_|\\___||___/ ${C}|${D}\n"
    printf "  ${C}|${W}                                       ${C}|${D}\n"
    printf "  ${C}|${W}  📱 Full Installer v1.4               ${C}|${D}\n"
    printf "  ${C}|${W}  🤖 Debian + Fluxbox + Hermes          ${C}|${D}\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "\n"
}

step() {
    printf "\n"
    printf "  ${B}=== Step $1: $2 ===${D}\n"
    printf "\n"
}

ok()   { printf "  ${G}v${D} $1\n"; }
warn() { printf "  ${Y}!${D} $1\n"; }
fail() { printf "  ${R}x${D} $1\n"; exit 1; }
log()  { printf "  $1\n"; }

# ============================================
#   CHECK: must be run with bash, not sh
# ============================================

if [ -z "$BASH_VERSION" ]; then
    printf "\n"
    printf "  ${R}Error: This script must be run with bash, not sh.${D}\n"
    printf "\n"
    printf "  ${W}Use:${D}\n"
    printf "\n"
    printf "    bash <(curl -fsSL https://raw.githubusercontent.com/amirghm/hermes-agent-mobile/main/scripts/install-termux.sh)\n"
    printf "\n"
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

printf "\n"
printf "  ${W}Installing:${D}\n"
printf "\n"
printf "    1. Termux packages\n"
printf "    2. Debian (lightweight Linux)\n"
printf "    3. Fluxbox (lightweight window manager)\n"
printf "    4. Hermes-Agent\n"
printf "\n"
printf "  ${Y}This takes 5-10 minutes.${D}\n"
printf "\n"

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
#   STEP 4: Install Fluxbox (lightweight WM)
# ============================================

step 4 "Installing Fluxbox"

log "Installing Fluxbox + X11..."
proot-distro login debian -- bash -c "apt install -y fluxbox x11-xserver-utils xterm firefox-esr dbus-x11" 2>&1 | tail -5

ok "Fluxbox installed"

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

cat > "$PREFIX/bin/startflux" << 'FLUXBOX_LAUNCHER'
#!/bin/sh
printf "Starting Fluxbox Desktop...\n"
printf "Open Termux X11 app to see the desktop.\n"
termux-x11 :0 &
sleep 2
proot-distro login debian -- bash -c "export DISPLAY=:0; dbus-launch fluxbox"
FLUXBOX_LAUNCHER
chmod +x "$PREFIX/bin/startflux"

ok "Launchers created"

# ============================================
#   STEP 8: Run Hermes Setup
# ============================================

step 8 "Configuring Hermes"

printf "  ${W}Now let's configure Hermes (API key, model, etc.)${D}\n"
printf "\n"
proot-distro login debian -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes setup"

# ============================================
#   DONE
# ============================================

header

printf "  ${G}Everything installed and configured!${D}\n"
printf "\n"
printf "  ${W}Commands:${D}\n"
printf "\n"
printf "    ${C}hermes${D}          ${W}Start Hermes chat${D}\n"
printf "    ${C}debian${D}          ${W}Enter Debian shell${D}\n"
printf "    ${C}startflux${D}       ${W}Start Fluxbox desktop (GUI)${D}\n"
printf "\n"
printf "  ${W}Desktop (GUI):${D}\n"
printf "    1. Install ${C}Termux:X11${D} from ${C}F-Droid${D}\n"
printf "    2. Run ${C}startflux${D}\n"
printf "    3. Open Termux:X11 app\n"
printf "\n"
printf "  ${Y}⚠  Termux:X11 is REQUIRED for GUI desktop${D}\n"
printf "     Download: ${C}https://f-droid.org/packages/com.termux.x11/${D}\n"
printf "\n"
printf "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}\n"
printf "\n"
