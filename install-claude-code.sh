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

# --- Configure user's shell ---
ZSHRC="$USER_HOME/.zshrc"

# Add ~/.local/bin to PATH
if ! grep -q '\.local/bin' "$ZSHRC" 2>/dev/null; then
  sudo -u "$LOGGED_IN_USER" bash -c "echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> \"$ZSHRC\""
fi

# Prevent the terminal setup prompt from appearing.
# Claude Code v2.1.45 has a bug where this prompt freezes in Terminal.app.
# TERM_PROGRAM is only used for terminal identification, not rendering.
# Rendering uses TERM (xterm-256color) which stays untouched.
# Remove this alias once Anthropic fixes the freeze bug in a future version.
if ! grep -q 'alias claude=' "$ZSHRC" 2>/dev/null; then
  sudo -u "$LOGGED_IN_USER" bash -c "echo 'alias claude=\"TERM_PROGRAM=xterm-256color claude\"' >> \"$ZSHRC\""
fi

# --- Configure Terminal.app settings (Option+Enter, visual bell) ---
# Even though the alias skips the prompt, we still configure Terminal.app
# so users actually get the correct keyboard behavior
TERM_PLIST="$USER_HOME/Library/Preferences/com.apple.Terminal.plist"
if [ -f "$TERM_PLIST" ]; then
  DEFAULT_PROFILE=$(sudo -u "$LOGGED_IN_USER" defaults read com.apple.Terminal "Default Window Settings" 2>/dev/null || echo "Basic")
  STARTUP_PROFILE=$(sudo -u "$LOGGED_IN_USER" defaults read com.apple.Terminal "Startup Window Settings" 2>/dev/null || echo "Basic")

  for PROFILE in "$DEFAULT_PROFILE" "$STARTUP_PROFILE"; do
    /usr/libexec/PlistBuddy -c "Add ':Window Settings:${PROFILE}:useOptionAsMetaKey' bool true" "$TERM_PLIST" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Set ':Window Settings:${PROFILE}:useOptionAsMetaKey' true" "$TERM_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add ':Window Settings:${PROFILE}:Bell' bool false" "$TERM_PLIST" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Set ':Window Settings:${PROFILE}:Bell' false" "$TERM_PLIST" 2>/dev/null || true
  done

  killall cfprefsd 2>/dev/null || true
  echo "Terminal.app configured (profile: $DEFAULT_PROFILE)"
fi

echo "Done. Quit Terminal (Cmd+Q), reopen, and run: claude"
