#!/bin/sh
# ============================================
#   Hermes-Agent Installer for iSH (iOS)
#   Run: sh install-ish.sh
# ============================================

set -e

INSTALLER_VERSION="0.16.0"
PYTHON_DIR="$HOME/python311"
PYTHON_BIN="$PYTHON_DIR/bin/python3.11"
PYTHON_LIB_DIR="$PYTHON_DIR/lib"
RELEASE="https://github.com/amirghm/hermes-agent-mobile/releases/download/v$INSTALLER_VERSION"
LIBFFI7_RELEASE_URL="$RELEASE/libffi7-i686.tar.gz"
LIBFFI7_APK_URL="https://dl-cdn.alpinelinux.org/alpine/v3.14/main/x86/libffi-3.3-r2.apk"

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
    printf "  +-------------------------------------------+\n"
    printf "  |  %-39s  |\n" " _   _"
    printf "  |  %-39s  |\n" "| | | | ___ _ __ _ __ ___   ___  ___"
    printf "  |  %-39s  |\n" "| |_| |/ _ \\ '__| '_ \` _ \\ / _ \\/ __|"
    printf "  |  %-39s  |\n" "|  _  |  __/ |  | | | | | |  __/\\__ \\"
    printf "  |  %-39s  |\n" "|_| |_|\\___|_|  |_| |_| |_|\\___||___/"
    printf "  |  %-39s  |\n" ""
    printf "  |  %-39s  |\n" "Hermes Mobile Installer"
    printf "  |  v%-38s  |\n" "$INSTALLER_VERSION"
    printf "  |  %-39s  |\n" "by NousResearch / @amirghm"
    printf "  +-------------------------------------------+\n"
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

looks_like_telegram_token() {
    case "$1" in
        *:* )
            printf "%s" "$1" | grep -Eq '^[0-9]{6,}:[A-Za-z0-9_-]{20,}$'
            ;;
        *)
            return 1
            ;;
    esac
}

validate_telegram_token_or_warn() {
    VALUE="$1"
    [ -z "$VALUE" ] && return 0

    if looks_like_telegram_token "$VALUE"; then
        return 0
    fi

    warn "That does not look like a Telegram bot token."
    warn "Expected format: 123456789:AA..."
    return 1
}

install_apk_packages() {
    if ! command -v apk >/dev/null 2>&1; then
        fail "apk not found. This installer requires iSH/Alpine Linux."
    fi

    printf "  Updating apk package index...\n"
    apk update >/dev/null || fail "apk update failed"

    for pkg in curl wget bash ca-certificates libffi libgcc libstdc++ openssl sqlite-libs zlib; do
        if apk info -e "$pkg" >/dev/null 2>&1; then
            if apk version -q -l '<' "$pkg" 2>/dev/null | grep -q .; then
                printf "  Updating: %s\n" "$pkg"
                apk add --no-cache --upgrade "$pkg" >/dev/null || fail "apk update failed for $pkg"
            else
                ok "$pkg already installed"
            fi
        else
            printf "  Installing: %s\n" "$pkg"
            apk add --no-cache "$pkg" >/dev/null || fail "apk install failed for $pkg"
        fi
    done

    command -v curl >/dev/null 2>&1 || fail "curl was not installed"
    command -v wget >/dev/null 2>&1 || fail "wget was not installed"
    command -v bash >/dev/null 2>&1 || fail "bash was not installed"
}

ensure_libffi_compat() {
    mkdir -p "$PYTHON_LIB_DIR"

    if [ -e "$PYTHON_LIB_DIR/libffi.so.7" ]; then
        ok "bundled libffi.so.7 available"
        return 0
    fi

    if [ -e /usr/lib/libffi.so.7 ] || [ -e /lib/libffi.so.7 ]; then
        ok "libffi.so.7 available"
        return 0
    fi

    printf "  Downloading libffi.so.7 runtime...\n"
    LIBFFI_TMP="$TMPDIR/libffi7"
    rm -rf "$LIBFFI_TMP"
    mkdir -p "$LIBFFI_TMP"

    if download "$TMPDIR/libffi7.tar.gz" "$LIBFFI7_RELEASE_URL"; then
        tar xzf "$TMPDIR/libffi7.tar.gz" -C "$LIBFFI_TMP" || fail "libffi.so.7 release extract failed"
        LIBFFI_SOURCE_DIR="$LIBFFI_TMP"
        rm -f "$TMPDIR/libffi7.tar.gz"
    else
        download "$TMPDIR/libffi7.apk" "$LIBFFI7_APK_URL" || fail "libffi.so.7 download failed"
        tar xzf "$TMPDIR/libffi7.apk" -C "$LIBFFI_TMP" || fail "libffi.so.7 extract failed"
        LIBFFI_SOURCE_DIR="$LIBFFI_TMP/usr/lib"
        rm -f "$TMPDIR/libffi7.apk"
    fi

    [ -e "$LIBFFI_SOURCE_DIR/libffi.so.7" ] || fail "libffi.so.7 not found in package"
    cp -f "$LIBFFI_SOURCE_DIR/libffi.so.7"* "$PYTHON_LIB_DIR/" || fail "libffi.so.7 copy failed"
    rm -rf "$LIBFFI_TMP"

    [ -e "$PYTHON_LIB_DIR/libffi.so.7" ] || fail "Bundled libffi.so.7 install failed"
    ok "bundled libffi.so.7 installed"
}

