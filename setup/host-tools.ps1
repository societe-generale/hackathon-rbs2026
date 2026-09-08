# Run in PowerShell as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run PowerShell as Administrator."
    Exit
}

Write-Host "--- Installing Host Dev Infrastructure ---" -ForegroundColor Cyan

# Install WSL 2 (requis pour Docker)
Write-Host "Activation du composant WSL..." -ForegroundColor Yellow
wsl --install --no-distribution

# Install Git, Docker Desktop, VS Code, Azure CLI and Make
$packages = @("Git.Git", "Docker.DockerDesktop", "Microsoft.VisualStudioCode", "GnuWin32.Make", "Microsoft.AzureCLI")

foreach ($package in $packages) {
    Write-Host "Installing $package..." -ForegroundColor Yellow
    winget install --id $package --exact --silent --accept-source-agreements --accept-package-agreements
}

# Install VS Code Dev Containers Extension automatically
Write-Host "Installing VS Code Dev Containers Extension..." -ForegroundColor Green
code --install-extension ms-vscode-remote.remote-containers
# Installation de l'extension Docker / Container Tools (gestion des images, conteneurs, logs)
code --install-extension ms-azuretools.vscode-docker

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

Write-Host "`nHost environment ready! Please restart your computer to start Docker daemon." -ForegroundColor Green