#!/bin/sh
# ============================================
#   Hermes-Agent Installer for iSH (iOS)
#   Run: sh install-ish.sh
# ============================================

set -e

download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fSL -o "$1" "$2" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$1" "$2" 2>/dev/null
    else
        printf "  x Neither curl nor wget found\n"
        exit 1
    fi
}

header() {
    clear
    printf "\n"
    printf "  +---------------------------------------+\n"
    printf "  | _   _                                |\n"
    printf "  || | | | ___ _ __ _ __ ___   ___  ___  |\n"
    printf "  || |_| |/ _ \\ '__| '_ \` _ \\ / _ \\/ __| |\n"
    printf "  ||  _  |  __/ |  | | | | | |  __/\\__ \\ |\n"
    printf "  ||_| |_|\\___|_|  |_| |_| |_\\___||___/ |\n"
    printf "  |                                       |\n"
    printf "  |  Mobile Installer v0.16.0             |\n"
    printf "  |  by NousResearch                      |\n"
    printf "  |  wrote by @amirghm                    |\n"
    printf "  +---------------------------------------+\n"
    printf "\n"
}

step() {
    printf "\n"
    printf "  --- Step $1: $2 ---\n"
    printf "\n"
}

ok()   { printf "  [ok] $1\n"; }
warn() { printf "  [!] $1\n"; }
fail() { printf "  [x] $1\n"; exit 1; }
log()  { printf "  $1\n"; }

ask() {
    printf "  $1 "
    read -r "$2"
}

trim_spaces() {
    printf "%s" "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

install_apk_packages() {
    if ! command -v apk >/dev/null 2>&1; then
        fail "apk not found. This installer requires iSH/Alpine Linux."
    fi

    printf "  Updating apk package index...\n"
    apk update >/dev/null || fail "apk update failed"

    printf "  Installing: curl, wget, bash, ca-certificates\n"
    apk add --no-cache curl wget bash ca-certificates >/dev/null || fail "apk add failed"

    command -v curl >/dev/null 2>&1 || fail "curl was not installed"
    command -v wget >/dev/null 2>&1 || fail "wget was not installed"
    command -v bash >/dev/null 2>&1 || fail "bash was not installed"

    ok "curl installed"
    ok "wget installed"
    ok "bash installed"
    ok "ca-certificates installed"
}

create_launchers() {
    mkdir -p "$HOME/python311/bin"

    cat > "$HOME/python311/bin/hermes" << 'HERMES_LAUNCHER'
#!/bin/sh
HERMES_PY="$HOME/python311/bin/python3.11"
export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"
exec "$HERMES_PY" -m hermes_cli.main "$@"
HERMES_LAUNCHER
    chmod +x "$HOME/python311/bin/hermes"

    cat > "$HOME/python311/bin/hermes-agent" << 'HERMES_AGENT_LAUNCHER'
#!/bin/sh
exec "$HOME/python311/bin/hermes" "$@"
HERMES_AGENT_LAUNCHER
    chmod +x "$HOME/python311/bin/hermes-agent"
}

existing_hermes_value() {
    KEY="$1"
    ENV_FILE="$HOME/.hermes/.env"
    CONFIG_FILE="$HOME/.hermes/config.yaml"

    case "$KEY" in
        OPENROUTER_API_KEY|TELEGRAM_BOT_TOKEN)
            [ -f "$ENV_FILE" ] || return 0
            grep "^${KEY}=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2-
            ;;
        MODEL_NAME)
            [ -f "$CONFIG_FILE" ] || return 0
            sed -n "s/^[[:space:]]*default:[[:space:]]*//p" "$CONFIG_FILE" | tail -1
            ;;
    esac
}

choose_setup_mode() {
    SETUP_MODE="quick"

    clear
    printf "\n"
    printf "  +---------------------------------------+\n"
    printf "  |        Hermes Mobile Setup            |\n"
    printf "  +---------------------------------------+\n"
    printf "\n"
    printf "  1) Quick setup\n"
    printf "     OpenRouter + Telegram token\n"
    printf "     Best for matching the Android flow.\n"
    printf "\n"
    printf "  2) Normal setup\n"
    printf "     Official Hermes setup wizard\n"
    printf "     More providers and options.\n"
    printf "\n"
    printf "  Select setup [1]: "
    read -r SETUP_MODE_INPUT
    printf "\n"

    case "$SETUP_MODE_INPUT" in
        2|normal|Normal|NORMAL)
            SETUP_MODE="normal"
            ;;
        *)
            SETUP_MODE="quick"
            collect_quick_setup
            ;;
    esac
}

