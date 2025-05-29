#!/bin/bash
# This is a dual-purpose script that works on both Windows and Linux
@echo off & goto :batch 2>nul || bash "$0" "$@" && exit $?

:batch
echo Running Windows commands...
cmd /c scripts\setupHost.bat
exit /b %ERRORLEVEL%

# Linux/bash section starts here
echo "Running Linux commands..."
chmod +x scripts/setupHost.sh
./scripts/setupHost.sh
exit $?
