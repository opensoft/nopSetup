#!/bin/sh
@echo off
:: This section runs on Linux (shell) or Windows (batch)

if "%OS%"=="Windows_NT" goto WINDOWS
if [ -n "$SHELL" ]; then goto LINUX
exit

:WINDOWS
echo Running Windows commands...
setupHost.bat
exit /b

:LINUX
echo Running Linux commands...
./setupHost.sh
exit
