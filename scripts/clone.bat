REM Clone Script for Windows - Manage NopCommerce plugin repositories with Pattern Learning
REM
REM This script uses a placeholder plugin (Nop.Plugin.Placeholder) to ensure
REM the Plugins folder definition is never removed from the solution file.

@echo off
setlocal enabledelayedexpansion

REM Pattern cache file location
set PATTERN_CACHE_FILE=%USERPROFILE%\.clone_pattern_cache

REM Known NopCommerce plugin patterns (ordered by likelihood)
set PATTERN_COUNT=12
set PATTERN_1=Nop.Plugin.Opensoft.{name}
set PATTERN_2=Nop.Plugin.Misc.{name}
set PATTERN_3=Nop.Plugin.{name}
set PATTERN_4=Nop.Plugin.Widgets.{name}
set PATTERN_5=Nop.Plugin.Payments.{name}
set PATTERN_6=Nop.Plugin.Shipping.{name}
set PATTERN_7=Nop.Plugin.Tax.{name}
set PATTERN_8=Nop.Plugin.ExternalAuth.{name}
set PATTERN_9=Nop.Plugin.DiscountRules.{name}
set PATTERN_10=Nop.Plugin.MultiFactorAuth.{name}
set PATTERN_11=Nop.Plugin.Pickup.{name}
set PATTERN_12=Nop.Plugin.Api.{name}

REM Check for help option first
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

REM Initialize variables
set VERBOSE=false
set REMOVE=false
set SITE_MODE=false
set DISCOVER_MODE=false
set LIST_PATTERNS=false
set CLEAR_CACHE=false
set MANUAL_PATTERN=
set FULL_NAME=
set REPO_NAME=
set SITE_NAME=
set REPO_SLUG=

REM Parse arguments with proper loop
set ARG_COUNT=0
for %%a in (%*) do set /a ARG_COUNT+=1

set /a CURRENT_ARG=1
:parse_args
if %CURRENT_ARG% gtr %ARG_COUNT% goto args_parsed

call set ARG=%%%CURRENT_ARG%

if "!ARG!"=="--verbose" (
    set VERBOSE=true
    goto next_arg
)
if "!ARG!"=="-v" (
    set VERBOSE=true
    goto next_arg
)
if "!ARG!"=="--remove" (
    set REMOVE=true
    goto next_arg
)
if "!ARG!"=="-rm" (
    set REMOVE=true
    goto next_arg
)
if "!ARG!"=="--site" (
    set SITE_MODE=true
    goto next_arg
)
if "!ARG!"=="-s" (
    set SITE_MODE=true
    goto next_arg
)
if "!ARG!"=="--discover" (
    set DISCOVER_MODE=true
    goto next_arg
)
if "!ARG!"=="--list-patterns" (
    set LIST_PATTERNS=true
    goto next_arg
)
if "!ARG!"=="--clear-cache" (
    set CLEAR_CACHE=true
    goto next_arg
)
if "!ARG!"=="--pattern" (
    set /a CURRENT_ARG+=1
    call set MANUAL_PATTERN=%%%CURRENT_ARG%
    goto next_arg
)
if "!ARG!"=="--full-name" (
    set /a CURRENT_ARG+=1
    call set FULL_NAME=%%%CURRENT_ARG%
    goto next_arg
)

REM If no flag, this should be the repo name or site name
if "!SITE_MODE!"=="true" (
    if not defined SITE_NAME set SITE_NAME=!ARG!
) else (
    if not defined REPO_NAME set REPO_NAME=!ARG!
)

:next_arg
set /a CURRENT_ARG+=1
goto parse_args

:args_parsed

REM Handle special modes first
if "%CLEAR_CACHE%"=="true" (
    if exist "%PATTERN_CACHE_FILE%" (
        del "%PATTERN_CACHE_FILE%"
        echo Pattern cache cleared successfully.
    ) else (
        echo Pattern cache is already empty.
    )
    exit /b 0
)

