# Hackathon Project

A Python development project with containerized development environment support.

## 📋 Prerequisites

### Windows
- Windows 10 or Windows 11 (21H2 or later)
- Administrative access to your computer

### macOS & Linux
- Docker installed
- VS Code installed

## 🚀 Getting Started

### Windows Setup

1. **Run the host setup script** (requires Administrator privileges):
   ```powershell
   cd setup
   .\install-host.bat
   ```
   This will automatically:
   - Install WSL 2
   - Install Docker Desktop
   - Install Git
   - Install VS Code and required extensions (Dev Containers, Docker)
   - Configure WSL 2 memory settings

2. **Restart your computer** after the script completes

3. **Clone and open the project**:
   ```powershell
   git clone <repository-url>
   cd hackathon
   code .
   ```

4. **Open in Dev Container**:
   - VS Code will prompt you to "Reopen in Container"
   - Click the button or use `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

### macOS & Linux Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd hackathon
   ```

2. **Open in VS Code**:
   ```bash
   code .
   ```

3. **Open in Dev Container**:
   - VS Code will prompt you to "Reopen in Container"
   - Click the button or use `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"

## 📦 Development Environment

This project uses a Dev Container with:
- **Python 3.12** - Latest stable Python version
- **uv** - Fast Python package and project manager
- **VS Code Extensions** - Python, Pylance for enhanced development experience

### Auto-setup

The Dev Container will automatically:
1. Create a Python virtual environment (`.venv`)
2. Install dependencies from `pyproject.toml` or `requirements.txt`

## 📁 Project Structure

```
hackathon/
├── infra/                  # Bicep Azure AI Foundry infrastructure
│   ├── foundry.bicep       # Foundry resource, project, and LLM deployment
│   ├── main.bicep          # Subscription-scoped deployment entry point
│   └── main.bicepparam     # Deployment configuration
├── .devcontainer/          # Dev container configuration
│   ├── Dockerfile          # Container image definition
│   └── devcontainer.json   # VS Code container settings
├── setup/                  # Setup scripts
│   ├── host-tools.ps1      # Windows host setup (PowerShell)
│   └── install-host.bat    # Windows batch launcher
├── .venv/                  # Python virtual environment (auto-created)
├── .gitignore             # Git ignore rules
└── README.md              # This file
```

## Azure AI Foundry infrastructure

The Bicep deployment in [`infra/`](./infra/) provisions a Microsoft Foundry
resource (`Microsoft.CognitiveServices/accounts` with `kind: 'AIServices'`),
its Foundry project, and one or more LLM deployments. Each deployment name is
the value applications send as the `model` or deployment identifier.

### Deploying

1. Sign in to Azure and select the target subscription:

   ```bash
   az login
   az account set --subscription "<subscription-id-or-name>"
   ```

2. Update [`infra/main.bicepparam`](./infra/main.bicepparam). Select a region,
   Foundry resource name, and one or more `modelDeployments` entries with model
   names and versions available to your Azure subscription. The Foundry resource
   name must be globally unique.

   ```bicep
   param modelDeployments = [
     {
       deploymentName: 'chat'
       modelName: 'gpt-4o-mini'
       modelVersion: '2026-03-17'
       skuName: 'GlobalStandard'
       capacity: 1
     }
     {
       deploymentName: 'reasoning'
       modelName: 'gpt-5.6-terra'
       modelVersion: '2026-07-09'
       skuName: 'GlobalStandard'
       capacity: 1
     }
   ]
   ```

3. Validate and deploy the subscription-scoped template (creates the resource
   group and all resources in it):

   ```bash
   make deploy
   ```

   This is equivalent to running:

   ```bash
   az bicep build --file infra/main.bicep
   az deployment sub create \
     --name foundry-llm \
     --location swedencentral \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

   Other useful targets: `make whatif` to preview changes before deploying,
   `make outputs` to print the endpoint/project/deployment names of the last
   deployment, and `make destroy` to delete the resource group. Run `make
   help` to list all targets.

4. Get the endpoint and configure local application variables:

   ```bash
   az deployment sub show \
     --name foundry-llm \
     --query properties.outputs.foundryEndpoint.value --output tsv
   az deployment sub show \
     --name foundry-llm \
       --query properties.outputs.llmDeploymentNames.value --output tsv
   az cognitiveservices account keys list \
     --name "<foundry-name>" \
     --resource-group "<resource-group-name>" \
     --query key1 --output tsv
   ```

   Put the resulting values in `.env` as `AZURE_OPENAI_ENDPOINT`,
   `AZURE_OPENAI_API_KEY`, and the deployment name your app should use as
   `AZURE_OPENAI_DEPLOYMENT_NAME`. Do not commit the key.

To remove the deployed resources when they are no longer needed, run
`make destroy` (or `az group delete --name "<resource-group-name>" --yes`).

## 🛠 Development Workflow

### Installing Dependencies

```bash
# Using uv
uv sync                    # Install from pyproject.toml
uv pip install <package>   # Install a package
```

### Running Your Code

```bash
python your_script.py
```

### Creating a pyproject.toml

If you don't have a `pyproject.toml` yet, create one:

```toml
[project]
name = "hackathon"
version = "0.1.0"
description = "My hackathon project"
requires-python = ">=3.12"
dependencies = [
    # Add your dependencies here
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

## 🔧 VS Code Settings

The Dev Container includes the following VS Code settings:
- **Python Interpreter**: Points to `.venv/bin/python`
- **Format on Save**: Enabled for auto-formatting
- **Extensions**: Python and Pylance for intelligent code analysis

## 📝 Notes

- The project is configured for French development environments
- All Python dependencies should be specified in `pyproject.toml` or `requirements.txt`
- The `.venv` directory is created automatically and should not be committed to git

## 🤝 Contributing

1. Create a new branch for your feature
2. Make your changes
3. Test your code in the Dev Container
4. Commit and push your changes

## 📄 License

Add your license information here.

## ❓ Troubleshooting

### "No space left on device" error on Windows
The setup script automatically configures WSL 2 with 8GB memory and 4GB swap. If you need more, edit `%USERPROFILE%\.wslconfig`:
```
[wsl2]
memory=16GB
swap=8GB
```

### Dev Container won't start
- Ensure Docker Desktop is running
- Try rebuilding the container: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
- Check Docker's available disk space

### Python packages not found
- Ensure you're running commands inside the Dev Container
- Run `uv sync` to install dependencies from `pyproject.toml`
