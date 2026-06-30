#!/bin/bash
# ============================================
#   Hermes-Agent Full Installer for Termux
#   Sets up Debian + Firefox + Hermes
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
    printf "  ${C}|${W}%s${C}|${D}\n" '  _   _                                '
    printf "  ${C}|${W}%s${C}|${D}\n" ' | | | | ___ _ __ _ __ ___   ___  ___  '
    printf "  ${C}|${W}%s${C}|${D}\n" ' | |_| |/ _ '"'"' '"'"'__| '"'"'_ ` _ \ / _ \/ __| '
    printf "  ${C}|${W}%s${C}|${D}\n" ' |  _  |  __/ |  | | | | | |  __/\__ \ '
    printf "  ${C}|${W}%s${C}|${D}\n" ' |_| |_|\___|_|  |_| |_| |_|\___||___/ '
    printf "  ${C}|${W}%s${C}|${D}\n" '                                       '
    printf "  ${C}|${W}  📱 Full Installer v2.0               ${C}|${D}\n"
    printf "  ${C}|${W}  🤖 Debian + Firefox + Hermes         ${C}|${D}\n"
    printf "  ${C}|${W}  ✍️ wrote by @amirghm                  ${C}|${D}\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "\n"
}

step() {
    printf "\n"
    printf "  ${B}=== Step $1: $2 ===${D}\n"
    printf "\n"
}

ok()   { printf "  ${G}v${D} $1\n"; }
skip() { printf "  ${Y}~${D} $1 (already installed)\n"; }
warn() { printf "  ${Y}!${D} $1\n"; }
fail() { printf "  ${R}x${D} $1\n"; exit 1; }
log()  { printf "  $1\n"; }

run_with_spinner() {
    MESSAGE="$1"
    LOG_FILE="$2"
    shift 2

    printf "  ${W}%s${D}" "$MESSAGE"
    "$@" > "$LOG_FILE" 2>&1 &
    COMMAND_PID=$!
    SPINNER='|/-\'
    SPINNER_INDEX=0

    while kill -0 "$COMMAND_PID" 2>/dev/null; do
        SPINNER_INDEX=$(( (SPINNER_INDEX + 1) % 4 ))
        printf "\r  ${W}%s${D} ${C}%s${D}" "$MESSAGE" "$(printf '%s' "$SPINNER" | cut -c $((SPINNER_INDEX + 1)))"
        sleep 1
    done

    wait "$COMMAND_PID"
    RESULT=$?
    if [ "$RESULT" -eq 0 ]; then
        printf "\r  ${G}v${D} %s\n" "$MESSAGE"
    else
        printf "\r  ${R}x${D} %s\n" "$MESSAGE"
        tail -20 "$LOG_FILE" 2>/dev/null || true
        return "$RESULT"
    fi
}

ask() {
    printf "  ${W}$1${D} "
    read -r "$2"
}

ask_secret() {
    printf "  ${W}$1${D} "
    read -r -s "$2"
    printf "\n"
}

choose_setup_mode() {
    SETUP_MODE="quick"
    QUICK_SETUP_REQUESTED=false

    printf "  ${W}Choose setup mode:${D}\n"
    printf "\n"
    printf "    ${C}1) Quick setup${D}  ${W}OpenRouter + Telegram, recommended for mobile${D}\n"
    printf "    ${C}2) Normal setup${D} ${W}Official Hermes setup wizard${D}\n"
    printf "\n"
    printf "  ${W}Select [1]:${D} "
    read -r SETUP_MODE_INPUT
    printf "\n"

    case "$SETUP_MODE_INPUT" in
        2|normal|Normal|NORMAL)
            SETUP_MODE="normal"
            ;;
        *)
            SETUP_MODE="quick"
            QUICK_SETUP_REQUESTED=true
            collect_quick_setup
            ;;
    esac
}