if "%LIST_PATTERNS%"=="true" (
    echo Known NopCommerce plugin patterns:
    for /l %%i in (1,1,%PATTERN_COUNT%) do (
        call echo   %%i. %%PATTERN_%%i%%
    )
    exit /b 0
)
if "%DISCOVER_MODE%"=="true" (
    if not defined REPO_NAME (
        echo Error: Discovery mode requires a plugin name.
        echo Usage: clone --discover ^<plugin-name^>
        exit /b 1
    )

    echo 🔍 Discovering available patterns for: %REPO_NAME%
    echo.

    set DEVOPS_PROJECT=git@ssh.dev.azure.com:v3/FarHeapSolutions/Nop%%20Plugins
    set FOUND_COUNT=0

    REM Get pattern hints and test all patterns
    call :get_pattern_hints %REPO_NAME%

    REM Test each pattern
    for /l %%i in (1,1,%PATTERN_COUNT%) do (
        call set CURRENT_PATTERN=%%PATTERN_%%i%%
        call set REPO_SLUG_TEST=!CURRENT_PATTERN:{name}=%REPO_NAME%!
        set REPO_URL_TEST=!DEVOPS_PROJECT!/!REPO_SLUG_TEST!

        echo|set /p="Testing: !REPO_SLUG_TEST! ... "
        call :check_repository_exists "!REPO_URL_TEST!"
        if !errorlevel! equ 0 (
            echo ✅ EXISTS
            set /a FOUND_COUNT+=1
            set FOUND_!FOUND_COUNT!=!REPO_SLUG_TEST!
        ) else (
            echo ❌ Not found
        )
    )

    echo.
    if !FOUND_COUNT! equ 0 (
        echo ❌ No matching repositories found.
        call :suggest_alternatives %REPO_NAME%
    ) else if !FOUND_COUNT! equ 1 (
        call echo ✅ Found one matching repository: !FOUND_1!
        echo To clone: clone %REPO_NAME%
    ) else (
        echo ✅ Found multiple matching repositories:
        for /l %%j in (1,1,!FOUND_COUNT!) do (
            call echo   - %%FOUND_%%j%%
        )
        echo.
        echo Multiple matches found. The first one will be used by default.
    )
    exit /b 0
)

REM Validate arguments
if "%SITE_MODE%"=="true" (
    if not defined SITE_NAME (
        echo Error: The --site or -s option must be followed by a site name.
        echo Usage: clone [--verbose ^| -v] [--remove ^| -rm] --site ^<site-name^>
        exit /b 1
    )
) else (
    if defined FULL_NAME (
        set REPO_SLUG=%FULL_NAME%
        REM Extract repo name from full name for display purposes
        for /f "tokens=* delims=." %%a in ("%FULL_NAME%") do set REPO_NAME=%%a
        for %%a in (%FULL_NAME%) do set REPO_NAME=%%~na
    ) else if defined MANUAL_PATTERN (
        if not defined REPO_NAME (
            echo Error: Manual pattern requires a plugin name.
            echo Usage: clone --pattern 'Nop.Plugin.Category.{name}' ^<plugin-name^>
            exit /b 1
        )
        set REPO_SLUG=!MANUAL_PATTERN:{name}=%REPO_NAME%!
    ) else if not defined REPO_NAME (
        echo Error: Repository name is required.
        echo Usage: clone [OPTIONS] ^<repo-name^>
        echo        clone [OPTIONS] --site ^<site-name^>
        echo        clone --remove [OPTIONS] ^<repo-name^>
        echo        clone --remove --site ^<site-name^>
        echo.
        echo Use 'clone --help' for more information.
        exit /b 1
    )
)
set DEVOPS_PROJECT=git@ssh.dev.azure.com:v3/FarHeapSolutions/Nop%%20Plugins

REM Get current directory
set CURRENT_DIR=%CD%
if "%VERBOSE%"=="true" echo [DEBUG] Current directory: %CURRENT_DIR%

REM Search for solution files - use array approach
set SOLUTION_COUNT=0
set CHOSEN_SOLUTION=

REM Search up the directory tree
set SEARCH_DIR=%CD%
:search_up_loop
if "%VERBOSE%"=="true" echo [DEBUG] Searching up in: %SEARCH_DIR%

