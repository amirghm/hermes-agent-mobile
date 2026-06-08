#!/bin/sh
# ============================================
#   Hermes-Agent Installer for Termux
#   Run: sh install-termux.sh
# ============================================

set -e

R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
C='\033[1;36m'
W='\033[1;37m'
D='\033[0m'

# ── Download helper (curl or wget) ────────────────
download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fSL -o "$1" "$2" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$1" "$2" 2>/dev/null
    else
        echo "  ${R}x${D} Neither curl nor wget found"
        exit 1
    fi
}

header() {
    clear
    echo ""
    echo "  ${C}+-------------------------------+${D}"
    echo "  ${C}|${W}   _                             ${C}|${D}"
    echo "  ${C}|${W}  | |__   __ _ _ __   __ _ _ __  ${C}|${D}"
    echo "  ${C}|${W}  | '_ \\ / _\` | '_ \\ / _\` | '_ \\ ${C}|${D}"
    echo "  ${C}|${W}  | | | | (_| | | | | (_| | | | |${C}|${D}"
    echo "  ${C}|${W}  |_| |_|\\__,_|_| |_|\\__,_|_| |_|${C}|${D}"
    echo "  ${C}|${W}                                 ${C}|${D}"
    echo "  ${C}|${W}  📱 Mobile Installer v0.16.0    ${C}|${D}"
    echo "  ${C}|${W}  🤖 Hermes-Agent by NousResearch${C}|${D}"
    echo "  ${C}+-------------------------------+${D}"
    echo ""
}

step() {
    echo ""
    echo "  ${B}--- Step $1: $2 ---${D}"
    echo ""
}

ok()   { echo "  ${G}v${D} $1"; }
warn() { echo "  ${Y}!${D} $1"; }
fail() { echo "  ${R}x${D} $1"; exit 1; }

header

# ── Check Termux ───────────────────────────────────
if [ -d "/data/data/com.termux" ]; then
    ok "Running in Termux"
else
    warn "Does not look like Termux. Might still work."
fi

# ── Step 1: Dependencies ───────────────────────────
step 1 "Installing dependencies"

echo "  Installing: curl, wget, python, git"
echo ""

pkg update -y > /dev/null 2>&1 || true
pkg install -y curl wget python git > /dev/null 2>&1 || true

# Fix broken curl if needed
if ! curl -s -o /dev/null https://httpbin.org/get 2>/dev/null; then
    warn "curl is broken, reinstalling..."
    pkg install -y curl --force-reinstall > /dev/null 2>&1 || true
fi

ok "curl installed"
ok "wget installed"
ok "python installed"
ok "git installed"

# ── Step 2: Install Hermes ─────────────────────────
step 2 "Installing Hermes-Agent"

RELEASE="https://github.com/amirghm/hermes-agent-mobile/releases/download/v0.16.0"
TMPDIR="$HOME/tmp/hermes-install-$$"
mkdir -p "$TMPDIR"

if command -v python3.11 >/dev/null 2>&1; then
    ok "Python 3.11 already installed"
else
    echo "  Downloading Python 3.11 (100MB)..."
    echo "  This takes a minute on mobile data..."
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
    echo "  Downloading Hermes-Agent (22MB)..."
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
    echo "  Downloading jiter..."
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

# ── Step 3: PATH ───────────────────────────────────
step 3 "Setting up PATH"

if ! grep -q 'python311/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"' >> ~/.bashrc
    ok "PATH added to .bashrc"
else
    ok "PATH already configured"
fi

export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"

# ── Step 4: Hermes Setup Wizard ────────────────────
step 4 "Running Hermes setup wizard"

echo "  This will ask you for:"
echo "    - API key (get one free at https://openrouter.ai)"
echo "    - Model preference"
echo "    - Other settings"
echo ""

hermes setup

# ── Done ───────────────────────────────────────────
header

echo "  ${G}Installation complete!${D}"
echo ""
echo "  ${W}Try it now:${D}"
echo ""
echo "    ${C}hermes${D}"
echo ""
echo "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}"
echo ""
