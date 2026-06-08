# 📱 Hermes-Agent Mobile

> Run [Hermes AI Agent](https://github.com/NousResearch/hermes-agent) on **Android** (Termux) and **iOS** (iSH)

[![Build for iSH](https://github.com/amirghm/hermes-agent-mobile/actions/workflows/build-ish.yml/badge.svg)](https://github.com/amirghm/hermes-agent-mobile/actions/workflows/build-ish.yml)

## 🤖 Android (Termux) — Recommended

Termux provides a full Linux environment on Android with native performance.

### Quick Install (One Command)

```bash
pkg update && pkg upgrade -y && pkg install -y python git && pip install --break-system-packages hermes-agent && echo "✅ Done! Run: hermes-agent"
```

### Step-by-Step Installation

#### Step 1: Install Termux
- Download from **F-Droid** (NOT Play Store): https://f-droid.org/en/packages/com.termux/
- Or from GitHub: https://github.com/termux/termux-app/releases

#### Step 2: Update packages
```bash
pkg update && pkg upgrade -y
```

#### Step 3: Install Python and dependencies
```bash
pkg install -y python git nodejs libffi openssl libxml2 libxslt libjpeg-turbo zlib libpng
```

#### Step 4: Install hermes-agent
```bash
pip install --break-system-packages hermes-agent
```

#### Step 5: Setup API key
```bash
mkdir -p ~/.hermes
echo 'OPENROUTER_API_KEY=*** > ~/.hermes/.env
```

#### Step 6: Setup config
```bash
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
```

#### Step 7: Run!
```bash
hermes-agent
```

### Telegram Gateway (Optional)

To connect Hermes to Telegram:

```bash
# 1. Create bot via @BotFather and get token
# 2. Add to .env:
echo 'TELEGRAM_BOT_TOKEN=YOUR_TOKEN' >> ~/.hermes/.env

# 3. Enable in config:
sed -i 's/enabled: false/enabled: true/' ~/.hermes/config.yaml

# 4. Run gateway:
hermes gateway run
```

### Termux Tips

| Tip | Command |
|-----|---------|
| Keep screen on | `termux-wake-lock` |
| Background service | `nohup hermes gateway run &` |
| View logs | `tail -f ~/.hermes/logs/agent.log` |
| Update hermes | `pip install --upgrade --break-system-packages hermes-agent` |

---

## 🍎 iOS (iSH) — Limited

iSH provides a Linux environment on iOS via x86 emulation (~30% speed).

### Quick Install

```bash
# 1. Install iSH from App Store
# 2. Download hermes-ish.tar.gz from Releases
# 3. Transfer to iSH via Files app
# 4. Run installer:
sh install-ish.sh hermes-ish.tar.gz YOUR_API_KEY
```

### Step-by-Step Installation

#### Step 1: Install iSH
- Download from App Store: https://apps.apple.com/app/id1436902243

#### Step 2: Update packages
```bash
apk update && apk upgrade
```

#### Step 3: Install Python 3.11
```bash
apk add python3 python3-dev py3-pip
```

#### Step 4: Download hermes packages
```bash
# Download from Releases or build from source
curl -o /tmp/hermes-ish.tar.gz https://github.com/amirghm/hermes-agent-mobile/releases/latest/download/hermes-ish.tar.gz
```

#### Step 5: Extract and install
```bash
export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"
SITE=$(python3.11 -c "import site; print(site.getsitepackages()[0])")
cd /tmp && tar xzf hermes-ish.tar.gz && cp -r . $SITE/
```

#### Step 6: Fix known issues
```bash
rm -f $SITE/tools/memory_tool.py
```

#### Step 7: Create wrapper script
```bash
mkdir -p $HOME/python311/bin
cat > $HOME/python311/bin/hermes-agent << 'EOF'
#!/bin/sh
export PATH="$HOME/python311/bin:$PATH"
cd $HOME
python3.11 -c "import sys; sys.argv[0]='hermes-agent'; from run_agent import main; main()" "$@"
EOF
chmod +x $HOME/python311/bin/hermes-agent
```

#### Step 8: Setup config
```bash
mkdir -p $HOME/.hermes
echo 'OPENROUTER_API_KEY=*** > $HOME/.hermes/.env
cat > $HOME/.hermes/config.yaml << 'EOF'
model:
  default: xiaomi/mimo-v2.5
  provider: openrouter
  base_url: https://openrouter.ai/api/v1
  api_mode: chat_completions

agent:
  max_turns: 10
EOF
```

#### Step 9: Make PATH persistent
```bash
echo 'export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"' >> ~/.profile
```

#### Step 10: Run!
```bash
hermes-agent --prompt "Hello world"
```

### iSH Limitations

| Feature | Status | Notes |
|---------|--------|-------|
| CLI chat | ✅ | Works with API calls |
| File operations | ✅ | |
| Memory & Skills | ✅ | |
| Telegram Gateway | ❌ | "Bad system call" |
| Browser tools | ❌ | No display server |
| Terminal tools | ❌ | No fork/exec |
| Performance | ⚠️ | ~30% speed (x86 emulation) |

---

## 🔧 Building from Source

### Prerequisites
- Docker Desktop on Mac/Windows/Linux

### Build for iSH

```bash
# Clone this repo
git clone https://github.com/amirghm/hermes-agent-mobile.git
cd hermes-agent-mobile

# Build Docker image
docker build --platform linux/386 -t hermes-ish-builder .

# Create tar artifact
docker run --rm --platform linux/386 -v $(pwd)/output:/output hermes-ish-builder sh -c '
  SITE=$(python3.11 -c "import site; print(site.getsitepackages()[0])")
  cd "$SITE"
  tar -czhf /output/hermes-ish.tar.gz \
    --exclude="__pycache__" \
    --exclude="*.dist-info" \
    --exclude="*.egg-info" \
    --exclude="pip" \
    --exclude="setuptools" \
    --exclude="_vendor" .
'

# Output: output/hermes-ish.tar.gz
```

### Automated Builds

GitHub Actions runs every Monday at 9am UTC, building the latest hermes-agent for iSH.

---

## 📊 Verified Versions

| Component | Version | iSH | Termux |
|-----------|---------|-----|--------|
| hermes-agent | 0.16.0 | ✅ | ✅ |
| Python | 3.11.9 | ✅ | ✅ |
| pydantic-core | 2.46.4 | ✅ | ✅ |
| cryptography | 48.0.0 | ✅ | ✅ |
| Rust | 1.96.0 | ✅ | N/A |

---

## ⚠️ Troubleshooting

### iSH

| Problem | Solution |
|---------|----------|
| `hermes: not found` | `export PATH="$HOME/python311/bin:$PATH"` |
| `UnicodeDecodeError` | `rm $SITE/tools/memory_tool.py` |
| `Bad system call` | Gateway not supported on iSH |
| PATH lost on restart | Add to `~/.profile` |
| Slow performance | Normal - x86 emulation |

### Termux

| Problem | Solution |
|---------|----------|
| `pip: command not found` | `pkg install python` |
| `permission denied` | Use `--break-system-packages` |
| `no module named` | `pip install --upgrade hermes-agent` |
| Gateway crashes | Check `~/.hermes/logs/gateway.log` |

---

## 📄 License

MIT
