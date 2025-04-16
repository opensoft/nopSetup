#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create ~/.local/bin directory if it doesn't exist
mkdir -p ~/.local/bin

# Create symbolic link for the clone script
ln -sf "$SCRIPT_DIR/clone" ~/.local/bin/clone

# Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
    echo "Added ~/.local/bin to PATH for this session."
    
    # Add to shell profile if it doesn't already include it
    SHELL_PROFILE=""
    if [[ -f ~/.bashrc ]]; then
        SHELL_PROFILE=~/.bashrc
    elif [[ -f ~/.zshrc ]]; then
        SHELL_PROFILE=~/.zshrc
    fi
    
    if [[ -n "$SHELL_PROFILE" ]] && ! grep -q "PATH=\"\$HOME/.local/bin:\$PATH\"" "$SHELL_PROFILE"; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_PROFILE"
        echo "Added ~/.local/bin to PATH permanently in $SHELL_PROFILE"
    fi
fi

echo "cloning nopCommerce..."
git clone git@github.com:opensoft/nopCommerce.git
git checkout develop
echo "NopCommerce cloned successfully."

echo "cloning nopPlugins..."
git clone git@github.com:opensoft/nopPlugins.git
git checkout develop
echo "NopPlugins cloned successfully."

echo "nopCommerce development tools are now available."
echo "You can use the \"clone\" command from any nopCommerce directory to clone plugins."
