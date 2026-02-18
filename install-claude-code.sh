#!/bin/bash
# Rippling MDM Script: Install Claude Code CLI
# Deploy to select Macs via Rippling MDM
# Uses the native installer (no Node.js dependency, auto-updates)

set -e

LOGGED_IN_USER=$(stat -f%Su /dev/console)
USER_HOME=$(eval echo ~$LOGGED_IN_USER)

echo "Installing Claude Code for user: $LOGGED_IN_USER"

# Install Xcode Command Line Tools if not present (Claude Code needs git)
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools (needed for git)..."
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  CLT_PKG=$(softwareupdate -l 2>/dev/null | grep -o ".*Command Line Tools.*" | head -1 | sed 's/^[* ]*//')
  if [ -n "$CLT_PKG" ]; then
    softwareupdate -i "$CLT_PKG" --agree-to-license 2>&1
    echo "Xcode Command Line Tools installed"
  else
    echo "Warning: Could not find Command Line Tools package - git may prompt user to install"
  fi
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi

# Remove old npm-based claude binary so it doesn't shadow the native one
if [ -x "/usr/local/bin/claude" ]; then
  echo "Removing old npm-based Claude Code binary..."
  rm -f /usr/local/bin/claude
  npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
fi

# Create ~/.claude directories needed for OAuth sign-in
# Script runs as root so mkdir always succeeds, then chown hands it to the user
mkdir -p "$USER_HOME/.claude/debug" "$USER_HOME/.claude/config"
chown -R "$LOGGED_IN_USER" "$USER_HOME/.claude"

# Install Claude Code via native installer as the logged-in user
# Installs to ~/.local/bin/claude — no Node.js required
echo "Installing Claude Code via native installer..."
sudo -u "$LOGGED_IN_USER" bash -c 'curl -fsSL https://claude.ai/install.sh | bash -s -- -y' 2>&1

# Verify installation
CLAUDE_BIN="$USER_HOME/.local/bin/claude"
if [ ! -x "$CLAUDE_BIN" ]; then
  echo "Error: Claude Code installation failed - binary not found at $CLAUDE_BIN"
  exit 1
fi

# Ensure ~/.local/bin is in user's PATH (in case native installer didn't add it)
ZSHRC="$USER_HOME/.zshrc"
if [ ! -f "$ZSHRC" ] || ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
  sudo -u "$LOGGED_IN_USER" bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \"$ZSHRC\""
  echo "Added ~/.local/bin to PATH in .zshrc"
fi

echo "Claude Code installed successfully: $("$CLAUDE_BIN" --version 2>/dev/null || echo 'installed')"
echo "Binary location: $CLAUDE_BIN"
echo "Done - Claude Code is ready for $LOGGED_IN_USER"
