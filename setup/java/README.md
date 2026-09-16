# Java setup

If Java or Maven is not installed, double-click `install-java.bat` to run the
setup with administrator permissions.

Alternatively, run `setup.ps1` in PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup\java\setup.ps1
```

Open a new terminal after installation, then run the starter:

```powershell
cd starters\java
# Create and edit the shared .env in the repository root
mvn compile
mvn exec:java -Dexec.mainClass="FoundryClient"
```

The starter targets Java 11 and runs on Java 17.
