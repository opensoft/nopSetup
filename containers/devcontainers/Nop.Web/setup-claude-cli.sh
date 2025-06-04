#!/bin/bash

# Claude CLI Quick Setup Script for Existing Containers
# Usage: ./setup-claude-cli.sh [--user-only | --system-only]

set -e

INSTALL_USER=true
INSTALL_SYSTEM=true
SCRIPT_NAME=$(basename "$0")

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --user-only)
            INSTALL_SYSTEM=false
            shift
            ;;
        --system-only)
            INSTALL_USER=false
            shift
            ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME [--user-only | --system-only]"
            echo ""
            echo "Options:"
            echo "  --user-only    Install Claude CLI only for current user"
            echo "  --system-only  Install Claude CLI only system-wide (requires sudo)"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Default: Install for both system and user"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🚀 Claude CLI Quick Setup"
echo "========================="

# Check if Node.js and npm are available
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ Node.js $(node --version) found"
echo "✅ npm $(npm --version) found"
echo ""

# System installation
if [ "$INSTALL_SYSTEM" = true ]; then
    echo "📦 Installing Claude CLI system-wide..."

    if [ "$EUID" -eq 0 ]; then
        # Running as root
        npm install -g @anthropic-ai/claude-code

        # Create symlink for system access
        GLOBAL_ROOT=$(npm root -g)
        if [ -f "$GLOBAL_ROOT/@anthropic-ai/claude-code/bin/claude" ]; then
            ln -sf "$GLOBAL_ROOT/@anthropic-ai/claude-code/bin/claude" /usr/local/bin/claude
            echo "✅ System symlink created: /usr/local/bin/claude"
        fi
    else
        # Not running as root, try with sudo
        if command -v sudo >/dev/null 2>&1; then
            echo "🔐 Installing with sudo..."
            sudo npm install -g @anthropic-ai/claude-code

            # Create symlink
            GLOBAL_ROOT=$(sudo npm root -g)
            if [ -f "$GLOBAL_ROOT/@anthropic-ai/claude-code/bin/claude" ]; then
                sudo ln -sf "$GLOBAL_ROOT/@anthropic-ai/claude-code/bin/claude" /usr/local/bin/claude
                echo "✅ System symlink created: /usr/local/bin/claude"
            fi
        else
            echo "⚠️  Cannot install system-wide without sudo. Skipping system installation."
            INSTALL_SYSTEM=false
        fi
    fi
fi

# User installation
if [ "$INSTALL_USER" = true ]; then
    echo "👤 Installing Claude CLI for current user..."
    npm install -g @anthropic-ai/claude-code

    # Add to PATH in shell config if not already there
    USER_NPM_BIN="$(npm config get prefix)/bin"

    for SHELL_CONFIG in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$SHELL_CONFIG" ]; then
            if ! grep -q "$USER_NPM_BIN" "$SHELL_CONFIG"; then
                echo "" >> "$SHELL_CONFIG"
                echo "# Added by Claude CLI setup script" >> "$SHELL_CONFIG"
                echo "export PATH=\"\$PATH:$USER_NPM_BIN\"" >> "$SHELL_CONFIG"
                echo "✅ Updated PATH in $SHELL_CONFIG"
            else
                echo "ℹ️  PATH already configured in $SHELL_CONFIG"
            fi
        fi
    done
fi

echo ""
echo "🔍 Verifying installation..."

# Test installations
SYSTEM_OK=false
USER_OK=false

# Test system installation
if [ "$INSTALL_SYSTEM" = true ]; then
    if command -v claude >/dev/null 2>&1; then
        SYSTEM_VERSION=$(claude --version 2>/dev/null || echo "unknown")
        echo "✅ System Claude CLI: $SYSTEM_VERSION"
        SYSTEM_OK=true
    else
        echo "❌ System Claude CLI not found in PATH"
    fi
fi

# Test user installation
if [ "$INSTALL_USER" = true ]; then
    USER_NPM_BIN="$(npm config get prefix)/bin"
    if [ -f "$USER_NPM_BIN/claude" ]; then
        USER_VERSION=$("$USER_NPM_BIN/claude" --version 2>/dev/null || echo "unknown")
        echo "✅ User Claude CLI: $USER_VERSION"
        USER_OK=true
    else
        echo "❌ User Claude CLI not found"
    fi
fi

echo ""

# Final status
if ([ "$INSTALL_SYSTEM" = false ] || [ "$SYSTEM_OK" = true ]) && ([ "$INSTALL_USER" = false ] || [ "$USER_OK" = true ]); then
    echo "🎉 Claude CLI installation completed successfully!"
    echo ""
    echo "Usage:"
    echo "  claude --version    # Check version"
    echo "  claude --help       # Show help"
    echo ""
    echo "Note: You may need to restart your shell or run 'source ~/.bashrc' (or ~/.zshrc) to update your PATH."
else
    echo "⚠️  Installation completed with some issues."
    echo "You may need to manually add the npm bin directory to your PATH:"
    echo "  export PATH=\"\$PATH:$(npm config get prefix)/bin\""
    exit 1
fi

# Show current PATH for debugging
echo "Current PATH includes:"
echo "$PATH" | tr ':' '\n' | grep -E "(npm|node|local)" | head -5 || echo "  (no npm/node paths found)"

echo ""
echo "🔧 Troubleshooting:"
echo "If 'claude' command is not found, try:"
echo "  1. Restart your terminal/shell"
echo "  2. Run: source ~/.bashrc (or ~/.zshrc)"
echo "  3. Check: which claude"
echo "  4. Check: npm list -g @anthropic-ai/claude-code"