REM Check for .sln files in current search directory
for %%f in ("%SEARCH_DIR%\*.sln") do (
    if exist "%%f" (
        set /a SOLUTION_COUNT+=1
        REM Normalize path to remove double slashes
        set "NORMALIZED_PATH=%%f"
        set "NORMALIZED_PATH=!NORMALIZED_PATH:\\=\!"
        set SOLUTION_!SOLUTION_COUNT!=!NORMALIZED_PATH!
        if "%VERBOSE%"=="true" echo [DEBUG] Found solution: !NORMALIZED_PATH!
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
    set CHOSEN_SOLUTION=!SOLUTION_1!
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
if "%VERBOSE%"=="true" echo [DEBUG] Plugins directory: %PLUGINS_DIR%

REM Handle operations based on parsed arguments
if "%SITE_MODE%"=="true" goto handle_site_mode

REM Handle single repository operations
if "%REMOVE%"=="true" (
    call :process_repository remove "%REPO_NAME%"
) else (
    call :process_repository clone "%REPO_NAME%"
)

cd /d "%CURRENT_DIR%"
echo Script completed successfully.
exit /b 0

:handle_site_mode
REM Determine workspace root more reliably
pushd "%~dp0"
cd ..
set WORKSPACE_ROOT=%CD%
popd

set PLUGIN_LIST_FILE=%WORKSPACE_ROOT%\sites\%SITE_NAME%\PluginList.txt

if "%VERBOSE%"=="true" echo [DEBUG] Looking for plugin list at: %PLUGIN_LIST_FILE%

if not exist "%PLUGIN_LIST_FILE%" (
    echo Error: PluginList.txt file not found at '%PLUGIN_LIST_FILE%'.
    echo.
    echo Expected structure:
    echo   %WORKSPACE_ROOT%\sites\%SITE_NAME%\PluginList.txt
    echo.
    echo Available sites:
    if exist "%WORKSPACE_ROOT%\sites" (
        for /d %%d in ("%WORKSPACE_ROOT%\sites\*") do echo   - %%~nd
    ) else (
        echo   No sites folder found at %WORKSPACE_ROOT%\sites
    )
    exit /b 1
)

if "%REMOVE%"=="true" (
    echo Removing repositories for site '%SITE_NAME%' listed in %PLUGIN_LIST_FILE%...
    set OPERATION_NAME=remove
) else (
    echo Cloning repositories for site '%SITE_NAME%' listed in %PLUGIN_LIST_FILE%...
    set OPERATION_NAME=clone
)

REM Count total repositories for progress tracking
set TOTAL_REPOS=0
for /f "usebackq eol=# delims=" %%i in ("%PLUGIN_LIST_FILE%") do (
    if not "%%i"=="" set /a TOTAL_REPOS+=1
)

set CURRENT_REPO=0
for /f "usebackq eol=# delims=" %%i in ("%PLUGIN_LIST_FILE%") do (
    if not "%%i"=="" (
        set /a CURRENT_REPO+=1
        echo [!CURRENT_REPO!/!TOTAL_REPOS!] Processing repository: %%i
        call :process_repository !OPERATION_NAME! "%%i"
    )
)

if "%REMOVE%"=="true" (
    echo All repositories for site '%SITE_NAME%' have been removed.
) else (
    echo All repositories for site '%SITE_NAME%' processed.
)
cd /d "%CURRENT_DIR%"
exit /b 0

:show_help
echo.
echo Clone Script - NopCommerce Plugin Management with Pattern Learning
echo ==================================================================
echo.
echo USAGE:
echo   clone [OPTIONS] ^<repo-name^>
echo   clone [OPTIONS] --site ^<site-name^>
echo   clone --remove [OPTIONS] ^<repo-name^>
echo   clone --remove --site ^<site-name^>
echo   clone --discover ^<repo-name^>
echo   clone --pattern ^<pattern^> ^<repo-name^>
echo   clone --full-name ^<full-repo-name^>
echo   clone --list-patterns
echo   clone --clear-cache
echo.
echo OPTIONS:
echo   -h, --help              Show this help message
echo   -v, --verbose           Enable verbose output for debugging
echo   -rm, --remove           Remove a repository instead of cloning
echo   -s, --site              Clone/remove all repositories for a specific site
echo   --discover              Discover available repository patterns for a plugin
echo   --pattern ^<pattern^>     Use a specific pattern (e.g., "Nop.Plugin.Custom.{name}")
echo   --full-name ^<name^>      Use the complete repository name
echo   --list-patterns         Show all known repository patterns
echo   --clear-cache           Clear the pattern cache
echo.
echo PATTERN LEARNING:
echo   The script automatically learns and caches correct repository patterns.
echo   It tries multiple common NopCommerce plugin patterns in this order:
echo   1. Nop.Plugin.Opensoft.{name}     7. Nop.Plugin.Tax.{name}
echo   2. Nop.Plugin.Misc.{name}         8. Nop.Plugin.ExternalAuth.{name}
echo   3. Nop.Plugin.{name}              9. Nop.Plugin.DiscountRules.{name}
echo   4. Nop.Plugin.Widgets.{name}     10. Nop.Plugin.MultiFactorAuth.{name}
echo   5. Nop.Plugin.Payments.{name}    11. Nop.Plugin.Pickup.{name}
echo   6. Nop.Plugin.Shipping.{name}    12. Nop.Plugin.Api.{name}
echo.
echo BASIC EXAMPLES:
echo   clone SEO               Clone the SEO plugin (auto-discovers pattern)
echo   clone -v PayPal         Clone PayPal plugin with verbose output
echo   clone -rm SEO           Remove the SEO plugin repository
echo   clone --site MySite     Clone all plugins for a site
echo   clone -rm -s MySite     Remove all plugins for a site
echo.
echo PATTERN LEARNING EXAMPLES:
echo   clone --discover ProductAttribute      Discover available patterns for ProductAttribute
echo   clone --pattern "Nop.Plugin.Custom.{name}" MyPlugin   Use custom pattern
echo   clone --full-name Nop.Plugin.Misc.ProductAttribute    Use exact repository name
echo   clone --list-patterns                  Show all known patterns
echo   clone --clear-cache                    Clear pattern cache
echo.
echo TROUBLESHOOTING:
echo   If a plugin fails to clone:
echo   1. Use --discover to see available patterns
echo   2. Check the spelling of the plugin name
echo   3. Use --pattern or --full-name for custom repositories
echo.
echo DESCRIPTION:
echo   This script manages NopCommerce plugin repositories by cloning them from
echo   Azure DevOps and adding them to the solution. It automatically discovers
echo   and caches the correct repository patterns for different plugin types.
echo.
echo   Pattern learning reduces the need to know exact repository names by
echo   automatically testing common patterns and caching successful matches.
echo.
echo   For site operations, the script reads from PluginList.txt files located at:
echo   sites/^<site-name^>/PluginList.txt
echo.
exit /b 0

REM Function to get cached pattern for a plugin
:get_cached_pattern
setlocal enabledelayedexpansion
set "PLUGIN_NAME=%~1"
set "RESULT_VAR=%~2"

if not exist "%PATTERN_CACHE_FILE%" (
    endlocal & set "%RESULT_VAR%="
    goto :eof
)

for /f "usebackq tokens=1,2 delims==" %%a in ("%PATTERN_CACHE_FILE%") do (
    if "%%a"=="%PLUGIN_NAME%" (
        endlocal & set "%RESULT_VAR%=%%b"
        goto :eof
    )
)

endlocal & set "%RESULT_VAR%="
goto :eof

REM Function to cache a pattern for a plugin
:cache_pattern
setlocal enabledelayedexpansion
set "PLUGIN_NAME=%~1"
set "PATTERN=%~2"

if "%VERBOSE%"=="true" echo [DEBUG] Caching pattern for %PLUGIN_NAME%: %PATTERN% >&2

REM Create cache directory if it doesn't exist
for %%f in ("%PATTERN_CACHE_FILE%") do (
    if not exist "%%~dpf" mkdir "%%~dpf"
)

REM Remove existing entry for this plugin
if exist "%PATTERN_CACHE_FILE%" (
    for /f "usebackq tokens=* delims=" %%a in ("%PATTERN_CACHE_FILE%") do (
        set "LINE=%%a"
        for /f "tokens=1 delims==" %%b in ("!LINE!") do (
            if not "%%b"=="%PLUGIN_NAME%" echo !LINE!
        )
    ) > "%PATTERN_CACHE_FILE%.tmp"
    move "%PATTERN_CACHE_FILE%.tmp" "%PATTERN_CACHE_FILE%" >nul
)

REM Add new entry
echo %PLUGIN_NAME%=%PATTERN% >> "%PATTERN_CACHE_FILE%"

endlocal
goto :eof

REM Function to check if a repository exists
:check_repository_exists
setlocal enabledelayedexpansion
set "REPO_URL=%~1"

if "%VERBOSE%"=="true" echo [DEBUG] Checking repository: %REPO_URL% >&2

REM Use git ls-remote to check if repository exists
git ls-remote "%REPO_URL%" >nul 2>&1
set RESULT=!errorlevel!

endlocal & exit /b %RESULT%

REM Function to find the correct repository pattern for a plugin
:find_repository_pattern
setlocal enabledelayedexpansion
set "PLUGIN_NAME=%~1"
set "RESULT_VAR=%~2"

set DEVOPS_PROJECT_LOCAL=git@ssh.dev.azure.com:v3/FarHeapSolutions/Nop%%20Plugins

if "%VERBOSE%"=="true" echo [DEBUG] Finding pattern for: %PLUGIN_NAME% >&2

REM First check cache
call :get_cached_pattern "%PLUGIN_NAME%" CACHED_PATTERN
if defined CACHED_PATTERN (
    if "%VERBOSE%"=="true" echo [DEBUG] Found cached pattern: %CACHED_PATTERN% >&2
    endlocal & set "%RESULT_VAR%=%CACHED_PATTERN%"
    goto :eof
)

REM Get pattern hints first
call :get_pattern_hints "%PLUGIN_NAME%"

REM Test each pattern in order
for /l %%i in (1,1,%PATTERN_COUNT%) do (
    call set CURRENT_PATTERN=%%PATTERN_%%i%%
    call set TEST_REPO_SLUG=!CURRENT_PATTERN:{name}=%PLUGIN_NAME%!
    set TEST_REPO_URL=!DEVOPS_PROJECT_LOCAL!/!TEST_REPO_SLUG!

    if "%VERBOSE%"=="true" echo [DEBUG] Testing pattern: !CURRENT_PATTERN! -^> !TEST_REPO_SLUG! >&2

    call :check_repository_exists "!TEST_REPO_URL!"
    if !errorlevel! equ 0 (
        if "%VERBOSE%"=="true" echo [DEBUG] Found working pattern: !CURRENT_PATTERN! >&2
        call :cache_pattern "%PLUGIN_NAME%" "!CURRENT_PATTERN!"
        endlocal & set "%RESULT_VAR%=!CURRENT_PATTERN!"
        goto :eof
    )
)

REM No pattern found
if "%VERBOSE%"=="true" echo [DEBUG] No working pattern found for: %PLUGIN_NAME% >&2
endlocal & set "%RESULT_VAR%="
goto :eof

REM Function to get pattern hints based on plugin name
:get_pattern_hints
setlocal enabledelayedexpansion
set "PLUGIN_NAME=%~1"

REM Convert to lowercase for comparison
set "LOWER_NAME=%PLUGIN_NAME%"
call :to_lower LOWER_NAME

REM Payment-related plugins
echo %LOWER_NAME% | findstr /i "payment paypal stripe authnet klarna mollie worldpay square" >nul
if !errorlevel! equ 0 (
    if "%VERBOSE%"=="true" echo [DEBUG] Hint: %PLUGIN_NAME% looks like a payment plugin >&2
    goto :eof
)

REM Shipping-related plugins
echo %LOWER_NAME% | findstr /i "shipping fedex ups dhl usps" >nul
if !errorlevel! equ 0 (
    if "%VERBOSE%"=="true" echo [DEBUG] Hint: %PLUGIN_NAME% looks like a shipping plugin >&2
    goto :eof
)

REM Widget-related plugins
echo %LOWER_NAME% | findstr /i "widget slider banner carousel" >nul
if !errorlevel! equ 0 (
    if "%VERBOSE%"=="true" echo [DEBUG] Hint: %PLUGIN_NAME% looks like a widget plugin >&2
    goto :eof
)

REM Tax-related plugins
echo %LOWER_NAME% | findstr /i "tax avalara" >nul
if !errorlevel! equ 0 (
    if "%VERBOSE%"=="true" echo [DEBUG] Hint: %PLUGIN_NAME% looks like a tax plugin >&2
    goto :eof
)

REM Misc/General plugins (common fallback)
echo %LOWER_NAME% | findstr /i "seo export import product category customer order" >nul
if !errorlevel! equ 0 (
    if "%VERBOSE%"=="true" echo [DEBUG] Hint: %PLUGIN_NAME% looks like a misc plugin >&2
    goto :eof
)

if "%VERBOSE%"=="true" echo [DEBUG] No specific hints for: %PLUGIN_NAME% >&2
goto :eof

REM Function to convert string to lowercase
:to_lower
setlocal enabledelayedexpansion
set "STR=!%~1!"
for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    call set "STR=%%STR:%%i=%%i%%"
)
for %%i in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    call set "STR=%%STR:%%i=%%i%%"
)
REM Map uppercase to lowercase
set "STR=%STR:A=a%"
set "STR=%STR:B=b%"
set "STR=%STR:C=c%"
set "STR=%STR:D=d%"
set "STR=%STR:E=e%"
set "STR=%STR:F=f%"
set "STR=%STR:G=g%"
set "STR=%STR:H=h%"
set "STR=%STR:I=i%"
set "STR=%STR:J=j%"
set "STR=%STR:K=k%"
set "STR=%STR:L=l%"
set "STR=%STR:M=m%"
set "STR=%STR:N=n%"
set "STR=%STR:O=o%"
set "STR=%STR:P=p%"
set "STR=%STR:Q=q%"
set "STR=%STR:R=r%"
set "STR=%STR:S=s%"
set "STR=%STR:T=t%"
set "STR=%STR:U=u%"
set "STR=%STR:V=v%"
set "STR=%STR:W=w%"
set "STR=%STR:X=x%"
set "STR=%STR:Y=y%"
set "STR=%STR:Z=z%"
endlocal & set "%~1=%STR%"
goto :eof

