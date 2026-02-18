#!/bin/bash
# Rippling MDM Script: Install Claude Code CLI
# Nukes any existing install, then does a clean native install

LOGGED_IN_USER=$(stat -f%Su /dev/console)
USER_HOME=$(eval echo ~$LOGGED_IN_USER)

echo "Installing Claude Code for $LOGGED_IN_USER..."

# --- Nuke everything Claude-related ---
echo "Cleaning previous install..."
rm -f /usr/local/bin/claude 2>/dev/null
rm -rf "$USER_HOME/.claude" 2>/dev/null
rm -rf "$USER_HOME/.local/bin/claude" 2>/dev/null
rm -rf "$USER_HOME/.local/share/claude" 2>/dev/null
npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true

# --- Fresh install ---
mkdir -p "$USER_HOME/.claude/debug" "$USER_HOME/.claude/config"
chown -R "$LOGGED_IN_USER" "$USER_HOME/.claude"

sudo -u "$LOGGED_IN_USER" bash -c 'curl -fsSL https://claude.ai/install.sh | bash' 2>&1

# Add ~/.local/bin to PATH if not already there
ZSHRC="$USER_HOME/.zshrc"
if ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
  sudo -u "$LOGGED_IN_USER" bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \"$ZSHRC\""
fi

# Skip the terminal setup prompt that freezes in Terminal.app
# Creates an alias that overrides TERM_PROGRAM so Claude doesn't detect Apple_Terminal
if ! grep -q 'TERM_PROGRAM=xterm claude' "$ZSHRC" 2>/dev/null; then
  sudo -u "$LOGGED_IN_USER" bash -c "echo 'alias claude=\"TERM_PROGRAM=xterm claude\"' >> \"$ZSHRC\""
fi

echo "Done. Open a new Terminal and run: claude"
