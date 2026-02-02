@echo off
setlocal enabledelayedexpansion

echo.
echo ██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██╗    ██╗
echo ██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██║    ██║
echo ██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██║ █╗ ██║
echo ██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██║███╗██║
echo ██████╔╝███████╗ ╚████╔╝ ██║     ███████╗╚██████╔╝╚███╔███╔╝
echo ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝
echo.
echo  DevFlow by AI LENS
echo  End-to-End Product Development
echo.

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
    echo   [ERROR] GitHub CLI not found. Install: https://cli.github.com/
    exit /b 1
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
mkdir .claude\commands\ai 2>nul
mkdir .claude\commands\testing 2>nul
mkdir .claude\commands\quality 2>nul
mkdir .claude\commands\deploy 2>nul
mkdir .claude\commands\review 2>nul
mkdir .claude\rules 2>nul
mkdir .claude\agents 2>nul
mkdir .claude\scripts\pm 2>nul
mkdir .claude\scripts\common 2>nul
mkdir .claude\hooks 2>nul
mkdir .claude\context 2>nul
mkdir .claude\prds 2>nul
mkdir .claude\epics 2>nul
mkdir .claude\specs 2>nul
mkdir .claude\adrs 2>nul

echo   [OK] Directories created

if exist devflow\ (
    echo Installing DevFlow components...
    xcopy /s /y devflow\commands\* .claude\commands\ >nul 2>&1
    xcopy /s /y devflow\rules\* .claude\rules\ >nul 2>&1
    xcopy /s /y devflow\agents\* .claude\agents\ >nul 2>&1
    xcopy /s /y devflow\scripts\* .claude\scripts\ >nul 2>&1
    xcopy /s /y devflow\hooks\* .claude\hooks\ >nul 2>&1
    echo   [OK] Components installed
)

echo.
echo DevFlow Installation Complete!
echo.
echo Next Steps:
echo   1. Initialize: /devflow:init
echo   2. Set principles: /devflow:principles
echo   3. Create context: /context:create
echo   4. Start building: /pm:prd-new feature-name
echo.

endlocal
exit /b 0
