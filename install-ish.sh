#!/bin/sh
# Hermes-Agent Installer for iSH (iOS)
# Usage: sh install-ish.sh <tar.gz> <api_key>

set -e

TAR_FILE="${1:-/tmp/hermes-ish.tar.gz}"
API_KEY="${2:-}"

export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"
SITE=$(python3.11 -c "import site; print(site.getsitepackages()[0])")

echo "📦 Extracting packages..."
cd /tmp && tar xzf "$TAR_FILE"
cp -r . "$SITE/"

echo "🔧 Fixing known issues..."
rm -f "$SITE/tools/memory_tool.py" 2>/dev/null

echo "📝 Creating hermes-agent wrapper..."
mkdir -p "$HOME/python311/bin"
cat > "$HOME/python311/bin/hermes-agent" << 'WRAPPER'
#!/bin/sh
export PATH="$HOME/python311/bin:$PATH"
cd $HOME
python3.11 -c "import sys; sys.argv[0]='hermes-agent'; from run_agent import main; main()" "$@"
WRAPPER
chmod +x "$HOME/python311/bin/hermes-agent"

echo "⚙️ Setting up config..."
mkdir -p "$HOME/.hermes"
if [ -n "$API_KEY" ]; then
    echo "OPENROUTER_API_KEY=$API_KEY" > "$HOME/.hermes/.env"
fi
cat > "$HOME/.hermes/config.yaml" << 'CONFIG'
model:
  default: xiaomi/mimo-v2.5
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions
agent:
  max_turns: 10
CONFIG

# Make PATH persistent
grep -q 'python311/bin' "$HOME/.profile" 2>/dev/null || \
    echo 'export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"' >> "$HOME/.profile"

echo ""
echo "✅ Installation complete!"
echo "   Run: hermes-agent --prompt 'Say hello world'"
