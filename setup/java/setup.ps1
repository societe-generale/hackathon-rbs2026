# Run in PowerShell as Administrator when Java or Maven is not already installed.
$ErrorActionPreference = 'Stop'

Write-Host 'Installing Java 17 and Maven...' -ForegroundColor Cyan
try {
	winget install --id Microsoft.OpenJDK.17 --exact --silent --accept-source-agreements --accept-package-agreements
	winget install --id Apache.Maven --exact --silent --accept-source-agreements --accept-package-agreements
	code --install-extension vscjava.vscode-java-pack

	Write-Host "`nJava toolchain:" -ForegroundColor Cyan
	java --version
	mvn --version

	Write-Host "`nJava setup complete. Open a new terminal before running the starter." -ForegroundColor Green
}
finally {
	Read-Host "`nPress Enter to close this window"
}