collect_quick_setup() {
    printf "\n"
    printf "  ${C}Quick Setup: OpenRouter + Telegram${D}\n"
    printf "\n"
    printf "  ${W}This will configure Hermes with:${D}\n"
    printf "    ${C}Provider:${D} OpenRouter\n"
    printf "    ${C}Model:${D}    xiaomi/mimo-v2.5\n"
    printf "    ${C}Gateway:${D}  Telegram\n"
    printf "\n"

    OPENROUTER_API_KEY=""
    TELEGRAM_BOT_TOKEN=""
    MODEL_NAME="xiaomi/mimo-v2.5"

    while [ -z "$OPENROUTER_API_KEY" ]; do
        ask_secret "OpenRouter API key:" OPENROUTER_API_KEY
    done

    while [ -z "$TELEGRAM_BOT_TOKEN" ]; do
        ask_secret "Telegram bot token:" TELEGRAM_BOT_TOKEN
    done

    ask "Model [xiaomi/mimo-v2.5]:" MODEL_INPUT
    if [ -n "$MODEL_INPUT" ]; then
        MODEL_NAME="$MODEL_INPUT"
    fi

    printf "\n"
    printf "  ${W}Open your Telegram bot and send:${D} ${C}/start${D}\n"
    printf "  ${W}When you are done, press Enter here. The installer will detect the chat and send a ready message at the end.${D}\n"
    printf "\n"
    printf "  ${W}Press Enter to continue:${D} "
    read -r _
    printf "\n"

    ok "Quick setup details saved"
}

telegram_chat_id() {
    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
        return 1
    fi

    curl -fsSL "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" 2>/dev/null \
        | sed -n 's/.*"chat":{"id":\(-\{0,1\}[0-9][0-9]*\).*/\1/p' \
        | tail -1
}

send_telegram_ready_message() {
    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
        return 0
    fi

    CHAT_ID="$(telegram_chat_id || true)"
    if [ -z "$CHAT_ID" ]; then
        warn "Could not detect Telegram chat. Send /start to your bot, then run: hermes gateway"
        return 0
    fi

    curl -fsSL \
        -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        --data-urlencode "text=Hermes Agent is installed and running on your phone. Your AI employee just clocked in." \
        >/dev/null 2>&1 || {
            warn "Could not send Telegram ready message"
            return 0
        }

    ok "Ready message sent to Telegram"
}

apply_quick_setup() {
    log "Writing Hermes config..."
    proot-distro login debian -- env \
        HERMES_QUICK_OPENROUTER_API_KEY="$OPENROUTER_API_KEY" \
        HERMES_QUICK_TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" \
        HERMES_QUICK_MODEL="$MODEL_NAME" \
        bash -c '
set -e
mkdir -p ~/.hermes/logs ~/.hermes/sessions ~/.hermes/cron ~/.hermes/memories ~/.hermes/skills
ENV_FILE="$HOME/.hermes/.env"
CONFIG_FILE="$HOME/.hermes/config.yaml"
touch "$ENV_FILE"
chmod 600 "$ENV_FILE"

TMP_ENV="$(mktemp)"
grep -v -E "^(OPENROUTER_API_KEY|TELEGRAM_BOT_TOKEN)=" "$ENV_FILE" > "$TMP_ENV" 2>/dev/null || true
{
  cat "$TMP_ENV"
  printf "%s=%s\n" "OPENROUTER_API_KEY" "$HERMES_QUICK_OPENROUTER_API_KEY"
  printf "%s=%s\n" "TELEGRAM_BOT_TOKEN" "$HERMES_QUICK_TELEGRAM_BOT_TOKEN"
} > "$ENV_FILE"
rm -f "$TMP_ENV"
chmod 600 "$ENV_FILE"

cat > "$CONFIG_FILE" <<CONFIG_EOF
model:
  default: ${HERMES_QUICK_MODEL}
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions
agent:
  max_turns: 10
CONFIG_EOF
'
    ok "Quick setup saved"

    log "Starting Telegram gateway in the background..."
    proot-distro login debian -- bash -c 'source ~/.bashrc 2>/dev/null; mkdir -p ~/.hermes/logs; nohup hermes gateway > ~/.hermes/logs/gateway.log 2>&1 &'
    ok "Gateway started"
}

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

choose_setup_mode

# Check what's already installed
DEBIAN_INSTALLED=false
HERMES_INSTALLED=false
QUICK_SETUP_RAN=false

