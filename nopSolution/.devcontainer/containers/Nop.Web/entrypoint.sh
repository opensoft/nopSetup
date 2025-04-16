# #!/bin/bash

# # Add scripts to PATH
# export PATH="/workspace/.devcontainer/scripts:$PATH"


# export NODE_ENV=development
# export DATABASE_URL="mssql://nopcommerce_user:nopcommerce_password@nopcommerce_database/nopcommerce_db"
# export APP_NAME="nopCommerce"

# # keep the container running
# echo "Container is running, development tools ready..."
# echo "You can use the \"clone\" command from any nopCommerce directory to clone plugins."
# tail -f /dev/null



#!/bin/bash
set -e

# # Check if running inside a VS Code Dev Container
# if [ -z "${VSCODE_DEVCONTAINERS_SESSION}" ]; then
#   # Not running in Dev Container, just keep the container alive
#   echo "Not running in VS Code Dev Container. Sleeping indefinitely..."
#   exec sleep infinity
# else
#   # Running in Dev Container, execute the intended logic
#   echo "Running in VS Code Dev Container. Executing entrypoint logic..."
  
# This script is executed when the container starts.
export NODE_ENV=development
export DATABASE_URL="mssql://nopcommerce_user:nopcommerce_password@nopcommerce_database/nopcommerce_db"
export APP_NAME="nopCommerce"

# setup the container shell environment
# run the setup script in scripts directory
SCRIPT_DIR=$(dirname "$0") # Get the directory of the entrypoint script
SETUP_SCRIPT="$SCRIPT_DIR/scripts/setup.sh" # Path relative to entrypoint script

if [ -f "$SETUP_SCRIPT" ]; then
    echo "Attempting to run setup script: $SETUP_SCRIPT"
    chmod +x "$SETUP_SCRIPT"
    echo "Executing $SETUP_SCRIPT ..."
    # Execute setup.sh and check its exit code explicitly
    "$SETUP_SCRIPT"
    EXIT_CODE=$? # Capture the exit code immediately after execution

    if [ $EXIT_CODE -eq 0 ]; then
        echo "Setup script ($SETUP_SCRIPT) completed successfully."
        echo "Container is running, development tools ready..."
    else
        echo "-----------------------------------------------------"
        echo "ERROR: Setup script ($SETUP_SCRIPT) failed with exit code $EXIT_CODE."
        echo "Check the script's output above for potential errors."
        echo "-----------------------------------------------------"
        # Decide if the container should stop if setup fails.
        # For now, we'll let it continue to allow debugging.
        # exit $EXIT_CODE # Uncomment this line to make the container exit on setup failure
    fi
else
    echo "Setup script not found at '$SETUP_SCRIPT', skipping..."
fi
# keep the container running
echo "You can use the \"clone\" command from any nopCommerce directory to clone plugins."
echo "Keeping container alive..." # Added message
tail -f /dev/null
