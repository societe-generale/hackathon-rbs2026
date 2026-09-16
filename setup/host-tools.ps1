# Run in PowerShell as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator."
    Exit
}

Write-Host "--- Installing Host Dev Infrastructure ---" -ForegroundColor Cyan

# Install WSL 2 (requis pour Docker)
Write-Host "Activation du composant WSL..." -ForegroundColor Yellow
wsl --install --no-distribution

# Install Git, Docker Desktop, VS Code, Azure CLI, Make, Python and uv
$packages = @(
    "Git.Git",
    "Docker.DockerDesktop",
    "Microsoft.VisualStudioCode",
    "GnuWin32.Make",
    "Microsoft.AzureCLI",
    "Python.Python.3.12",
    "astral-sh.uv"
)

foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor Yellow
    winget install --id $package --exact --silent --accept-source-agreements --accept-package-agreements
}

# Ensure make.exe (GnuWin32) is available on PATH for new shells
$makeBinPath = "C:\Program Files (x86)\GnuWin32\bin"
if (Test-Path (Join-Path $makeBinPath "make.exe")) {
    $currentMachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($currentMachinePath -notlike "*$makeBinPath*") {
        Write-Host "Adding $makeBinPath to system PATH..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("Path", "$currentMachinePath;$makeBinPath", "Machine")
    }
    # Make it available in the current session too
    if ($env:Path -notlike "*$makeBinPath*") {
        $env:Path += ";$makeBinPath"
    }
} else {
    Write-Warning "make.exe not found at $makeBinPath. Verify the GnuWin32.Make package installed correctly."
}

# Install VS Code Dev Containers Extension automatically
Write-Host "Installing VS Code Dev Containers Extension..." -ForegroundColor Green
code --install-extension ms-vscode-remote.remote-containers
# Installation de l'extension Docker / Container Tools (gestion des images, conteneurs, logs)
code --install-extension ms-azuretools.vscode-docker
# Install Python tooling for the starter and local development.
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance

# 1. Ensure .wslconfig exists with enough RAM to prevent 'No space left on device' errors
$wslConfigPath = "$env:USERPROFILE\.wslconfig"

$wslConfigContent = @"
[wsl2]
memory=8GB
swap=4GB
"@

if (Test-Path $wslConfigPath) {
    # If file exists, ensure memory setting is added/updated without overwriting unrelated user settings
    $content = Get-Content $wslConfigPath -Raw
    if ($content -notmatch '\[wsl2\]') {
        Add-Content -Path $wslConfigPath -Value "`n[wsl2]`nmemory=8GB`nswap=4GB"
    } elseif ($content -notmatch 'memory=') {
        $content = $content -replace '\[wsl2\]', "[wsl2]`nmemory=8GB`nswap=4GB"
        Set-Content -Path $wslConfigPath -Value $content
    }
} else {
    # Create new .wslconfig file
    Set-Content -Path $wslConfigPath -Value $wslConfigContent
}

Write-Host "`nHost tools installed! Please restart your computer so PATH changes and Docker are available." -ForegroundColor Green
Write-Host "After restarting, run: cd starter; uv sync --locked" -ForegroundColor Green