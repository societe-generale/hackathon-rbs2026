# JavaScript setup

If Node.js is not installed, double-click `install-javascript.bat` to run the
setup with administrator permissions.

Alternatively, run `setup.ps1` in PowerShell as Administrator:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup\javascript\setup.ps1
```

Open a new terminal after installation, then run the starter:

```powershell
cd starter\javascript
# Create and edit the shared .env in the repository root
npm install
npm start
```

Node.js LTS includes `npm`.
