#!/bin/bash
# Rippling MDM Script: Install Claude Code CLI
# Deploy to select Macs via Rippling MDM
# Installs Node.js (if needed) and Claude Code for the logged-in user

set -e

LOGGED_IN_USER=$(stat -f%Su /dev/console)
USER_HOME=$(eval echo ~$LOGGED_IN_USER)

echo "Installing Claude Code for user: $LOGGED_IN_USER"

# Check if Node.js is installed (need v18+)
NODE_BIN=""
if [ -x "/usr/local/bin/node" ]; then
  NODE_BIN="/usr/local/bin/node"
elif [ -x "/opt/homebrew/bin/node" ]; then
  NODE_BIN="/opt/homebrew/bin/node"
elif sudo -u "$LOGGED_IN_USER" bash -c 'command -v node' &>/dev/null; then
  NODE_BIN=$(sudo -u "$LOGGED_IN_USER" bash -c 'command -v node')
fi

INSTALL_NODE=0
if [ -z "$NODE_BIN" ]; then
  echo "Node.js not found. Installing..."
  INSTALL_NODE=1
else
  NODE_VERSION=$("$NODE_BIN" -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_VERSION" -lt 18 ] 2>/dev/null; then
    echo "Node.js version too old (v$NODE_VERSION). Installing latest LTS..."
    INSTALL_NODE=1
  else
    echo "Node.js found: $("$NODE_BIN" -v)"
  fi
fi

if [ "$INSTALL_NODE" -eq 1 ]; then
  # Install Node.js LTS via official macOS pkg installer
  NODE_PKG="/tmp/node-lts.pkg"
  ARCH=$(uname -m)
  if [ "$ARCH" = "arm64" ]; then
    NODE_URL="https://nodejs.org/dist/v22.14.0/node-v22.14.0.pkg"
  else
    NODE_URL="https://nodejs.org/dist/v22.14.0/node-v22.14.0.pkg"
  fi

  echo "Downloading Node.js LTS..."
  curl -fsSL -o "$NODE_PKG" "$NODE_URL"
  if [ ! -s "$NODE_PKG" ]; then
    echo "Error: Failed to download Node.js installer"
    exit 1
  fi

  echo "Installing Node.js..."
  installer -pkg "$NODE_PKG" -target /
  rm -f "$NODE_PKG"

  NODE_BIN="/usr/local/bin/node"
  if [ ! -x "$NODE_BIN" ]; then
    echo "Error: Node.js installation failed"
    exit 1
  fi
  echo "Node.js installed: $("$NODE_BIN" -v)"
fi

# Find npm matching the node installation
NPM_BIN=""
NPM_DIR=$(dirname "$NODE_BIN")
if [ -x "$NPM_DIR/npm" ]; then
  NPM_BIN="$NPM_DIR/npm"
elif [ -x "/usr/local/bin/npm" ]; then
  NPM_BIN="/usr/local/bin/npm"
elif [ -x "/opt/homebrew/bin/npm" ]; then
  NPM_BIN="/opt/homebrew/bin/npm"
fi

if [ -z "$NPM_BIN" ]; then
  echo "Error: npm not found"
  exit 1
fi
echo "Using npm: $NPM_BIN"

# Install Claude Code globally
echo "Installing Claude Code..."
"$NPM_BIN" install -g @anthropic-ai/claude-code 2>&1

# Verify installation
CLAUDE_BIN=""
if [ -x "$NPM_DIR/claude" ]; then
  CLAUDE_BIN="$NPM_DIR/claude"
elif [ -x "/usr/local/bin/claude" ]; then
  CLAUDE_BIN="/usr/local/bin/claude"
fi

if [ -z "$CLAUDE_BIN" ]; then
  echo "Error: Claude Code installation failed - binary not found"
  exit 1
fi

echo "Claude Code installed successfully: $("$CLAUDE_BIN" --version 2>/dev/null || echo 'installed')"
echo "Binary location: $CLAUDE_BIN"
echo "Done - Claude Code is ready for $LOGGED_IN_USER"