verify_python_runtime() {
    LD_LIBRARY_PATH="$PYTHON_LIB_DIR:${LD_LIBRARY_PATH:-}" "$PYTHON_BIN" -c "import ctypes, ssl, sqlite3, zlib" 2>/dev/null || fail "Python runtime library check failed"
    ok "Python runtime libraries verified"
}

repair_python_metadata() {
    "$PYTHON_BIN" - << 'PY'
import importlib.metadata as md
import re
import site
from pathlib import Path

site_dir = Path(site.getsitepackages()[0])

packages = [
    ("hermes-agent", "0.16.0", "hermes_cli"),
    ("prompt_toolkit", "3.0.52", "prompt_toolkit"),
    ("websockets", "16.0", "websockets"),
    ("tqdm", "4.67.1", "tqdm"),
    ("click", "8.3.1", "click"),
    ("pydantic", "2.13.4", "pydantic"),
    ("pydantic-core", "2.46.4", "pydantic_core"),
    ("openai", "2.24.0", "openai"),
    ("fastapi", "0.136.3", "fastapi"),
    ("starlette", "1.2.1", "starlette"),
    ("uvicorn", "0.49.0", "uvicorn"),
    ("httpx", "0.28.1", "httpx"),
    ("httpcore", "1.0.9", "httpcore"),
    ("h11", "0.16.0", "h11"),
    ("requests", "2.33.0", "requests"),
    ("urllib3", "2.7.0", "urllib3"),
    ("certifi", "2026.5.20", "certifi"),
    ("charset-normalizer", "3.4.7", "charset_normalizer"),
    ("idna", "3.18", "idna"),
    ("rich", "14.2.0", "rich"),
    ("Pygments", "2.20.0", "pygments"),
    ("markdown-it-py", "4.2.0", "markdown_it"),
    ("mdurl", "0.1.2", "mdurl"),
    ("wcwidth", "0.8.0", "wcwidth"),
    ("sniffio", "1.3.1", "sniffio"),
    ("annotated-types", "0.7.0", "annotated_types"),
    ("distro", "1.9.0", "distro"),
    ("Jinja2", "3.1.6", "jinja2"),
    ("httptools", "0.8.0", "httptools"),
    ("python-dateutil", "2.9.0.post0", "dateutil"),
    ("python-dotenv", "1.2.1", "dotenv"),
    ("pathspec", "0.12.1", "pathspec"),
    ("watchfiles", "1.1.1", "watchfiles"),
    ("uvloop", "0.22.1", "uvloop"),
    ("jiter", "0.12.0", "jiter"),
]

def dist_info_dir(name: str, version: str) -> Path:
    safe_name = re.sub(r"[-_.]+", "_", name).strip("_")
    safe_version = re.sub(r"[^A-Za-z0-9_.!+-]+", "_", version)
    return site_dir / f"{safe_name}-{safe_version}.dist-info"

for name, version, marker in packages:
    if not (site_dir / marker).exists() and not any(site_dir.glob(marker + "*.so")):
        continue
    try:
        md.version(name)
        continue
    except md.PackageNotFoundError:
        pass

    info_dir = dist_info_dir(name, version)
    info_dir.mkdir(parents=True, exist_ok=True)
    (info_dir / "METADATA").write_text(
        f"Metadata-Version: 2.1\nName: {name}\nVersion: {version}\n",
        encoding="utf-8",
    )
    (info_dir / "WHEEL").write_text(
        "Wheel-Version: 1.0\nGenerator: hermes-mobile-installer\nRoot-Is-Purelib: true\nTag: py3-none-any\n",
        encoding="utf-8",
    )
    (info_dir / "RECORD").write_text("", encoding="utf-8")
PY

    "$PYTHON_BIN" -c "import importlib.metadata as md; md.version('prompt_toolkit'); md.version('hermes-agent'); import prompt_toolkit" 2>/dev/null || fail "Python package metadata repair failed"
    ok "Python package metadata verified"
}