REM Function to suggest alternatives when no repository is found
:suggest_alternatives
setlocal enabledelayedexpansion
set "PLUGIN_NAME=%~1"

echo.
echo 💡 Suggestions:
echo   • Check the spelling of '%PLUGIN_NAME%'
echo   • Try using --discover to see all available patterns
echo   • Use --full-name if you know the complete repository name
echo   • Use --pattern to specify a custom pattern
echo.
echo Examples:
echo   clone --discover %PLUGIN_NAME%
echo   clone --full-name Nop.Plugin.Category.%PLUGIN_NAME%
echo   clone --pattern "Nop.Plugin.Custom.{name}" %PLUGIN_NAME%

endlocal
goto :eof

REM Function to process a single repository (clone or remove) with pattern learning
:process_repository
setlocal enabledelayedexpansion
set OPERATION=%~1
set REPO_NAME_PARAM=%~2

REM Determine the repository slug using pattern learning
if defined FULL_NAME (
    set REPO_SLUG_LOCAL=%FULL_NAME%
    if "%VERBOSE%"=="true" echo [DEBUG] Using full name: %REPO_SLUG_LOCAL% >&2
) else if defined MANUAL_PATTERN (
    set REPO_SLUG_LOCAL=!MANUAL_PATTERN:{name}=%REPO_NAME_PARAM%!
    if "%VERBOSE%"=="true" echo [DEBUG] Using manual pattern: %MANUAL_PATTERN% -^> %REPO_SLUG_LOCAL% >&2
) else (
    REM Use pattern learning to find the correct pattern
    call :find_repository_pattern "%REPO_NAME_PARAM%" FOUND_PATTERN
    if defined FOUND_PATTERN (
        set REPO_SLUG_LOCAL=!FOUND_PATTERN:{name}=%REPO_NAME_PARAM%!
        if "%VERBOSE%"=="true" echo [DEBUG] Using discovered pattern: !FOUND_PATTERN! -^> %REPO_SLUG_LOCAL% >&2
    ) else (
        REM Fallback to default pattern
        set REPO_SLUG_LOCAL=Nop.Plugin.Opensoft.%REPO_NAME_PARAM%
        if "%VERBOSE%"=="true" echo [DEBUG] Using default pattern (fallback): %REPO_SLUG_LOCAL% >&2
        echo Warning: No matching repository pattern found for '%REPO_NAME_PARAM%'. Using default pattern.
        echo If this fails, try: clone --discover %REPO_NAME_PARAM%
    )
)

