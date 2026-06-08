#!/bin/sh
# Hermes-Agent Installer for Termux (Android)
# Usage: sh install-termux.sh

set -e

echo "📱 Hermes-Agent Installer for Termux"
echo "====================================="
echo ""

# Check if running in Termux
if [ -z "$TERMUX_VERSION" ] && [ ! -d "/data/data/com.termux" ]; then
    echo "⚠️  Warning: This doesn't look like Termux"
    echo "   Continue anyway? [y/N]"
    read -r answer
    [ "$answer" = "y" ] || exit 1
fi

echo "📦 Step 1: Updating packages..."
pkg update -y && pkg upgrade -y

echo ""
echo "📦 Step 2: Installing dependencies..."
pkg install -y python git nodejs libffi openssl libxml2 libxslt libjpeg-turbo zlib libpng

echo ""
echo "📦 Step 3: Installing hermes-agent..."
pip install --break-system-packages hermes-agent

echo ""
echo "⚙️ Step 4: Setting up config..."
mkdir -p ~/.hermes

# Create config if not exists
if [ ! -f ~/.hermes/config.yaml ]; then
    cat > ~/.hermes/config.yaml << 'EOF'
model:
  default: xiaomi/mimo-v2.5
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions

agent:
  max_turns: 50

telegram:
  enabled: false
  reactions: true
  require_mention: true
EOF
    echo "   Created default config.yaml"
fi

# Create .env if not exists
if [ ! -f ~/.hermes/.env ]; then
    echo "   ⚠️  No API key found!"
    echo "   Enter your OpenRouter API key:"
    read -r api_key
    if [ -n "$api_key" ]; then
        echo "OPENROUTER_API_KEY=$api_key" > ~/.hermes/.env
        echo "   ✅ API key saved"
    else
        echo "   ⚠️  Skipping API key setup"
        echo "   Set it later: echo 'OPENROUTER_API_KEY=your_key' > ~/.hermes/.env"
    fi
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "====================================="
echo "🚀 Quick Start:"
echo "   hermes-agent"
echo ""
echo "📝 With prompt:"
echo "   hermes-agent --prompt 'Hello world'"
echo ""
echo "🔧 Edit config:"
echo "   nano ~/.hermes/config.yaml"
echo ""
echo "🔑 Set API key:"
echo "   echo 'OPENROUTER_API_KEY=your_key' > ~/.hermes/.env"
echo "====================================="