collect_quick_setup() {
    clear
    printf "\n"
    printf "  +---------------------------------------+\n"
    printf "  |            Quick Setup                |\n"
    printf "  +---------------------------------------+\n"
    printf "\n"
    printf "  Provider  OpenRouter\n"
    printf "  Gateway   Telegram token saved for Hermes\n"
    printf "  Default   xiaomi/mimo-v2.5\n"
    printf "\n"

    OPENROUTER_API_KEY="$(trim_spaces "$(existing_hermes_value OPENROUTER_API_KEY)")"
    TELEGRAM_BOT_TOKEN="$(trim_spaces "$(existing_hermes_value TELEGRAM_BOT_TOKEN)")"
    MODEL_NAME="$(trim_spaces "$(existing_hermes_value MODEL_NAME)")"
    [ -n "$MODEL_NAME" ] || MODEL_NAME="xiaomi/mimo-v2.5"

    if [ -n "$OPENROUTER_API_KEY" ]; then
        ok "Existing OpenRouter key found"
        ask "OpenRouter API key [Enter to keep]:" OPENROUTER_INPUT
        OPENROUTER_INPUT="$(trim_spaces "$OPENROUTER_INPUT")"
        [ -n "$OPENROUTER_INPUT" ] && OPENROUTER_API_KEY="$OPENROUTER_INPUT"
    fi

    while [ -z "$OPENROUTER_API_KEY" ]; do
        ask "OpenRouter API key:" OPENROUTER_API_KEY
        OPENROUTER_API_KEY="$(trim_spaces "$OPENROUTER_API_KEY")"
    done

    if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        ok "Existing Telegram token found"
        ask "Telegram bot token [Enter to keep]:" TELEGRAM_INPUT
        TELEGRAM_INPUT="$(trim_spaces "$TELEGRAM_INPUT")"
        [ -n "$TELEGRAM_INPUT" ] && TELEGRAM_BOT_TOKEN="$TELEGRAM_INPUT"
    else
        ask "Telegram bot token [optional on iSH]:" TELEGRAM_BOT_TOKEN
        TELEGRAM_BOT_TOKEN="$(trim_spaces "$TELEGRAM_BOT_TOKEN")"
    fi

    printf "\n"
    printf "  Choose an OpenRouter model.\n"
    printf "  Press Enter for: %s\n" "$MODEL_NAME"
    ask "Model:" MODEL_INPUT
    MODEL_INPUT="$(trim_spaces "$MODEL_INPUT")"
    [ -n "$MODEL_INPUT" ] && MODEL_NAME="$MODEL_INPUT"

    printf "\n"
    warn "iSH can run Hermes chat, but long-running gateway/background behavior may be limited by iOS/iSH."
    ok "Quick setup details saved"
}

apply_quick_setup() {
    log "Writing Hermes config..."
    mkdir -p "$HOME/.hermes/logs" "$HOME/.hermes/sessions" "$HOME/.hermes/cron" "$HOME/.hermes/memories" "$HOME/.hermes/skills"
    ENV_FILE="$HOME/.hermes/.env"
    CONFIG_FILE="$HOME/.hermes/config.yaml"
    touch "$ENV_FILE"
    chmod 600 "$ENV_FILE"

    TMP_ENV="$TMPDIR/hermes-env"
    grep -v -E "^(OPENROUTER_API_KEY|TELEGRAM_BOT_TOKEN)=" "$ENV_FILE" > "$TMP_ENV" 2>/dev/null || true
    {
        cat "$TMP_ENV"
        printf "%s=%s\n" "OPENROUTER_API_KEY" "$OPENROUTER_API_KEY"
        [ -n "$TELEGRAM_BOT_TOKEN" ] && printf "%s=%s\n" "TELEGRAM_BOT_TOKEN" "$TELEGRAM_BOT_TOKEN"
    } > "$ENV_FILE"
    rm -f "$TMP_ENV"
    chmod 600 "$ENV_FILE"

    cat > "$CONFIG_FILE" << CONFIG_EOF
model:
  default: ${MODEL_NAME}
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions
agent:
  max_turns: 10
CONFIG_EOF

    ok "Quick setup saved"
}

