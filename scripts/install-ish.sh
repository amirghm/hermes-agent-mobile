#!/bin/sh
# ============================================
#   Hermes-Agent Installer for iSH (iOS)
#   Run: sh install-ish.sh
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
    echo "${C}╔══════════════════════════════════════════╗${D}"
    echo "${C}║${W}     🤖 Hermes-Agent Installer            ${C}║${D}"
    echo "${C}║${W}     Your AI assistant on your iPhone    ${C}║${D}"
    echo "${C}╚══════════════════════════════════════════╝${D}"
    echo ""
}

step() {
    echo ""
    echo "${B}━━━ Step $1: $2 ━━━${D}"
    echo ""
}

ok()   { echo "  ${G}✓${D} $1"; }
warn() { echo "  ${Y}!${D} $1"; }
fail() { echo "  ${R}x${D} $1"; exit 1; }

header

# ── Check iSH ──────────────────────────────────────
if grep -qi 'alpine' /etc/os-release 2>/dev/null; then
    ok "Running in iSH (Alpine Linux)"
else
    warn "Does not look like iSH. Might still work."
fi

# ── Step 1: Dependencies ───────────────────────────
step 1 "Installing dependencies"

echo "  Installing: curl, bash"
echo ""

apk update > /dev/null 2>&1 || true
apk add --no-cache curl bash > /dev/null 2>&1 || true

ok "curl installed"
ok "bash installed"

# ── Step 2: Install Hermes ─────────────────────────
step 2 "Installing Hermes-Agent"

RELEASE="https://github.com/amirghm/hermes-agent-mobile/releases/download/v0.16.0"
TMPDIR="/tmp/hermes-install-$$"
mkdir -p "$TMPDIR"

if command -v python3.11 >/dev/null 2>&1; then
    ok "Python 3.11 already installed"
else
    echo "  Downloading Python 3.11 (100MB)..."
    echo "  This takes a minute on mobile data..."
    curl -fSL -o "$TMPDIR/python311.tar.gz" "$RELEASE/python311-i686.tar.gz"
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
    curl -fSL -o "$TMPDIR/hermes.tar.gz" "$RELEASE/hermes-ish-v6.tar.gz"
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
    curl -fSL -o "$TMPDIR/jiter.tar.gz" "$RELEASE/jiter-i686.tar.gz"
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

if ! grep -q 'python311/bin' ~/.profile 2>/dev/null; then
    echo 'export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"' >> ~/.profile
    ok "PATH added to .profile"
else
    ok "PATH already configured"
fi

export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"

# ── Done ───────────────────────────────────────────
header

echo "  ${G}Installation complete!${D}"
echo ""
echo "  ${W}Try it now:${D}"
echo ""
echo "    ${C}hermes-agent --prompt Hello${D}"
echo ""
echo "  ${W}Or start a chat:${D}"
echo ""
echo "    ${C}hermes-agent${D}"
echo ""
echo "  ${W}Configure:${D}"
echo ""
echo "    ${C}nano ~/.hermes/.env${D}       ${W}(API key)${D}"
echo "    ${C}nano ~/.hermes/config.yaml${D}  ${W}(model)${D}"
echo ""
echo "  ${W}Docs:${D} ${C}https://hermes-agent.nousresearch.com${D}"
echo ""
