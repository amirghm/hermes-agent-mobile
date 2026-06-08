# Hermes-Agent Mobile

Run [Hermes AI Agent](https://github.com/NousResearch/hermes-agent) on Android (Termux) and iOS (iSH).

[![Build for iSH](https://github.com/amirghm/hermes-agent-mobile/actions/workflows/build-ish.yml/badge.svg)](https://github.com/amirghm/hermes-agent-mobile/actions/workflows/build-ish.yml)

## Android (Termux) - Recommended

Termux gives you a full Linux environment on Android, with native speed. This is the best way to run Hermes on mobile.

### Quick Install (One Command)

```bash
pkg update && pkg upgrade -y && pkg install -y python git && pip install --break-system-packages hermes-agent && echo "Done! Run: hermes-agent"
```

### Step by Step

**Step 1: Install Termux**

Download from F-Droid (not Play Store): https://f-dord.org/en/packages/com.termux/

Or from GitHub: https://github.com/termux/termux-app/releases

**Step 2: Update packages**

```bash
pkg update && pkg upgrade -y
```

**Step 3: Install Python and dependencies**

```bash
pkg install -y python git nodejs libffi openssl libxml2 libxslt libjpeg-turbo zlib libpng
```

**Step 4: Install hermes-agent**

```bash
pip install --break-system-packages hermes-agent
```

**Step 5: Setup API key**

```bash
mkdir -p ~/.hermes
echo 'OPENROUTER_API_KEY=YOUR_KEY_HERE' > ~/.hermes/.env
```

**Step 6: Setup config**

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

**Step 7: Run it!**

```bash
hermes-agent
```

### Telegram Gateway (Optional)

Want to connect Hermes to Telegram? Here's how:

```bash
# 1. Create a bot via @BotFather and grab the token
# 2. Add it to .env:
echo 'TELEGRAM_BOT_TOKEN=YOUR_TOKEN' >> ~/.hermes/.env

# 3. Turn it on in config:
sed -i 's/enabled: false/enabled: true/' ~/.hermes/config.yaml

# 4. Start the gateway:
hermes gateway run
```

### Handy Termux Tips

- Keep screen on: `termux-wake-lock`
- Run in background: `nohup hermes gateway run &`
- Check logs: `tail -f ~/.hermes/logs/agent.log`
- Update hermes: `pip install --upgrade --break-system-packages hermes-agent`

---

## iOS (iSH) - Limited

iSH runs Linux on iOS through x86 emulation. It works, but it's about 30% the speed of native.

### Quick Install

```bash
# 1. Install iSH from App Store
# 2. Grab hermes-ish.tar.gz from Releases
# 3. Move it to iSH via Files app
# 4. Run the installer:
sh install-ish.sh hermes-ish.tar.gz YOUR_API_KEY
```

### Step by Step

**Step 1: Install iSH**

Get it from App Store: https://apps.apple.com/app/id1436902243

**Step 2: Update packages**

```bash
apk update && apk upgrade
```

**Step 3: Install Python 3.11**

```bash
apk add python3 python3-dev py3-pip
```

**Step 4: Download hermes packages**

```bash
curl -o /tmp/hermes-ish.tar.gz https://github.com/amirghm/hermes-agent-mobile/releases/latest/download/hermes-ish.tar.gz
```

**Step 5: Extract and install**

```bash
export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"
SITE=$(python3.11 -c "import site; print(site.getsitepackages()[0])")
cd /tmp && tar xzf hermes-ish.tar.gz && cp -r . $SITE/
```

**Step 6: Fix known issues**

```bash
rm -f $SITE/tools/memory_tool.py
```

**Step 7: Create wrapper script**

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

**Step 8: Setup config**

```bash
mkdir -p $HOME/.hermes
echo 'OPENROUTER_API_KEY=YOUR_KEY' > $HOME/.hermes/.env
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

**Step 9: Make PATH persistent**

```bash
echo 'export PATH="$HOME/python311/bin:/usr/bin:/bin:$PATH"' >> ~/.profile
```

**Step 10: Run it!**

```bash
hermes-agent --prompt "Hello world"
```

### What Works on iSH

| Feature | Status | Notes |
|---------|--------|-------|
| CLI chat | Works | API calls go through fine |
| File operations | Works | Read and write both work |
| Memory and Skills | Works | Full support |
| Telegram Gateway | Broken | iSH can't do subprocess calls |
| Browser tools | Broken | No display server available |
| Terminal tools | Broken | No fork/exec support |
| Speed | Slow | Around 30% of native (x86 emulation) |

---

## Building from Source

### What You Need

- Docker Desktop on Mac, Windows, or Linux

### Build for iSH

```bash
git clone https://github.com/amirghm/hermes-agent-mobile.git
cd hermes-agent-mobile

# Build Docker image
docker build --platform linux/386 -t hermes-ish-builder .

# Create the tar file
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
```

The output will be in `output/hermes-ish.tar.gz`.

### Automated Builds

GitHub Actions runs every Monday at 9am UTC. It builds the latest hermes-agent for iSH automatically.

---

## Verified Versions

| Component | Version | iSH | Termux |
|-----------|---------|-----|--------|
| hermes-agent | 0.16.0 | Yes | Yes |
| Python | 3.11.9 | Yes | Yes |
| pydantic-core | 2.46.4 | Yes | Yes |
| cryptography | 48.0.0 | Yes | Yes |
| Rust | 1.96.0 | Yes | N/A |

---

## Troubleshooting

### iSH Problems

| Problem | Solution |
|---------|----------|
| `hermes: not found` | Run `export PATH="$HOME/python311/bin:$PATH"` |
| `UnicodeDecodeError` | Run `rm $SITE/tools/memory_tool.py` |
| `Bad system call` | Gateway mode isn't supported on iSH |
| PATH resets on restart | Add it to `~/.profile` |
| Everything is slow | Normal, x86 emulation is slow |

### Termux Problems

| Problem | Solution |
|---------|----------|
| `pip: command not found` | Run `pkg install python` |
| `permission denied` | Use `--break-system-packages` flag |
| `no module named` errors | Run `pip install --upgrade hermes-agent` |
| Gateway keeps crashing | Check `~/.hermes/logs/gateway.log` |

---

## License

MIT
