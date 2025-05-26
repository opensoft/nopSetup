@echo off
setlocal enabledelayedexpansion

REM Check for help option first
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

REM Enable verbose mode if --verbose or -v is passed
set VERBOSE=false
if "%~1"=="--verbose" (
    set VERBOSE=true
    shift
)
if "%~1"=="-v" (
    set VERBOSE=true
    shift
)

REM Function to log messages in verbose mode
if "%VERBOSE%"=="true" echo [DEBUG] Starting clone script

REM Check if a repository name argument is provided
if "%~1"=="" (
    echo Usage: clone [--verbose ^| -v] [--remove ^| -rm] [--site ^| -s] ^<repo-name^>
    echo Use 'clone -h' or 'clone --help' for more information.
    exit /b 1
)

REM Variables
set ACTION=%~1
set REPO_NAME=%~2
if not "%ACTION%"=="--remove" (
    if not "%ACTION%"=="-rm" (
        set REPO_NAME=%~1
    )
)
set REPO_SLUG=Nop.Plugin.Opensoft.%REPO_NAME%
set DEVOPS_PROJECT=FarHeapSolutions@vs-ssh.visualstudio.com:v3/FarHeapSolutions/Nop%%20Plugins

REM Get current directory
set CURRENT_DIR=%CD%
if "%VERBOSE%"=="true" echo [DEBUG] Current directory: %CURRENT_DIR%

REM Search for solution files
set SOLUTION_COUNT=0
set SOLUTION_LIST=
set CHOSEN_SOLUTION=

REM Search up the directory tree
set SEARCH_DIR=%CD%
:search_up_loop
if "%VERBOSE%"=="true" echo [DEBUG] Searching up in: %SEARCH_DIR%

REM Check for .sln files in current search directory
for %%f in ("%SEARCH_DIR%\*.sln") do (
    if exist "%%f" (
        set /a SOLUTION_COUNT+=1
        set SOLUTION_LIST=!SOLUTION_LIST!"%%f"
        if "%VERBOSE%"=="true" echo [DEBUG] Found solution: %%f
    )
)

REM Check if we've reached nopSetup or workspace folder
for %%d in ("%SEARCH_DIR%") do set DIR_NAME=%%~nd
if /i "%DIR_NAME%"=="nopSetup" goto end_search_up
if /i "%DIR_NAME%"=="workspace" goto end_search_up

REM Move up one directory
for %%d in ("%SEARCH_DIR%") do set PARENT_DIR=%%~dpd
set PARENT_DIR=%PARENT_DIR:~0,-1%
if "%SEARCH_DIR%"=="%PARENT_DIR%" goto end_search_up
set SEARCH_DIR=%PARENT_DIR%
goto search_up_loop

:end_search_up
REM If no solutions found going up, search down 3 levels
if %SOLUTION_COUNT%==0 (
    if "%VERBOSE%"=="true" echo [DEBUG] No solutions found going up, searching down 3 levels
    call :search_down "%CURRENT_DIR%" 0
)

REM Handle solution selection - simplified version
if %SOLUTION_COUNT%==0 (
    echo No solution file found
    exit /b 1
)

if %SOLUTION_COUNT%==1 (
    for %%s in (%SOLUTION_LIST%) do set CHOSEN_SOLUTION=%%~s
    if "%VERBOSE%"=="true" echo [DEBUG] Using single solution: !CHOSEN_SOLUTION!
    goto solution_selected
)

REM Multiple solutions - show enhanced selection menu
echo.
echo Multiple solution files found:
echo ================================
call :display_solution_choices
echo.
set /p CHOICE=Please choose a solution file (1-%SOLUTION_COUNT%):
call :validate_and_set_choice

:solution_selected
if "%CHOSEN_SOLUTION%"=="" (
    echo Invalid selection
    exit /b 1
)

