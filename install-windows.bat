@echo off
:: =============================================
::   1Acces Print Collector Agent - Installer Wrapper
:: =============================================
:: Ce .bat lance le script PowerShell install-windows.ps1 qui telecharge
:: le binaire depuis GitHub Releases et installe le service Windows.
:: =============================================

echo =============================================
echo   1Acces Print Collector Agent - Installation
echo =============================================
echo.

:: Verifier les droits admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERREUR] Veuillez executer ce script en tant qu'administrateur.
    pause
    exit /b 1
)

set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%install-windows.ps1

if not exist "%PS_SCRIPT%" (
    echo [ERREUR] install-windows.ps1 introuvable a cote de ce .bat
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%"
set EXITCODE=%ERRORLEVEL%

echo.
if %EXITCODE% neq 0 (
    echo [ERREUR] L'installation a echoue (code %EXITCODE%).
) else (
    echo [OK] Installation terminee.
)
pause
exit /b %EXITCODE%