header

if grep -qi 'alpine' /etc/os-release 2>/dev/null; then
    ok "Running in iSH (Alpine Linux)"
else
    warn "Does not look like iSH. Might still work."
fi

# Step 1: Dependencies
step 1 "Installing dependencies"

install_apk_packages

# Step 2: Install Hermes
step 2 "Installing Hermes-Agent"

RELEASE="https://github.com/amirghm/hermes-agent-mobile/releases/download/v0.16.0"
TMPDIR="$HOME/tmp/hermes-install-$$"
mkdir -p "$TMPDIR"

if command -v python3.11 >/dev/null 2>&1; then
    ok "Python 3.11 already installed"
else
    printf "  Downloading Python 3.11 (100MB)...\n"
    printf "  This takes a minute on mobile data...\n"
    download "$TMPDIR/python311.tar.gz" "$RELEASE/python311-i686.tar.gz" || fail "Download failed"
    cd "$TMPDIR" && tar xzf python311.tar.gz
    [ -d "$TMPDIR/python311" ] || fail "Python archive did not contain python311"
    mkdir -p "$HOME/python311"
    cp -rf "$TMPDIR/python311/"* "$HOME/python311/"
    rm -rf "$TMPDIR/python311" "$TMPDIR/python311.tar.gz"
    ok "Python 3.11 installed"
fi

export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"

if python3.11 -c "import hermes_cli" 2>/dev/null; then
    ok "Hermes already installed"
else
    printf "  Downloading Hermes-Agent (22MB)...\n"
    download "$TMPDIR/hermes.tar.gz" "$RELEASE/hermes-ish-v6.tar.gz" || fail "Download failed"
    cd "$TMPDIR" && tar xzf hermes.tar.gz
    SITE=$(python3.11 -c "import site; print(site.getsitepackages()[0])")
    cp -rf "$TMPDIR/usr/"* "$SITE/" 2>/dev/null || true
    rm -f "$SITE/tools/memory_tool.py" 2>/dev/null || true
    rm -rf "$TMPDIR/hermes.tar.gz" "$TMPDIR/usr"
    ok "Hermes-Agent installed"
fi

if python3.11 -c "import jiter" 2>/dev/null; then
    ok "jiter already installed"
else
    printf "  Downloading jiter...\n"
    download "$TMPDIR/jiter.tar.gz" "$RELEASE/jiter-i686.tar.gz" || fail "Download failed"
    cd "$TMPDIR" && tar xzf jiter.tar.gz
    SITE=$(python3.11 -c "import site; print(site.getsitepackages()[0])")
    for f in "$TMPDIR"/jiter* "$TMPDIR"/_jiter*; do
        [ -e "$f" ] && cp -rf "$f" "$SITE/" 2>/dev/null
    done
    rm -rf "$TMPDIR"/jiter* "$TMPDIR"/_jiter*
    ok "jiter installed"
fi

create_launchers
ok "Hermes command installed"

# Step 3: PATH
step 3 "Setting up PATH"

if ! grep -q 'python311/bin' ~/.profile 2>/dev/null; then
    echo 'export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"' >> ~/.profile
    ok "PATH added to .profile"
else
    ok "PATH already configured"
fi

export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"

step 4 "Configuring Hermes"

choose_setup_mode

case "$SETUP_MODE" in
    normal)
        printf "  Starting official Hermes setup wizard...\n"
        printf "\n"
        hermes setup
        ;;
    *)
        apply_quick_setup
        ;;
esac

rm -rf "$TMPDIR"

# Done
header

printf "  Installation complete!\n"
printf "\n"
printf "  Try it now:\n"
printf "\n"
printf "    hermes --prompt Hello\n"
printf "\n"
printf "  Or start a chat:\n"
printf "\n"
printf "    hermes\n"
printf "\n"
printf "  Configure:\n"
printf "\n"
printf "    hermes setup\n"
printf "    nano ~/.hermes/.env\n"
printf "    nano ~/.hermes/config.yaml\n"
printf "\n"
printf "  Docs: https://hermes-agent.nousresearch.com\n"
printf "\n"

if [ "$SETUP_MODE" = "quick" ]; then
    printf "  Starting Hermes chat...\n"
    printf "\n"
    exec hermes
fi
