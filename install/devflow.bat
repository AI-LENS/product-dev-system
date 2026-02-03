@echo off
setlocal enabledelayedexpansion

echo.
echo  ========================================
echo   Product-dev-system by AI LENS
echo   End-to-End Product Development
echo  ========================================
echo.

:: Determine Product-dev-system source directory (where this script lives)
set "SCRIPT_DIR=%~dp0"
set "DEVFLOW_ROOT=%SCRIPT_DIR%.."
pushd "%DEVFLOW_ROOT%"
set "DEVFLOW_ROOT=%CD%"
popd
set "DEVFLOW_SRC=%DEVFLOW_ROOT%\devflow"

echo Product-dev-system source: %DEVFLOW_ROOT%
echo Target project: %CD%
echo.

:: Validate source exists
if not exist "%DEVFLOW_SRC%\" (
    echo [ERROR] Product-dev-system source not found at: %DEVFLOW_SRC%
    echo         Make sure you're running this from a valid Product-dev-system installation.
    exit /b 1
)

:: Prevent installing into Product-dev-system repo itself
if "%CD%"=="%DEVFLOW_ROOT%" (
    echo [ERROR] Cannot install Product-dev-system into itself.
    echo         Run this script from your target project directory.
    exit /b 1
)

:: Check prerequisites
echo Checking prerequisites...

where git >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Git found
) else (
    echo   [ERROR] Git not found. Install: https://git-scm.com/
    exit /b 1
)

where gh >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] GitHub CLI found
) else (
    echo   [WARN] GitHub CLI not found. Install: https://cli.github.com/
)

where python >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Python found
) else (
    echo   [ERROR] Python not found. Install: https://www.python.org/
    exit /b 1
)

echo.
echo Creating directory structure...
mkdir .claude\commands\pm 2>nul
mkdir .claude\commands\context 2>nul
mkdir .claude\commands\design 2>nul
mkdir .claude\commands\init 2>nul
mkdir .claude\commands\arch 2>nul
mkdir .claude\commands\db 2>nul
mkdir .claude\commands\api 2>nul
mkdir .claude\commands\testing 2>nul
mkdir .claude\commands\quality 2>nul
mkdir .claude\commands\deploy 2>nul
mkdir .claude\commands\review 2>nul
mkdir .claude\commands\devflow 2>nul
mkdir .claude\rules 2>nul
mkdir .claude\agents 2>nul
mkdir .claude\scripts\pm 2>nul
mkdir .claude\scripts\common 2>nul
mkdir .claude\hooks 2>nul
mkdir .claude\templates 2>nul
mkdir .claude\context 2>nul
mkdir .claude\prds 2>nul
mkdir .claude\epics 2>nul
mkdir .claude\specs 2>nul
mkdir .claude\adrs 2>nul

echo   [OK] Directories created

echo.
echo Installing Product-dev-system components...

:: Copy commands
if exist "%DEVFLOW_SRC%\commands\" (
    xcopy /s /y /q "%DEVFLOW_SRC%\commands\*" ".claude\commands\" >nul 2>&1
    echo   [OK] Commands installed
)

:: Copy rules
if exist "%DEVFLOW_SRC%\rules\" (
    xcopy /s /y /q "%DEVFLOW_SRC%\rules\*" ".claude\rules\" >nul 2>&1
    echo   [OK] Rules installed
)

:: Copy agents
if exist "%DEVFLOW_SRC%\agents\" (
    xcopy /s /y /q "%DEVFLOW_SRC%\agents\*" ".claude\agents\" >nul 2>&1
    echo   [OK] Agents installed
)

:: Copy scripts
if exist "%DEVFLOW_SRC%\scripts\" (
    xcopy /s /y /q "%DEVFLOW_SRC%\scripts\*" ".claude\scripts\" >nul 2>&1
    echo   [OK] Scripts installed
)

:: Copy hooks
if exist "%DEVFLOW_SRC%\hooks\" (
    xcopy /s /y /q "%DEVFLOW_SRC%\hooks\*" ".claude\hooks\" >nul 2>&1
    echo   [OK] Hooks installed
)

:: Copy templates
if exist "%DEVFLOW_SRC%\templates\" (
    xcopy /s /y /q "%DEVFLOW_SRC%\templates\*" ".claude\templates\" >nul 2>&1
    echo   [OK] Templates installed
)

:: Copy config
if exist "%DEVFLOW_SRC%\devflow.config" (
    copy /y "%DEVFLOW_SRC%\devflow.config" ".claude\" >nul 2>&1
    echo   [OK] Config installed
)

echo.
echo ============================================
echo   Product-dev-system Installation Complete!
echo ============================================
echo.
echo Next Steps:
echo   1. Initialize: /devflow:init
echo   2. Set principles: /devflow:principles
echo   3. Create context: /context:create
echo   4. Start building: /pm:prd-new feature-name
echo.

endlocal
exit /b 0
