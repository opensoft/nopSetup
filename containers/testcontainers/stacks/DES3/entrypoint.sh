#!/bin/bash

# Add .devcontainer to PATH
export PATH="/workspace/.devcontainer:$PATH"

# keep the container running
echo "Container is running, development tools ready..."
echo "You can use the \"clone\" command from any nopCommerce directory to clone plugins."
tail -f /dev/null