if proot-distro login debian -- echo "ok" >/dev/null 2>&1; then
    DEBIAN_INSTALLED=true
fi

if proot-distro login debian -- bash -c "command -v hermes" >/dev/null 2>&1; then
    HERMES_INSTALLED=true
fi

# Show what will be installed
printf "\n"
printf "  ${W}Checking status:${D}\n"
printf "\n"
if [ "$DEBIAN_INSTALLED" = true ]; then
    skip "Debian"
else
    printf "    ${C}Debian${D} ${W}will be installed${D}\n"
fi

if [ "$HERMES_INSTALLED" = true ]; then
    skip "Hermes-Agent"
else
    printf "    ${C}Hermes-Agent${D} ${W}will be installed${D}\n"
fi
printf "\n"

# ============================================
#   STEP 1: Termux packages
# ============================================

step 1 "Setting up Termux"

log "Updating packages..."
pkg update -y 2>&1 | tail -3
pkg upgrade -y 2>&1 | tail -3

log "Installing proot-distro..."
pkg install -y proot-distro 2>&1 | tail -3

log "Installing remaining packages..."
pkg install -y git curl wget 2>&1 | tail -5

ok "Termux packages installed"

# ============================================
#   STEP 2: Install Debian
# ============================================

step 2 "Installing Debian"

if [ "$DEBIAN_INSTALLED" = true ]; then
    skip "Debian already installed"
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
#   STEP 4: Install Firefox + build tools
# ============================================

step 4 "Installing Firefox + build tools"

log "This is the slowest step. Firefox and build tools pull many Debian packages."
STEP4_LOG="${TMPDIR:-/tmp}/hermes-step4-install.log"
run_with_spinner "Installing Debian packages. This can take a few minutes..." "$STEP4_LOG" \
    proot-distro login debian -- bash -c "apt install -y firefox-esr python3 python3-pip python3-venv git curl build-essential libffi-dev libssl-dev pkg-config"

# ============================================
#   STEP 5: Install Hermes
# ============================================

step 5 "Installing Hermes-Agent"

if [ "$HERMES_INSTALLED" = true ]; then
    skip "Hermes already installed"
else
    log "Running official Hermes installer..."
    proot-distro login debian -- bash -c "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup" 2>&1 | tail -20
    ok "Hermes installed"
fi

# ============================================
#   STEP 6: Create launchers
# ============================================

step 6 "Creating launchers"

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

ok "Launchers created"

# ============================================
#   STEP 7: Configure Hermes (if not configured)
# ============================================

step 7 "Configuring Hermes"

# Check if already configured
HERMES_CONFIGURED=false
if proot-distro login debian -- bash -c "test -f ~/.hermes/.env" 2>/dev/null; then
    if proot-distro login debian -- bash -c "grep -q OPENROUTER_API_KEY ~/.hermes/.env" 2>/dev/null; then
        HERMES_CONFIGURED=true
    fi
fi

if [ "$HERMES_CONFIGURED" = true ]; then
    skip "Hermes already configured"
else
    case "$SETUP_MODE" in
        normal)
            printf "  ${W}Starting official Hermes setup wizard...${D}\n"
            printf "\n"
            proot-distro login debian -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes setup"
            ;;
        *)
            apply_quick_setup
            QUICK_SETUP_RAN=true
            send_telegram_ready_message
            ;;
    esac
fi

# ============================================
#   DONE
# ============================================

header

printf "  ${G}Everything installed!${D}\n"
printf "\n"
printf "  ${W}Commands:${D}\n"
printf "\n"
printf "    ${C}hermes${D}          ${W}Start Hermes chat${D}\n"
printf "    ${C}hermes setup${D}     ${W}Configure API key & model${D}\n"
printf "    ${C}hermes gateway${D}   ${W}Start Telegram/messaging gateway${D}\n"
printf "    ${C}debian${D}          ${W}Enter Debian shell${D}\n"
printf "\n"
printf "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}\n"
printf "\n"

if [ "$QUICK_SETUP_RAN" = true ]; then
    printf "  ${W}Starting Hermes chat...${D}\n"
    printf "\n"
    proot-distro login debian -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes"
fi