set CLONE_DIR_LOCAL=%PLUGINS_DIR%\%REPO_SLUG_LOCAL%

if "%VERBOSE%"=="true" echo [DEBUG] Processing: %OPERATION% %REPO_NAME_PARAM% as %REPO_SLUG_LOCAL% >&2

if "%OPERATION%"=="clone" (
    echo --- Cloning %REPO_NAME_PARAM% ---

    if exist "%CLONE_DIR_LOCAL%" (
        echo Repository %REPO_SLUG_LOCAL% already exists. Skipping clone.
        goto process_end
    )

    git clone "%DEVOPS_PROJECT%/%REPO_SLUG_LOCAL%" "%CLONE_DIR_LOCAL%"
    if !errorlevel! neq 0 (
        echo Error: Failed to clone %REPO_SLUG_LOCAL%. Skipping.
        goto process_end
    )

    REM Verify the clone was successful by checking for the project file
    if not exist "%CLONE_DIR_LOCAL%\%REPO_SLUG_LOCAL%.csproj" (
        echo Error: Repository cloned but project file '%REPO_SLUG_LOCAL%.csproj' is missing
        echo Removing incomplete clone...
        rmdir /s /q "%CLONE_DIR_LOCAL%"
        goto process_end
    )

    pushd "%CLONE_DIR_LOCAL%"
    git checkout 4.80/develop
    if !errorlevel! neq 0 (
        echo Warning: Failed to switch to branch '4.80/develop' for %REPO_SLUG_LOCAL%
        echo The repository was cloned but may be on a different default branch.
    )
    popd

    REM Add to solution
    pushd "%SOLUTION_DIR%"
    if exist "Plugins\%REPO_SLUG_LOCAL%\%REPO_SLUG_LOCAL%.csproj" (
        dotnet sln "%CHOSEN_SOLUTION%" add --solution-folder Plugins "Plugins\%REPO_SLUG_LOCAL%\%REPO_SLUG_LOCAL%.csproj"
        if !errorlevel! equ 0 (
            echo Project %REPO_SLUG_LOCAL% added to solution.
        ) else (
            echo Warning: Failed to add %REPO_SLUG_LOCAL% to solution.
        )
    ) else (
        echo Warning: Project file not found for %REPO_SLUG_LOCAL%
    )
    popd
    echo --- Finished cloning %REPO_NAME_PARAM% ---

) else if "%OPERATION%"=="remove" (
    echo --- Removing %REPO_NAME_PARAM% ---

    if exist "%CLONE_DIR_LOCAL%" (
        rmdir /s /q "%CLONE_DIR_LOCAL%"
        echo Folder '%CLONE_DIR_LOCAL%' removed.
    ) else (
        echo Folder '%CLONE_DIR_LOCAL%' does not exist.
    )

    pushd "%SOLUTION_DIR%"
    REM Use dotnet sln remove since we have a placeholder plugin to prevent empty folder removal
    where dotnet >nul 2>&1
    if !errorlevel! equ 0 (
        dotnet sln "%CHOSEN_SOLUTION%" remove "Plugins\%REPO_SLUG_LOCAL%\%REPO_SLUG_LOCAL%.csproj" 2>nul
        if !errorlevel! equ 0 (
            echo Project %REPO_SLUG_LOCAL% removed from solution.
        ) else (
            echo Warning: Failed to remove %REPO_SLUG_LOCAL% from solution (may not have been in solution).
        )
    ) else (
        echo dotnet command not found. Removing project from solution manually...
        REM Note: Manual removal in batch would require complex parsing
        REM For now, just warn the user
        echo Warning: Manual solution editing not implemented in Windows batch script.
        echo Please remove the project manually from the solution file or install dotnet CLI.
    )
    popd
    echo --- Finished removing %REPO_NAME_PARAM% ---
)