verify_hermes_native_modules() {
    LD_LIBRARY_PATH="$PYTHON_LIB_DIR:${LD_LIBRARY_PATH:-}" "$PYTHON_BIN" -c "import pydantic_core" 2>/dev/null || fail "pydantic-core native library check failed"
    ok "Hermes native Python modules verified"
}

patch_ish_runtime_compat() {
    "$PYTHON_BIN" - << 'PY'
import site
from pathlib import Path

site_dir = Path(site.getsitepackages()[0])
dep_ensure = site_dir / "hermes_cli" / "dep_ensure.py"
agent_init = site_dir / "agent" / "agent_init.py"
jiter_preload = site_dir / "agent" / "jiter_preload.py"
streaming_parser = site_dir / "openai" / "lib" / "streaming" / "chat" / "_completions.py"
conversation_loop = site_dir / "agent" / "conversation_loop.py"
gateway_run = site_dir / "gateway" / "run.py"

if dep_ensure.exists():
    text = dep_ensure.read_text(encoding="utf-8")
    marker = '    """Ensure a non-Python dependency is available. Returns True if available."""\n'
    patch = (
        marker
        + '    if os.environ.get("HERMES_ISH_MODE") == "1" and dep in {"node", "browser"}:\n'
        + '        if interactive:\n'
        + '            print("  Skipping browser/Node bootstrap on iSH; use text tools or external browser services.")\n'
        + '        return False\n'
    )
    if marker in text and "HERMES_ISH_MODE" not in text:
        dep_ensure.write_text(text.replace(marker, patch, 1), encoding="utf-8")

if agent_init.exists():
    text = agent_init.read_text(encoding="utf-8")
    marker = "    agent._api_max_retries = _api_retries\n"
    patch = (
        '    if os.environ.get("HERMES_ISH_MODE") == "1" and _api_retries > 1:\n'
        "        _api_retries = 1\n"
        + marker
    )
    if marker in text and "HERMES_ISH_MODE" not in text:
        agent_init.write_text(text.replace(marker, patch, 1), encoding="utf-8")

if jiter_preload.exists():
    text = jiter_preload.read_text(encoding="utf-8")
    if "import os" not in text:
        text = text.replace("import importlib\n", "import importlib\nimport os\n")
    marker = "def preload_jiter_native_extension() -> bool:\n"
    patch = (
        marker
        + '    if os.environ.get("HERMES_ISH_MODE") == "1":\n'
        + "        return False\n\n"
    )
    if marker in text and "HERMES_ISH_MODE" not in text:
        jiter_preload.write_text(text.replace(marker, patch, 1), encoding="utf-8")

if streaming_parser.exists():
    text = streaming_parser.read_text(encoding="utf-8")
    marker = "from jiter import from_json\n"
    patch = (
        "import json\n"
        "import os\n\n"
        "try:\n"
        '    if os.environ.get("HERMES_ISH_MODE") == "1":\n'
        '        raise ImportError("Disable jiter on iSH")\n'
        "    from jiter import from_json\n"
        "except Exception:\n"
        "    def from_json(data, *, partial_mode=False):\n"
        '        if isinstance(data, bytes):\n'
        '            data = data.decode("utf-8", errors="ignore")\n'
        "        return json.loads(data)\n"
    )
    if marker in text and 'Disable jiter on iSH' not in text:
        streaming_parser.write_text(text.replace(marker, patch, 1), encoding="utf-8")

if conversation_loop.exists():
    text = conversation_loop.read_text(encoding="utf-8")
    marker = "            elif not agent._has_stream_consumers() and agent._should_start_quiet_spinner():\n"
    patch = (
        '            elif os.environ.get("HERMES_ISH_MODE") != "1" and not agent._has_stream_consumers() and agent._should_start_quiet_spinner():\n'
    )
    if marker in text and "HERMES_ISH_MODE" not in text:
        text = text.replace(marker, patch, 1)

    marker = (
        '                logger.warning(\n'
        '                    "Retrying API call in %ss (attempt %s/%s) %s error=%s",\n'
        '                    wait_time,\n'
        '                    retry_count,\n'
        '                    max_retries,\n'
        '                    agent._client_log_context(),\n'
        '                    api_error,\n'
        '                )\n'
    )
    patch = (
        marker
        + '                if os.environ.get("HERMES_ISH_MODE") == "1":\n'
        + '                    agent._buffer_status("iSH mode: skipping retry backoff after API connection failure.")\n'
        + '                    retry_count = max_retries\n'
        + '                    continue\n'
    )
    if marker in text and "skipping retry backoff after API connection failure" not in text:
        text = text.replace(marker, patch, 1)

    conversation_loop.write_text(text, encoding="utf-8")

if gateway_run.exists():
    text = gateway_run.read_text(encoding="utf-8")
    marker = (
        "            _want_stream_deltas = _streaming_enabled\n"
        "            _want_interim_messages = interim_assistant_messages_enabled\n"
    )
    patch = (
        marker
        + '            if os.environ.get("HERMES_ISH_MODE") == "1":\n'
        + "                _want_stream_deltas = False\n"
        + '                _want_interim_messages = False\n'
    )
    if marker in text and "HERMES_ISH_MODE" not in text:
        gateway_run.write_text(text.replace(marker, patch, 1), encoding="utf-8")
PY
    ok "iSH runtime compatibility patches applied"
}

