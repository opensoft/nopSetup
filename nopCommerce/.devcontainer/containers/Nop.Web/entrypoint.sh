# #!/bin/bash


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
# run the setupContainerShell script in scripts directory
SCRIPT_DIR=$(dirname "$0")/scripts    # Get the directory of the entrypoint script
SETUP_SCRIPT="$SCRIPT_DIR/setupContainerShell.sh" # Path relative to entrypoint script

if [ -f "$SETUP_SCRIPT" ]; then
    echo "Attempting to run setupContainerShell script: $SETUP_SCRIPT"
    chmod +x "$SETUP_SCRIPT"
    echo "Executing $SETUP_SCRIPT ..."
    # Execute setupContainerShell.sh and check its exit code explicitly
    "$SETUP_SCRIPT"
    EXIT_CODE=$? # Capture the exit code immediately after execution

    if [ $EXIT_CODE -eq 0 ]; then
        echo "setupContainerShell script ($SETUP_SCRIPT) completed successfully."
        echo "Container is running, development tools ready..."
    else
        echo "-----------------------------------------------------"
        echo "ERROR: setupContainerShell script ($SETUP_SCRIPT) failed with exit code $EXIT_CODE."
        echo "Check the script's output above for potential errors."
        echo "-----------------------------------------------------"
        # Decide if the container should stop if setup fails.
        # For now, we'll let it continue to allow debugging.
        # exit $EXIT_CODE # Uncomment this line to make the container exit on setup failure
    fi
else
    echo "setupContainerShell script not found at '$SETUP_SCRIPT', skipping..."
fi
# keep the container running
echo "You can use the \"clone\" command from any nopCommerce directory to clone plugins."
echo "Keeping container alive..." # Added message
tail -f /dev/null