:process_end
endlocal
goto :eof

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
        REM Normalize path to remove double slashes
        set "NORMALIZED_PATH=%%f"
        set "NORMALIZED_PATH=!NORMALIZED_PATH:\\=\!"
        set SOLUTION_!SOLUTION_COUNT!=!NORMALIZED_PATH!
        if "%VERBOSE%"=="true" echo [DEBUG] Found solution: !NORMALIZED_PATH!
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
set INDEX=1
:display_loop
if %INDEX% gtr %SOLUTION_COUNT% goto :eof
call set CURRENT_SOL=%%SOLUTION_%INDEX%%%
for %%f in ("%CURRENT_SOL%") do (
    echo   %INDEX%. %%~nxf
    echo      ^> %%f
)
set /a INDEX+=1
goto display_loop

REM Function to validate choice and set chosen solution
:validate_and_set_choice
REM Trim any whitespace from CHOICE
for /f "tokens=* delims= " %%a in ("%CHOICE%") do set CHOICE=%%a

REM Validate range
if %CHOICE% lss 1 (
    echo Invalid choice. Please enter a number between 1 and %SOLUTION_COUNT%.
    exit /b 1
)
if %CHOICE% gtr %SOLUTION_COUNT% (
    echo Invalid choice. Please enter a number between 1 and %SOLUTION_COUNT%.
    exit /b 1
)

REM Set chosen solution using array index
call set CHOSEN_SOLUTION=%%SOLUTION_%CHOICE%%%
goto :eof
