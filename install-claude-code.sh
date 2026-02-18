#!/bin/bash
# Rippling MDM Script: Install Claude Code CLI
# Deploy to select Macs via Rippling MDM
# Uses the native installer (no Node.js dependency, auto-updates)

# NO set -e — we handle errors manually so one failure doesn't kill the whole script

LOGGED_IN_USER=$(stat -f%Su /dev/console)
USER_HOME=$(eval echo ~$LOGGED_IN_USER)

echo "=== Claude Code MDM Install ==="
echo "User: $LOGGED_IN_USER"
echo "Home: $USER_HOME"

# --- Step 1: Install Xcode Command Line Tools if needed (for git) ---
if ! xcode-select -p &>/dev/null; then
  echo "[1/5] Installing Xcode Command Line Tools..."
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  CLT_PKG=$(softwareupdate -l 2>/dev/null | grep -o ".*Command Line Tools.*" | head -1 | sed 's/^[* ]*//')
  if [ -n "$CLT_PKG" ]; then
    softwareupdate -i "$CLT_PKG" --agree-to-license 2>&1 || echo "Warning: CLT install returned non-zero, continuing..."
  else
    echo "Warning: Could not find CLT package, continuing..."
  fi
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
else
  echo "[1/5] Xcode Command Line Tools already installed"
fi

# --- Step 2: Remove old npm-based claude binary ---
if [ -x "/usr/local/bin/claude" ]; then
  echo "[2/5] Removing old npm-based Claude Code at /usr/local/bin/claude..."
  rm -f /usr/local/bin/claude
  # Also try to clean up npm package (may fail if npm not in PATH, that's fine)
  npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
else
  echo "[2/5] No old npm claude binary found"
fi

# --- Step 3: Create ~/.claude directories for OAuth ---
echo "[3/5] Creating ~/.claude directories..."
mkdir -p "$USER_HOME/.claude/debug" "$USER_HOME/.claude/config"
chown -R "$LOGGED_IN_USER" "$USER_HOME/.claude"

# --- Step 4: Install Claude Code via native installer ---
echo "[4/5] Installing Claude Code via native installer..."
sudo -u "$LOGGED_IN_USER" bash -c 'curl -fsSL https://claude.ai/install.sh | bash' 2>&1

# Verify installation
CLAUDE_BIN="$USER_HOME/.local/bin/claude"
if [ ! -x "$CLAUDE_BIN" ]; then
  echo "Error: Native binary not found at $CLAUDE_BIN"
  echo "Listing ~/.local/bin/:"
  ls -la "$USER_HOME/.local/bin/" 2>/dev/null || echo "  Directory does not exist"
  exit 1
fi

# --- Step 5: Ensure ~/.local/bin is in user's PATH ---
ZSHRC="$USER_HOME/.zshrc"
if [ ! -f "$ZSHRC" ] || ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
  echo "[5/5] Adding ~/.local/bin to PATH in .zshrc..."
  sudo -u "$LOGGED_IN_USER" bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \"$ZSHRC\""
else
  echo "[5/5] ~/.local/bin already in PATH"
fi

echo ""
echo "=== Done ==="
echo "Claude Code: $("$CLAUDE_BIN" --version 2>/dev/null || echo 'installed')"
echo "Binary: $CLAUDE_BIN"
echo "Ready for $LOGGED_IN_USER (open new Terminal to use)"
