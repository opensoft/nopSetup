#!/bin/bash
# Multi-platform setup script

# Better Windows detection - check if we're actually in a Windows cmd environment
# In WSL, cmd.exe exists but we want to run the Linux version
if [[ "${OS:-}" == "Windows_NT" ]] && [[ ! -f "/proc/version" ]]; then
    # True Windows environment
    echo "Detected Windows environment"
    # Use the original Windows batch logic here if needed
    cmd.exe /c "call \"%~dp0scripts\\setupHost.bat\" %*"
    exit $?
fi

# Check if we're running in bash, if not, re-execute with bash
if [ -z "${BASH_VERSION:-}" ]; then
    echo "Re-executing with bash..."
    exec bash "$0" "$@"
fi

# Linux/macOS section - now guaranteed to be in bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
echo "Running Linux commands..."
"${SCRIPT_DIR}/scripts/setupHost.sh" "$@"
