!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(dirname "$0")"
# Use absolute path for SCRIPT_DIR for robustness
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"

echo "--- Starting Container Shell Setup ---"
echo "Script directory: $SCRIPT_DIR"

# --- Run additional setup scripts ---

# Run addClone2Shell script
ADD_CLONE_SCRIPT="$SCRIPT_DIR/addClone2Shell.sh"
if [ -f "$ADD_CLONE_SCRIPT" ]; then
    echo "Running additional setup script: $ADD_CLONE_SCRIPT"
    bash "$ADD_CLONE_SCRIPT" # Fixed stray backtick here
    if [ $? -ne 0 ]; then
        echo "Warning: $ADD_CLONE_SCRIPT finished with errors."
    else
        echo "$ADD_CLONE_SCRIPT completed successfully."
    fi
else
    echo "Warning: Additional setup script not found: $ADD_CLONE_SCRIPT"
fi
# Note: The following message might be inaccurate depending on addClone2Shell.sh logic
# echo " - The 'clone' command symlink created in ~/.local/bin/"
echo "-----------------------------------------------------"
echo "Setup finished."
echo "-----------------------------------------------------"