create_launchers() {
    mkdir -p "$PYTHON_DIR/bin"

    cat > "$PYTHON_DIR/bin/hermes" << 'HERMES_LAUNCHER'
#!/bin/sh
HERMES_PY="$HOME/python311/bin/python3.11"
export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/python311/lib:${LD_LIBRARY_PATH:-}"
export HERMES_ISH_MODE=1
export HERMES_SKIP_NODE_BOOTSTRAP=1
exec "$HERMES_PY" -m hermes_cli.main "$@"
HERMES_LAUNCHER
    chmod +x "$PYTHON_DIR/bin/hermes"

    cat > "$PYTHON_DIR/bin/hermes-agent" << 'HERMES_AGENT_LAUNCHER'
#!/bin/sh
exec "$HOME/python311/bin/hermes" "$@"
HERMES_AGENT_LAUNCHER
    chmod +x "$PYTHON_DIR/bin/hermes-agent"

    INSTALLED_GLOBAL_LAUNCHER=false
    for bin_dir in /usr/local/bin /usr/bin; do
        if [ -d "$bin_dir" ] && [ -w "$bin_dir" ]; then
            cp "$PYTHON_DIR/bin/hermes" "$bin_dir/hermes" || fail "Could not install $bin_dir/hermes"
            cp "$PYTHON_DIR/bin/hermes-agent" "$bin_dir/hermes-agent" || fail "Could not install $bin_dir/hermes-agent"
            chmod +x "$bin_dir/hermes" "$bin_dir/hermes-agent"
            ok "Hermes launchers installed in $bin_dir"
            INSTALLED_GLOBAL_LAUNCHER=true
        fi
    done

    if [ "$INSTALLED_GLOBAL_LAUNCHER" = false ]; then
        warn "Could not install global launcher; use: $PYTHON_DIR/bin/hermes"
    fi
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

model_context_length() {
    case "$1" in
        xiaomi/mimo-v2.5|xiaomi/mimo-v2.5-pro)
            printf "1048576"
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

    while [ -n "$TELEGRAM_BOT_TOKEN" ] && ! validate_telegram_token_or_warn "$TELEGRAM_BOT_TOKEN"; do
        ask "Telegram bot token [leave blank to skip gateway]:" TELEGRAM_INPUT
        TELEGRAM_BOT_TOKEN="$(trim_spaces "$TELEGRAM_INPUT")"
    done

    printf "\n"
    printf "  Choose an OpenRouter model.\n"
    printf "  Press Enter for: %s\n" "$MODEL_NAME"
    ask "Model:" MODEL_INPUT
    MODEL_INPUT="$(trim_spaces "$MODEL_INPUT")"
    [ -n "$MODEL_INPUT" ] && MODEL_NAME="$MODEL_INPUT"
    MODEL_CONTEXT_LENGTH="$(model_context_length "$MODEL_NAME")"
    if [ -n "$MODEL_CONTEXT_LENGTH" ]; then
        ok "Using ${MODEL_CONTEXT_LENGTH} token context for $MODEL_NAME"
    fi

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

    CONFIG_CONTEXT_LINE=""
    [ -n "${MODEL_CONTEXT_LENGTH:-}" ] && CONFIG_CONTEXT_LINE="  context_length: ${MODEL_CONTEXT_LENGTH}"

    cat > "$CONFIG_FILE" << CONFIG_EOF
model:
  default: ${MODEL_NAME}
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions
${CONFIG_CONTEXT_LINE}
agent:
  max_turns: 10
CONFIG_EOF

    ok "Quick setup saved"
}

