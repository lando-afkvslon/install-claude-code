#!/bin/bash
# Rippling MDM Script: Install Claude Code CLI
# Minimal install — native binary only

LOGGED_IN_USER=$(stat -f%Su /dev/console)
USER_HOME=$(eval echo ~$LOGGED_IN_USER)

echo "Installing Claude Code for $LOGGED_IN_USER..."

# Remove old npm binary if it exists
rm -f /usr/local/bin/claude 2>/dev/null

# Create ~/.claude directories for OAuth sign-in
mkdir -p "$USER_HOME/.claude/debug" "$USER_HOME/.claude/config"
chown -R "$LOGGED_IN_USER" "$USER_HOME/.claude"

# Install Claude Code native binary
sudo -u "$LOGGED_IN_USER" bash -c 'curl -fsSL https://claude.ai/install.sh | bash' 2>&1

# Add ~/.local/bin to PATH if not already there
ZSHRC="$USER_HOME/.zshrc"
if ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
  sudo -u "$LOGGED_IN_USER" bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \"$ZSHRC\""
fi

echo "Done. Open a new Terminal and run: claude"
