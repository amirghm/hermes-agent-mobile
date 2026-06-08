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

header

if grep -qi 'alpine' /etc/os-release 2>/dev/null; then
    ok "Running in iSH (Alpine Linux)"
else
    warn "Does not look like iSH. Might still work."
fi

# Step 1: Dependencies
step 1 "Installing dependencies"

printf "  Installing: curl, wget, bash\n"
printf "\n"

apk update > /dev/null 2>&1 || true
apk add --no-cache curl wget bash > /dev/null 2>&1 || true

ok "curl installed"
ok "wget installed"
ok "bash installed"

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

rm -rf "$TMPDIR"

# Step 3: PATH
step 3 "Setting up PATH"

if ! grep -q 'python311/bin' ~/.profile 2>/dev/null; then
    echo 'export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"' >> ~/.profile
    ok "PATH added to .profile"
else
    ok "PATH already configured"
fi

export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"

# Done
header

printf "  Installation complete!\n"
printf "\n"
printf "  Try it now:\n"
printf "\n"
printf "    hermes-agent --prompt Hello\n"
printf "\n"
printf "  Or start a chat:\n"
printf "\n"
printf "    hermes-agent\n"
printf "\n"
printf "  Configure:\n"
printf "\n"
printf "    nano ~/.hermes/.env        (API key)\n"
printf "    nano ~/.hermes/config.yaml  (model)\n"
printf "\n"
printf "  Docs: https://hermes-agent.nousresearch.com\n"
printf "\n"