REM Get solution directory
for %%f in ("%CHOSEN_SOLUTION%") do set SOLUTION_DIR=%%~dpf
set SOLUTION_DIR=%SOLUTION_DIR:~0,-1%
if "%VERBOSE%"=="true" echo [DEBUG] Solution directory: %SOLUTION_DIR%

REM Check if Plugins folder exists
if not exist "%SOLUTION_DIR%\Plugins" (
    echo Error: Plugins folder not found at %SOLUTION_DIR%\Plugins
    exit /b 1
)

set PLUGINS_DIR=%SOLUTION_DIR%\Plugins
set CLONE_DIR=%PLUGINS_DIR%\%REPO_SLUG%
if "%VERBOSE%"=="true" echo [DEBUG] Clone directory: %CLONE_DIR%

REM Handle removal
if "%ACTION%"=="--remove" goto remove_repo
if "%ACTION%"=="-rm" goto remove_repo

REM Clone the repository
echo Cloning repository '%REPO_SLUG%'...
git clone "%DEVOPS_PROJECT%/%REPO_SLUG%" "%CLONE_DIR%"
if %errorlevel% neq 0 (
    echo Error: Failed to clone repository '%REPO_SLUG%'
    exit /b 1
)

echo Repository '%REPO_SLUG%' cloned successfully.

REM Change to the cloned directory and switch branch
cd /d "%CLONE_DIR%"
git checkout 4.80/develop
if %errorlevel% neq 0 (
    echo Error: Failed to switch to branch '4.80/develop'
    cd /d "%CURRENT_DIR%"
    exit /b 1
)

REM Add project to solution
cd /d "%SOLUTION_DIR%"
dotnet sln "%CHOSEN_SOLUTION%" add "Plugins\%REPO_SLUG%\%REPO_SLUG%.csproj"
if %errorlevel% neq 0 (
    echo Error: Failed to add project to solution
) else (
    echo Project '%REPO_SLUG%' added to solution successfully.
)

cd /d "%CURRENT_DIR%"
echo Script completed successfully.
exit /b 0

:remove_repo
echo Removing repository '%REPO_SLUG%'...

if exist "%CLONE_DIR%" (
    rmdir /s /q "%CLONE_DIR%"
    echo Folder '%CLONE_DIR%' removed successfully.
) else (
    echo Folder '%CLONE_DIR%' does not exist.
)

REM Remove from solution
cd /d "%SOLUTION_DIR%"
dotnet sln "%CHOSEN_SOLUTION%" remove "Plugins\%REPO_SLUG%\%REPO_SLUG%.csproj" 2>nul
echo Project '%REPO_SLUG%' removed from solution.

cd /d "%CURRENT_DIR%"
echo Repository '%REPO_SLUG%' removed successfully.
exit /b 0

:show_help
echo.
echo Clone Script - NopCommerce Plugin Management
echo ============================================
echo.
echo USAGE:
echo   clone [OPTIONS] ^<repo-name^>
echo.
echo OPTIONS:
echo   -h, --help              Show this help message
echo   -v, --verbose           Enable verbose output for debugging
echo   -rm, --remove           Remove a repository instead of cloning
echo.
echo EXAMPLES:
echo   clone SEO               Clone the SEO plugin repository
echo   clone -v PayPal         Clone PayPal plugin with verbose output
echo   clone -rm SEO           Remove the SEO plugin repository
echo.
exit /b 0

REM Function to search down directories
:search_down
set SEARCH_PATH=%~1
set DEPTH=%~2
if %DEPTH% geq 3 goto :eof

if "%VERBOSE%"=="true" echo [DEBUG] Searching down in: %SEARCH_PATH% (depth %DEPTH%)

REM Check for .sln files in current directory
for %%f in ("%SEARCH_PATH%\*.sln") do (
    if exist "%%f" (
        set /a SOLUTION_COUNT+=1
        set SOLUTION_LIST=!SOLUTION_LIST!"%%f"
        if "%VERBOSE%"=="true" echo [DEBUG] Found solution: %%f
    )
)

