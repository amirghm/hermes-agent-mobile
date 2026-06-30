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

    printf "  ${W}%s${D}\n" "$MESSAGE"
    "$@" > "$LOG_FILE" 2>&1 &
    COMMAND_PID=$!
    ELAPSED=0

    while kill -0 "$COMMAND_PID" 2>/dev/null; do
        sleep 10
        ELAPSED=$((ELAPSED + 10))
        if [ $((ELAPSED % 30)) -eq 0 ]; then
            printf "  ${C}Still installing... %ss${D}\n" "$ELAPSED"
        fi
    done

    wait "$COMMAND_PID"
    RESULT=$?
    if [ "$RESULT" -eq 0 ]; then
        printf "  ${G}v${D} %s\n" "$MESSAGE"
    else
        printf "  ${R}x${D} %s\n" "$MESSAGE"
        tail -20 "$LOG_FILE" 2>/dev/null || true
        return "$RESULT"
    fi
}

run_and_tail() {
    LOG_FILE="$1"
    TAIL_LINES="$2"
    shift 2

    "$@" > "$LOG_FILE" 2>&1
    RESULT=$?
    tail -n "$TAIL_LINES" "$LOG_FILE" 2>/dev/null || true
    return "$RESULT"
}

ensure_debian_bash() {
    if proot-distro login debian -- bash -c 'command -v bash >/dev/null 2>&1' >/dev/null 2>&1; then
        ok "Bash available"
        return 0
    fi

    log "Bash missing. Repairing Debian tools..."
    BASH_REPAIR_LOG="${TMPDIR:-/tmp}/hermes-bash-repair.log"
    run_and_tail "$BASH_REPAIR_LOG" 8 \
        proot-distro login debian -- bash -c "apt update && apt install -y bash"

    if proot-distro login debian -- bash -c 'command -v bash >/dev/null 2>&1' >/dev/null 2>&1; then
        ok "Bash repaired"
    else
        fail "Bash is still missing. See: $BASH_REPAIR_LOG"
    fi
}

create_launchers() {
    mkdir -p "$PREFIX/bin"

    cat > "$PREFIX/bin/hermes" << 'HERMES_LAUNCHER'
#!/bin/sh
proot-distro login debian -- bash -c 'source ~/.bashrc 2>/dev/null; cd ~; exec hermes "$@"' bash "$@"
HERMES_LAUNCHER
    chmod +x "$PREFIX/bin/hermes"

    cat > "$PREFIX/bin/debian" << 'DEBIAN_LAUNCHER'
#!/bin/sh
proot-distro login debian
DEBIAN_LAUNCHER
    chmod +x "$PREFIX/bin/debian"
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

trim_spaces() {
    printf "%s" "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

existing_hermes_value() {
    KEY="$1"

    if ! command -v proot-distro >/dev/null 2>&1; then
        return 0
    fi

    proot-distro login debian -- env HERMES_LOOKUP_KEY="$KEY" bash -c '
ENV_FILE="$HOME/.hermes/.env"
CONFIG_FILE="$HOME/.hermes/config.yaml"

case "$HERMES_LOOKUP_KEY" in
    OPENROUTER_API_KEY|TELEGRAM_BOT_TOKEN)
        [ -f "$ENV_FILE" ] || exit 0
        grep "^${HERMES_LOOKUP_KEY}=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2-
        ;;
    MODEL_NAME)
        [ -f "$CONFIG_FILE" ] || exit 0
        sed -n "s/^[[:space:]]*default:[[:space:]]*//p" "$CONFIG_FILE" | tail -1
        ;;
esac
' 2>/dev/null || true
}

