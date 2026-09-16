# Run in PowerShell as Administrator when Node.js is not already installed.
$ErrorActionPreference = 'Stop'

Write-Host 'Installing Node.js LTS...' -ForegroundColor Cyan
try {
	winget install --id OpenJS.NodeJS.LTS --exact --silent --accept-source-agreements --accept-package-agreements
	code --install-extension dbaeumer.vscode-eslint

	Write-Host "`nJavaScript toolchain:" -ForegroundColor Cyan
	node --version
	npm --version

	Write-Host "`nJavaScript setup complete. Open a new terminal before running the starter." -ForegroundColor Green
}
finally {
	Read-Host "`nPress Enter to close this window"
}
