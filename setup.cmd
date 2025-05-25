#!/bin/sh
# The next line works in both environments \
if [ -n "$WINDIR" ]; then \
  # Windows commands
  @echo off & \
  echo Running Windows commands... & \
  scripts\setupHost.bat & \
  exit /b %ERRORLEVEL%; \
exit $?; fi

# Linux commands
echo "Running Linux commands..."
./scripts/setupHost.sh
exit $?