REM Search subdirectories
set /a NEXT_DEPTH=%DEPTH%+1
for /d %%d in ("%SEARCH_PATH%\*") do (
    call :search_down "%%d" %NEXT_DEPTH%
)
goto :eof

REM Function to display solution choices with highlighted differences
:display_solution_choices
setlocal enabledelayedexpansion

REM Find common base path
call :find_common_base_path

REM Display solutions with highlighting
set INDEX=1
for %%s in (%SOLUTION_LIST%) do (
    call :display_solution_option "%%~s" !INDEX!
    set /a INDEX+=1
)
goto :eof

REM Function to find common base path among all solutions
:find_common_base_path
setlocal enabledelayedexpansion
set COMMON_BASE=
set FIRST_SOLUTION=

REM Get first solution as reference
for %%s in (%SOLUTION_LIST%) do (
    if "!FIRST_SOLUTION!"=="" set FIRST_SOLUTION=%%~s
)

REM Extract directory of first solution
for %%f in ("!FIRST_SOLUTION!") do set FIRST_DIR=%%~dpf

REM Find common path by comparing with other solutions
set TEMP_COMMON=!FIRST_DIR!
for %%s in (%SOLUTION_LIST%) do (
    for %%f in ("%%~s") do (
        call :get_common_path "!TEMP_COMMON!" "%%~dpf"
    )
)

set COMMON_BASE=!TEMP_COMMON!
endlocal & set COMMON_BASE=%COMMON_BASE%
goto :eof

REM Function to get common path between two paths
:get_common_path
setlocal enabledelayedexpansion
set PATH1=%~1
set PATH2=%~2
set COMMON=

REM Simple approach - find common drive and root parts
for /f "tokens=1 delims=\" %%a in ("!PATH1!") do set DRIVE1=%%a
for /f "tokens=1 delims=\" %%a in ("!PATH2!") do set DRIVE2=%%a

if /i "!DRIVE1!"=="!DRIVE2!" (
    set COMMON=!DRIVE1!\
) else (
    set COMMON=
)

endlocal & set TEMP_COMMON=%COMMON%
goto :eof

REM Function to display a single solution option with highlighting
:display_solution_option
setlocal enabledelayedexpansion
set SOLUTION_PATH=%~1
set OPTION_INDEX=%~2

REM Get relative path from common base
set REL_PATH=!SOLUTION_PATH!
if defined COMMON_BASE (
    set REL_PATH=!SOLUTION_PATH:%COMMON_BASE%=!
)

REM Extract filename and directory
for %%f in ("!SOLUTION_PATH!") do (
    set FILENAME=%%~nxf
    set DIRNAME=%%~dpf
)

REM Display with enhanced formatting
if "!REL_PATH!"=="!SOLUTION_PATH!" (
    echo   %OPTION_INDEX%. !FILENAME!
    echo      ^> !SOLUTION_PATH!
) else (
    echo   %OPTION_INDEX%. !FILENAME!
    echo      ^> ...!REL_PATH!
)

goto :eof

REM Function to validate choice and set chosen solution
:validate_and_set_choice
setlocal enabledelayedexpansion

REM Validate input is a number
echo !CHOICE! | findstr /r "^[0-9][0-9]*$" >nul
if %errorlevel% neq 0 (
    echo Invalid input. Please enter a number.
    exit /b 1
)

REM Validate range
if !CHOICE! lss 1 (
    echo Invalid choice. Please enter a number between 1 and %SOLUTION_COUNT%.
    exit /b 1
)
if !CHOICE! gtr %SOLUTION_COUNT% (
    echo Invalid choice. Please enter a number between 1 and %SOLUTION_COUNT%.
    exit /b 1
)

REM Set chosen solution
set INDEX=1
for %%s in (%SOLUTION_LIST%) do (
    if !INDEX!==!CHOICE! (
        endlocal & set CHOSEN_SOLUTION=%%~s
        goto :eof
    )
    set /a INDEX+=1
)

endlocal
goto :eof