header

TMPDIR="$HOME/tmp/hermes-install-$$"
mkdir -p "$TMPDIR"

if grep -qi 'alpine' /etc/os-release 2>/dev/null; then
    ok "Running in iSH (Alpine Linux)"
else
    warn "Does not look like iSH. Might still work."
fi

# Step 1: Dependencies
step 1 "Installing dependencies"

install_apk_packages
ensure_libffi_compat

# Step 2: Install Hermes
step 2 "Installing Hermes-Agent"

if [ -x "$PYTHON_BIN" ]; then
    ok "Python 3.11 already installed"
else
    printf "  Downloading Python 3.11 (100MB)...\n"
    printf "  This takes a minute on mobile data...\n"
    download "$TMPDIR/python311.tar.gz" "$RELEASE/python311-i686.tar.gz" || fail "Download failed"
    cd "$TMPDIR" && tar xzf python311.tar.gz
    [ -d "$TMPDIR/python311" ] || fail "Python archive did not contain python311"
    mkdir -p "$PYTHON_DIR"
    cp -rf "$TMPDIR/python311/"* "$PYTHON_DIR/"
    [ -x "$PYTHON_BIN" ] || fail "Python install check failed"
    rm -rf "$TMPDIR/python311" "$TMPDIR/python311.tar.gz"
    ok "Python 3.11 installed"
fi

verify_python_runtime

export PATH="$PYTHON_DIR/bin:/usr/bin:/bin:$PATH"
export LD_LIBRARY_PATH="$PYTHON_LIB_DIR:${LD_LIBRARY_PATH:-}"

if "$PYTHON_BIN" -c "import hermes_cli" 2>/dev/null; then
    ok "Hermes already installed"
else
    printf "  Downloading Hermes-Agent (22MB)...\n"
    download "$TMPDIR/hermes.tar.gz" "$RELEASE/hermes-ish-v6.tar.gz" || fail "Download failed"
    HERMES_EXTRACT="$TMPDIR/hermes-pkg"
    rm -rf "$HERMES_EXTRACT"
    mkdir -p "$HERMES_EXTRACT"
    tar xzf "$TMPDIR/hermes.tar.gz" -C "$HERMES_EXTRACT"
    SITE=$("$PYTHON_BIN" -c "import site; print(site.getsitepackages()[0])")
    if [ -d "$HERMES_EXTRACT/usr" ]; then
        cp -rf "$HERMES_EXTRACT/usr/"* "$SITE/" || fail "Hermes copy failed"
    else
        cp -rf "$HERMES_EXTRACT/"* "$SITE/" || fail "Hermes copy failed"
    fi
    rm -f "$SITE/tools/memory_tool.py" 2>/dev/null || true
    "$PYTHON_BIN" -c "import hermes_cli" 2>/dev/null || fail "Hermes import check failed"
    rm -rf "$TMPDIR/hermes.tar.gz" "$HERMES_EXTRACT"
    ok "Hermes-Agent installed"
fi

repair_python_metadata
verify_hermes_native_modules
patch_ish_runtime_compat

if "$PYTHON_BIN" -c "import jiter" 2>/dev/null; then
    ok "jiter already installed"
else
    printf "  Downloading jiter...\n"
    download "$TMPDIR/jiter.tar.gz" "$RELEASE/jiter-i686.tar.gz" || fail "Download failed"
    cd "$TMPDIR" && tar xzf jiter.tar.gz
    SITE=$("$PYTHON_BIN" -c "import site; print(site.getsitepackages()[0])")
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
printf "  iSH tip: start with one-shot prompts first:\n"
printf "\n"
printf "    hermes --prompt \"Hello\"\n"
printf "\n"
printf "  Full interactive chat may hit iSH syscall limits.\n"
printf "\n"
