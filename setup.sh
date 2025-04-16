#!/bin/bash

NOPCOMMERCE_BINARIES_URL=""
# Check OS type
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Running on Linux"
    # Put Linux-specific commands here
    NOPCOMMERCE_BINARIES_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_NoSource_linux_x64.zip"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS"
    # Put macOS-specific commands here
    NOPCOMMERCE_BINARIES_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_NoSource_mac_x64.zip"
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "Running on Windows (using Cygwin/MSYS/Git Bash)"
    # Put Windows-specific commands here (using Bash syntax)
    NOPCOMMERCE_BINARIES_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_NoSource_win_x64.zip"
else
    echo "Running on an unknown OS ($OSTYPE)"
fi


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

# --- nopCommerce Repository Setup ---
echo "Cloning nopCommerce repository..."
git clone git@github.com:opensoft/nopCommerce.git nopCommerce
cd nopCommerce || exit 1 # Change into the directory or exit if failed
git checkout develop
cd .. # Go back to the parent directory
echo "NopCommerce repository cloned successfully."


# --- nopSolution Source Download and Setup ---
# This is the full source of the nopSolution framework (specific version)
# This is NOT a repo. Use this for reference or plugin development alongside the repos.
echo "Downloading nopCommerce source zip (v4.80.5)..."
curl -L -o nopCommerce_4.80.5_Source.zip https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_Source.zip
echo "nopCommerce source zip downloaded."

# Create the nopSolution directory and unzip the source code into it
echo "Creating nopSolution directory and unzipping source..."
mkdir -p nopSolution
unzip -q nopCommerce_4.80.5_Source.zip -d nopSolution
echo "nopCommerce source unzipped into nopSolution directory."

# Remove files at the root of nopSolution, keep subdirectories
echo "Cleaning up root files in nopSolution..."
find nopSolution/ -maxdepth 1 -type f -delete
echo "Removed files at the root of nopSolution, if any."

# Remove files at the root of nopSolution/src, keep subdirectories
echo "Cleaning up root files in nopSolution/src..."
find nopSolution/src/ -maxdepth 1 -type f -delete
echo "Removed files at the root of nopSolution/src, if any."

# Clean up the downloaded zip file
echo "Removing downloaded zip file..."
rm nopCommerce_4.80.5_Source.zip
echo "Zip file removed."
echo "nopSolution source setup complete."
echo "-----------------------------------------------------" # Added separator

# --- nopPlugins Source Download and Setup ---
# This is the full source of the nopPlugins framework (specific version)
# This is NOT a repo. Use this for reference alongside the repos.
# !!! UPDATE THE URL AND VERSION (X.Y.Z) BELOW !!!
#PLUGIN_VERSION="X.Y.Z" # Replace with actual version
echo "Downloading nopCommerce Binaries zip"

# Create the nopPlugins_Source directory and unzip the source code into it
echo "Creating nopPlugins_Source directory and unzipping source..."
mkdir -p nopPlugins
curl -L -o "nopCommerce_4.80.5_binaries.zip" "${NOPCOMMERCE_BINARIES_URL}"
if [ $? -ne 0 ]; then
    echo "Error downloading nopCommerce binaries zip. Please check the URL and version."
    # Decide if you want to exit or continue:
    # exit 1 
else 
    echo "nopCommerce binaries zip downloaded successfully."
fi   
unzip -q "nopCommerce_4.80.5_binaries.zip" -d nopPlugins_Source
echo "nopPlugins source unzipped into nopPlugins_Source directory."

# Remove files at the root of nopPlugins_Source, keep subdirectories
echo "Cleaning up root files in nopPlugins_Source..."
find nopPlugins_Source/ -maxdepth 1 -type f -delete
echo "Removed files at the root of nopPlugins_Source, if any."

# Remove files at the root of nopPlugins_Source/src, keep subdirectories (if applicable)
if [ -d "nopPlugins_Source/src" ]; then
    echo "Cleaning up root files in nopPlugins_Source/src..."
    find nopPlugins_Source/src/ -maxdepth 1 -type f -delete
    echo "Removed files at the root of nopPlugins_Source/src, if any."
fi

# Clean up the downloaded zip file
echo "Removing downloaded Binaries zip file..."
rm "nopCommerce_4.80.5_binaries.zip"
echo "Binaries zip file removed."
echo "-----------------------------------------------------" # Added separator




# --- Final Messages ---
echo ""
echo "-----------------------------------------------------"
echo "nopCommerce development environment setup complete!"
echo " - nopCommerce repository cloned into 'nopCommerce/'"
echo " - nopPlugins repository cloned into 'nopPlugins/'"
echo " - nopCommerce v4.80.5 source extracted into 'nopSolution/' (cleaned)"
echo " - The 'clone' command is available for managing plugins."
echo "-----------------------------------------------------"