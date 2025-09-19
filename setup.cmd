: '
@echo off
REM Windows / cmd section
REM Use full path to scripts directory relative to this file
call "%~dp0scripts\setupHost.bat" %*
set EXITCODE=%ERRORLEVEL%
exit /b %EXITCODE%
'
#!/usr/bin/env bash
set -euo pipefail
# Linux / macOS section
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
echo "Running Linux commands..."
"${SCRIPT_DIR}/scripts/setupHost.sh" "$@"