choose_setup_mode() {
    SETUP_MODE="quick"
    QUICK_SETUP_REQUESTED=false

    clear
    printf "\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "  ${C}|${W}        Hermes Mobile Setup         ${C}|${D}\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "\n"
    printf "  ${C}1${D}) ${W}Quick setup${D}\n"
    printf "     ${Y}OpenRouter + Telegram${D}\n"
    printf "     ${W}Best for this tutorial.${D}\n"
    printf "\n"
    printf "  ${C}2${D}) ${W}Normal setup${D}\n"
    printf "     ${Y}Official Hermes wizard${D}\n"
    printf "     ${W}More providers and options.${D}\n"
    printf "\n"
    printf "  ${W}Select setup [1]:${D} "
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
    clear
    printf "\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "  ${C}|${W}            Quick Setup             ${C}|${D}\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "\n"
    printf "  ${C}Provider${D}  OpenRouter\n"
    printf "  ${C}Gateway${D}   Telegram\n"
    printf "  ${C}Default${D}   xiaomi/mimo-v2.5\n"
    printf "\n"
    printf "  ${Y}Your pasted keys will be visible.${D}\n"
    printf "\n"

    OPENROUTER_API_KEY=""
    TELEGRAM_BOT_TOKEN=""
    MODEL_NAME="xiaomi/mimo-v2.5"

    EXISTING_OPENROUTER_API_KEY="$(trim_spaces "$(existing_hermes_value OPENROUTER_API_KEY)")"
    EXISTING_TELEGRAM_BOT_TOKEN="$(trim_spaces "$(existing_hermes_value TELEGRAM_BOT_TOKEN)")"
    EXISTING_MODEL_NAME="$(trim_spaces "$(existing_hermes_value MODEL_NAME)")"

    if [ -n "$EXISTING_OPENROUTER_API_KEY" ]; then
        OPENROUTER_API_KEY="$EXISTING_OPENROUTER_API_KEY"
        printf "  ${G}v${D} Existing OpenRouter key found\n"
    fi

    if [ -n "$EXISTING_TELEGRAM_BOT_TOKEN" ]; then
        TELEGRAM_BOT_TOKEN="$EXISTING_TELEGRAM_BOT_TOKEN"
        printf "  ${G}v${D} Existing Telegram token found\n"
    fi

    if [ -n "$EXISTING_MODEL_NAME" ]; then
        MODEL_NAME="$EXISTING_MODEL_NAME"
        printf "  ${G}v${D} Existing model: ${C}%s${D}\n" "$MODEL_NAME"
    fi

    printf "\n"

    while [ -z "$OPENROUTER_API_KEY" ]; do
        ask "OpenRouter API key:" OPENROUTER_API_KEY
        OPENROUTER_API_KEY="$(trim_spaces "$OPENROUTER_API_KEY")"
    done

    if [ -n "$EXISTING_OPENROUTER_API_KEY" ]; then
        ask "OpenRouter API key [Enter to keep]:" OPENROUTER_INPUT
        OPENROUTER_INPUT="$(trim_spaces "$OPENROUTER_INPUT")"
        if [ -n "$OPENROUTER_INPUT" ]; then
            OPENROUTER_API_KEY="$OPENROUTER_INPUT"
        fi
    fi

    while [ -z "$TELEGRAM_BOT_TOKEN" ]; do
        ask "Telegram bot token:" TELEGRAM_BOT_TOKEN
        TELEGRAM_BOT_TOKEN="$(trim_spaces "$TELEGRAM_BOT_TOKEN")"
    done

    if [ -n "$EXISTING_TELEGRAM_BOT_TOKEN" ]; then
        ask "Telegram bot token [Enter to keep]:" TELEGRAM_INPUT
        TELEGRAM_INPUT="$(trim_spaces "$TELEGRAM_INPUT")"
        if [ -n "$TELEGRAM_INPUT" ]; then
            TELEGRAM_BOT_TOKEN="$TELEGRAM_INPUT"
        fi
    fi

    printf "\n"
    printf "  ${W}Choose an OpenRouter model.${D}\n"
    printf "  ${W}Press Enter for:${D} ${C}%s${D}\n" "$MODEL_NAME"
    ask "Model:" MODEL_INPUT
    MODEL_INPUT="$(trim_spaces "$MODEL_INPUT")"
    if [ -n "$MODEL_INPUT" ]; then
        MODEL_NAME="$MODEL_INPUT"
    fi

    printf "\n"
    printf "  ${W}Now open your Telegram bot.${D}\n"
    printf "  ${W}Send:${D} ${C}/start${D}\n"
    printf "  ${W}Then return here.${D}\n"
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

    curl --connect-timeout 8 --max-time 15 -fsSL "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates" 2>/dev/null \
        | sed -n 's/.*"chat":{"id":\(-\{0,1\}[0-9][0-9]*\).*/\1/p' \
        | tail -1
}

send_telegram_ready_message() {
    if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
        return 0
    fi

    log "Sending Telegram ready message..."
    CHAT_ID="$(telegram_chat_id || true)"
    if [ -z "$CHAT_ID" ]; then
        warn "Could not detect Telegram chat. Send /start to your bot, then run: hermes gateway"
        return 0
    fi

    curl --connect-timeout 8 --max-time 15 -fsSL \
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
    proot-distro login debian -- bash -c '
source ~/.bashrc 2>/dev/null
cd ~
mkdir -p ~/.hermes/logs
GATEWAY_LOG="$HOME/.hermes/logs/gateway.log"
GATEWAY_PID_FILE="$HOME/.hermes/gateway.pid"
: > "$GATEWAY_LOG"
nohup hermes gateway > "$GATEWAY_LOG" 2>&1 &
GATEWAY_PID=$!
echo "$GATEWAY_PID" > "$GATEWAY_PID_FILE"
sleep 3
if kill -0 "$GATEWAY_PID" 2>/dev/null; then
    printf "Gateway PID: %s\n" "$GATEWAY_PID"
    exit 0
fi
printf "Gateway exited during startup.\n"
printf "Last gateway log lines:\n"
tail -30 "$GATEWAY_LOG" 2>/dev/null || true
exit 1
'
    ok "Gateway started"
    log "Gateway log: ~/.hermes/logs/gateway.log"
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

create_launchers
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
STEP3_UPDATE_LOG="${TMPDIR:-/tmp}/hermes-step3-update.log"
run_and_tail "$STEP3_UPDATE_LOG" 5 \
    proot-distro login debian -- bash -c "apt update && apt upgrade -y"

log "Installing base tools..."
STEP3_TOOLS_LOG="${TMPDIR:-/tmp}/hermes-step3-tools.log"
run_and_tail "$STEP3_TOOLS_LOG" 5 \
    proot-distro login debian -- bash -c "apt install -y bash sudo nano adduser"

ensure_debian_bash

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

log "Slow step: installing Firefox and build tools."
STEP4_LOG="${TMPDIR:-/tmp}/hermes-step4-install.log"
run_with_spinner "Installing packages. Please wait..." "$STEP4_LOG" \
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

create_launchers
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

case "$SETUP_MODE" in
    normal)
        if [ "$HERMES_CONFIGURED" = true ]; then
            skip "Hermes already configured"
        else
            printf "  ${W}Starting official Hermes setup wizard...${D}\n"
            printf "\n"
            proot-distro login debian -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes setup"
        fi
        ;;
    *)
        if [ "$HERMES_CONFIGURED" = true ]; then
            log "Updating quick setup config..."
        fi
        apply_quick_setup
        QUICK_SETUP_RAN=true
        send_telegram_ready_message
        ;;
esac

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

if [ "$SETUP_MODE" = "quick" ]; then
    printf "  ${W}Starting Hermes chat...${D}\n"
    printf "\n"
    exec proot-distro login debian -- bash -c "source ~/.bashrc 2>/dev/null; cd ~; hermes"
fi
