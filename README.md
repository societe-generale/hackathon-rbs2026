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
├── infra/                  # Bicep hackathon infrastructure (one file per resource kind)
│   ├── main.bicep          # Subscription-scoped entry: creates the RG + wires all modules
│   ├── main.bicepparam     # Team-specific configuration (teamName drives naming)
│   ├── foundry.bicep       # Azure AI Foundry (LLM) resource, project, model deployments
│   ├── storage.bicep       # Storage account + blob container for RAG documents
│   ├── cosmos.bicep        # Cosmos DB (NoSQL, serverless) for chat / agent memory
│   └── search.bicep        # Azure AI Search (vector + semantic) for retrieval
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

## Hackathon Azure infrastructure

The Bicep deployment in [`infra/`](./infra/) provisions everything a team needs
to build a RAG agentic bot, all inside a single per-team resource group:

| Resource | File | Purpose |
| --- | --- | --- |
| Azure AI Foundry (AI Services) + project + model deployments | `foundry.bicep` | LLM endpoint used by your agent |
| Storage account + `documents` blob container | `storage.bicep` | Store source documents and artifacts |
| Cosmos DB (NoSQL, serverless) + `agent`/`sessions` container | `cosmos.bicep` | Chat history, session state, agent memory |
| Azure AI Search (Basic tier) | `search.bicep` | Vector + semantic retrieval for RAG |

Each team deploys their own resource group by setting a unique `teamName` in
`main.bicepparam`. All resource names default to `<kind>-rbs2026-<teamName>`,
so two teams can deploy side-by-side in the same subscription without collision.

### Deploying

1. Sign in to Azure and select the target subscription:

   ```bash
   az login
   az account set --subscription "<subscription-id-or-name>"
   ```

2. Edit [`infra/main.bicepparam`](./infra/main.bicepparam). At minimum set
   `teamName` to your team's short identifier (lowercase, 2-12 chars). Optionally
   override `location` or `modelDeployments`. All resource names are derived
   from `teamName` unless you override them explicitly.

   ```bicep
   param teamName = 'panthers'
   param location = 'swedencentral'
   param modelDeployments = [
     {
       deploymentName: 'chat'
       modelName: 'gpt-4o-mini'
       modelVersion: '2026-03-17'
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

   Other useful targets: `make whatif` to preview changes before deploying,
   `make outputs` to print the endpoints/names of the last deployment, and
   `make destroy` to delete the resource group. Run `make help` to list all
   targets.

4. Get the endpoints and configure local application variables:

   ```bash
   make outputs
   az cognitiveservices account keys list \
     --name "<foundry-name>" \
     --resource-group "<resource-group-name>" \
     --query key1 --output tsv
   ```

   Put the resulting values in `.env` as `AZURE_OPENAI_ENDPOINT`,
   `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_DEPLOYMENT_NAME`, plus the storage
   / Cosmos / search endpoints your app needs. Do not commit keys.

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
