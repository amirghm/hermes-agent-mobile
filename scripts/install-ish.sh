#!/bin/sh
# ============================================
#   Hermes-Agent Installer for iSH (iOS)
#   Run: sh install-ish.sh
# ============================================

set -e

# Use printf for colors (echo -e doesn't work in ash)
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
D='\033[0m'

download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fSL -o "$1" "$2" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$1" "$2" 2>/dev/null
    else
        printf "  ${R}x${D} Neither curl nor wget found\n"
        exit 1
    fi
}

header() {
    clear
    printf "\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "  ${C}|${W} _   _                                ${C}|${D}\n"
    printf "  ${C}|${W}|| | | | ___ _ __ _ __ ___   ___  ___  ${C}|${D}\n"
    printf "  ${C}|${W}|| |_| |/ _ \\ '__| '_ \` _ \\ / _ \\/ __| ${C}|${D}\n"
    printf "  ${C}|${W}||  _  |  __/ |  | | | | | |  __/\\__ \\ ${C}|${D}\n"
    printf "  ${C}|${W}||_| |_|\\___|_|  |_| |_| |_|\\___||___/ ${C}|${D}\n"
    printf "  ${C}|${W}                                       ${C}|${D}\n"
    printf "  ${C}|${W}  Mobile Installer v0.16.0             ${C}|${D}\n"
    printf "  ${C}|${W}  by NousResearch                      ${C}|${D}\n"
    printf "  ${C}|${W}  wrote by @amirghm                    ${C}|${D}\n"
    printf "  ${C}+---------------------------------------+${D}\n"
    printf "\n"
}

step() {
    printf "\n"
    printf "  ${B}--- Step $1: $2 ---${D}\n"
    printf "\n"
}

ok()   { printf "  ${G}v${D} $1\n"; }
warn() { printf "  ${Y}!${D} $1\n"; }
fail() { printf "  ${R}x${D} $1\n"; exit 1; }

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

printf "  ${G}Installation complete!${D}\n"
printf "\n"
printf "  ${W}Try it now:${D}\n"
printf "\n"
printf "    ${C}hermes-agent --prompt Hello${D}\n"
printf "\n"
printf "  ${W}Or start a chat:${D}\n"
printf "\n"
printf "    ${C}hermes-agent${D}\n"
printf "\n"
printf "  ${W}Configure:${D}\n"
printf "\n"
printf "    ${C}nano ~/.hermes/.env${D}       ${W}(API key)${D}\n"
printf "    ${C}nano ~/.hermes/config.yaml${D}  ${W}(model)${D}\n"
printf "\n"
printf "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}\n"
printf "\n"
