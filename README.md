# Hackathon RBS2026 - Python Starter Kit

A containerized Python development environment for quickly building AI applications during the hackathon. Includes Azure AI Foundry infrastructure, document storage, state persistence, and semantic search.

## ⚡ Quick Start (5 minutes)

### Prerequisites
- **Windows 10/11:** Download [Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Mac/Linux:** Install [Docker](https://docs.docker.com/engine/install/) and [VS Code](https://code.visualstudio.com/)

### 1. Clone and Open
```bash
git clone https://github.com/societe-generale/hackathon-rbs2026
cd hackathon-rbs2026
code .
```

### 2. Open Dev Container
VS Code will prompt: **"Reopen in Container"** → Click or press `Ctrl+Shift+P` → type "Dev Containers: Reopen in Container"

Wait ~30 seconds for the container to start.

### 3. Run the Python Starter
```bash
cd starter
uv sync --locked
uv run client.py
```

That's it! Your development environment is ready.

---

## 📁 Project Structure

```
hackathon-rbs2026/
├── README.md                   # This file
├── DEPLOYMENT_GUIDE.md         # → Deploy infrastructure to Azure
├── ADMIN.md                    # → Admin resource group management
├── starter/
│   ├── client.py               # Simple Foundry API client
│   ├── pyproject.toml          # Python dependencies
│   └── .env.example            # Configuration template
├── infra/                      # Azure infrastructure (Bicep templates)
│   ├── main.bicep              # Entry point
│   ├── foundry.bicep           # LLM endpoint
│   ├── storage.bicep           # Document storage
│   ├── cosmos.bicep            # State persistence
│   └── search.bicep            # Semantic search
├── .devcontainer/              # Dev Container configuration
└── setup/
    ├── host-tools.ps1          # Windows host setup (PowerShell)
    └── install-host.bat        # Windows batch launcher
```

---

## 🛠 Development Workflow

### Install Dependencies
```bash
# Inside the dev container
uv sync                  # Install from pyproject.toml
uv pip install <pkg>    # Add a package
```

### Run Your Code
```bash
python your_script.py
```

### Create a New Project
```toml
# pyproject.toml
[project]
name = "my-hackathon-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "openai",           # or your dependencies
    "python-dotenv",
]
```

---

## 🚀 Next: Deploy Your Infrastructure

Once you've set up your development environment, deploy Azure infrastructure to start building real features:

👉 **[Go to DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** for:
- How to deploy LLM endpoints, storage, databases, and search
- Choosing your use case (RAG, chatbot, multi-agent, etc.)
- Configuring your application

---

## 🔧 Troubleshooting

### Dev Container won't start
- Ensure Docker Desktop is running
- Try rebuilding: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
- Check Docker has enough disk space (10 GB recommended)

### Python packages not found
- Make sure you're inside the dev container (check VS Code sidebar)
- Run `uv sync` to install dependencies

### "Python not found" error
- Restart VS Code
- The container installs Python 3.12 automatically on first start
- If still missing, rebuild the container

### Dev Container takes too long to start
- Normal: First build takes 1-2 minutes
- Subsequent starts: 10-30 seconds
- VS Code shows progress in the notification

---

## 📚 Resources

- **[Starter](starter/)** - Example Python client code
- **[Infrastructure](infra/)** - Bicep templates for Azure resources
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Infrastructure and deployment instructions
- **[Admin Guide](ADMIN.md)** - Resource group management (for admins)

---

## 💡 Tips

**Pro tip 1:** Keep `.env` in `starter/` with the Python starter files.

**Pro tip 2:** Use the Python starter as a reference. Extend it for your use case:
```python
from openai import AzureOpenAI
# See starter/client.py for the full example
```

**Pro tip 3:** Check `.devcontainer/devcontainer.json` to customize your environment (VS Code extensions, environment variables, etc.).

---

## ❓ Still Stuck?

1. Check this README's Troubleshooting section
2. Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) if deploying infrastructure
3. Read [ADMIN.md](ADMIN.md) if you're managing resource groups
4. Open a GitHub issue with your error message
