@echo off
setlocal enabledelayedexpansion

REM deploy.bat - Deploy your team's resource group

cd /d "%~dp0" || exit /b 1

set "TEMPLATE_FILE=%cd%\main.bicep"

if "%1"=="" (
    echo.
    echo ❌ Usage: deploy.bat ^<parameters-file^>
    echo.
    echo Examples:
    echo   deploy.bat main-panthers.bicepparam
    echo   deploy.bat main-team1.bicepparam
    echo.
    exit /b 1
)

set "PARAMS_FILE=%1"

if not exist "%PARAMS_FILE%" (
    echo.
    echo ❌ Parameter file not found: %PARAMS_FILE%
    echo.
    echo Create one by copying the template:
    echo   copy main.bicepparam.template main-^<teamname^>.bicepparam
    echo   Edit and customize main-^<teamname^>.bicepparam
    echo.
    exit /b 1
)

echo.
echo ========================================
echo Prerequisites
echo ========================================
echo.

where az >nul 2>nul
if errorlevel 1 (
    echo ❌ Azure CLI not found. Install: https://aka.ms/azure-cli
    exit /b 1
)

echo ✓ Azure CLI found
echo ✓ Parameter file: %PARAMS_FILE%
echo.

echo ========================================
echo Azure Authentication
echo ========================================
echo.

az account show >nul 2>&1
if errorlevel 1 (
    echo Signing into Azure...
    call az login --use-device-code
)

for /f "tokens=*" %%i in ('az account show --query user.name -o tsv') do set "ACCOUNT=%%i"
for /f "tokens=*" %%i in ('az account show --query name -o tsv') do set "SUB=%%i"

echo ✓ Authenticated as: %ACCOUNT%
echo Subscription: %SUB%
echo.

echo ========================================
echo Validating Template
echo ========================================
echo.

call az bicep build --file "%TEMPLATE_FILE%" >nul 2>&1
if errorlevel 1 (
    echo ❌ Bicep validation failed
    exit /b 1
)

echo ✓ Bicep template valid
echo.

REM Extract team name from parameter file
for /f "tokens=*" %%i in ('findstr "param teamName" "%PARAMS_FILE%" ^| findstr /r "= '" ') do (
    set "line=%%i"
    for /f "tokens=2 delims=''" %%j in ("!line:param teamName = '=!") do set "TEAM_NAME=%%j"
)

for /f "tokens=*" %%i in ('findstr "param location" "%PARAMS_FILE%" ^| findstr /r "= '" ') do (
    set "line=%%i"
    for /f "tokens=2 delims=''" %%j in ("!line:param location = '=!") do set "LOCATION=%%j"
)

if "!LOCATION!"=="" set "LOCATION=swedencentral"

set "DEPLOYMENT_NAME=hackathon-rbs2026-!TEAM_NAME!"

echo Team: !TEAM_NAME!
echo Location: !LOCATION!
echo Deployment Name: !DEPLOYMENT_NAME!
echo.

echo ========================================
echo Deployment Preview
echo ========================================
echo.

call az deployment sub what-if ^
    --name "!DEPLOYMENT_NAME!" ^
    --location "!LOCATION!" ^
    --template-file "%TEMPLATE_FILE%" ^
    --parameters "%PARAMS_FILE%" ^
    --output table

echo.
set /p confirm="Proceed with deployment? (y/n): "

if /i not "!confirm!"=="y" (
    echo ❌ Deployment cancelled
    exit /b 0
)

echo.
echo ========================================
echo Deploying Infrastructure
echo ========================================
echo.

echo This may take 5-15 minutes...
echo.

call az deployment sub create ^
    --name "!DEPLOYMENT_NAME!" ^
    --location "!LOCATION!" ^
    --template-file "%TEMPLATE_FILE%" ^
    --parameters "%PARAMS_FILE!"

if errorlevel 1 (
    echo ❌ Deployment failed
    exit /b 1
)

echo.
echo ========================================
echo Deployment Complete
echo ========================================
echo.

echo Getting resource details...
echo.

call az deployment sub show ^
    --name "!DEPLOYMENT_NAME!" ^
    --query properties.outputs ^
    --output json

echo.
echo 📋 Next steps:
echo   1. Update your .env file with the endpoints above
echo   2. Get API keys:
echo      az cognitiveservices account keys list --name "foundry-rbs2026-!TEAM_NAME!" --resource-group "rg-hackathon-rbs2026-!TEAM_NAME!"
echo   3. Check the starter code in ..\starters\
echo.

pause
