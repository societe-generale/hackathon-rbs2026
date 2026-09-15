@echo off
setlocal enabledelayedexpansion

REM admin\create-resource-groups.bat - Create resource groups for all teams

set "LOCATION=swedencentral"
set "RESOURCE_GROUP_PREFIX=rg-hackathon-rbs2026"

echo.
echo ========================================
echo Azure Admin: Create Resource Groups
echo ========================================
echo.

where az >nul 2>nul
if errorlevel 1 (
    echo ❌ Azure CLI not found. Install: https://aka.ms/azure-cli
    exit /b 1
)

az account show >nul 2>&1
if errorlevel 1 (
    echo ℹ Signing in to Azure...
    call az login --use-device-code
)

for /f "tokens=*" %%i in ('az account show --query user.name -o tsv') do set "ACCOUNT=%%i"
for /f "tokens=*" %%i in ('az account show --query name -o tsv') do set "CURRENT_SUB=%%i"

echo ✓ Authenticated as: %ACCOUNT%
echo Current subscription: %CURRENT_SUB%
echo.

echo This will create 11 resource groups:
echo.
for %%i in (uc1 uc2 uc3 uc4 uc5 uc6 uc7 uc8 uc9 uc10 uc11) do (
    echo   • %RESOURCE_GROUP_PREFIX%-%%i
)
echo.
echo Location: %LOCATION%
echo.

set /p confirm="Proceed? (y/n): "

if /i not "!confirm!"=="y" (
    echo ❌ Cancelled
    exit /b 0
)

echo.
echo ========================================
echo Creating Resource Groups
echo ========================================
echo.

set /a CREATED=0
set /a FAILED=0

for %%i in (uc1 uc2 uc3 uc4 uc5 uc6 uc7 uc8 uc9 uc10 uc11) do (
    set "RG_NAME=%RESOURCE_GROUP_PREFIX%-%%i"

    setlocal enabledelayedexpansion
    <nul set /p ="Creating !RG_NAME!... "
    endlocal

    az group show --name "!RG_NAME!" >nul 2>&1
    if errorlevel 1 (
        call az group create --name "!RG_NAME!" --location "%LOCATION%" >nul 2>&1
        if errorlevel 1 (
            echo ❌ failed
            set /a FAILED=!FAILED!+1
        ) else (
            echo ✓ created
            set /a CREATED=!CREATED!+1
        )
    ) else (
        echo ℹ already exists
    )
)

echo.
echo ========================================
echo Summary
echo ========================================
echo.
echo Created: %CREATED%
echo Failed: %FAILED%
echo.

if %FAILED% equ 0 (
    echo ✓ All resource groups ready!
    echo.
    echo List your resource groups:
    echo   az group list --query "[?contains(name, 'hackathon')].name" -o table
    echo.
) else (
    echo ❌ Some resource groups failed to create
    exit /b 1
)

pause
