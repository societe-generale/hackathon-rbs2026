# Resource Group Setup - Quick Reference

Complete resource group setup for the hackathon with use-case-specific configurations.

## What's Included

### 📋 Documentation
- **`DEPLOYMENT_GUIDE.md`** - Comprehensive guide for teams deploying resource groups
- **`ORGANIZER_GUIDE.md`** - Guide for hackathon organizers managing the infrastructure
- **`infra/use-cases.json`** - JSON configuration defining 5 use cases

### 🚀 Deployment Scripts
- **`infra/deploy.sh`** - Interactive deployment wizard for Linux/Mac
- **`infra/deploy.bat`** - Interactive deployment wizard for Windows
- **`Makefile`** - Traditional make-based deployment commands

### 🏗️ Infrastructure Templates
- **`infra/main.bicep`** - Subscription-scoped entry point
- **`infra/foundry.bicep`** - Azure AI Foundry (LLM)
- **`infra/storage.bicep`** - Blob storage for documents
- **`infra/cosmos.bicep`** - Cosmos DB for state persistence
- **`infra/search.bicep`** - Azure AI Search for retrieval

---

## For Teams: Quick Start (5 minutes)

### Prerequisites
- Azure CLI installed: https://aka.ms/azure-cli
- Access to Azure subscription
- Git clone of this repository

### Deploy Your Resource Group

**Linux/macOS or in Dev Container:**
```bash
cd infra
bash deploy.sh
```

**Windows (PowerShell/Command Prompt):**
```bash
cd infra
deploy.bat
```

The script will guide you through:
1. Selecting your use case
2. Choosing a region
3. Setting your team name
4. Deploying your infrastructure
5. Showing your endpoints

**Expected time:** 5 minutes setup + 5-15 minutes deployment

### Manual Deployment (Alternative)

```bash
# Login to Azure
az login

# Create your parameter file
cp infra/main.bicepparam infra/main-<teamname>.bicepparam
# Edit main-<teamname>.bicepparam with your team name

# Deploy
cd infra
make PARAMETERS_FILE=main-<teamname>.bicepparam deploy
```

---

## Use Cases at a Glance

| Use Case | Best For | Key Resources |
|----------|----------|---------------|
| **RAG-Powered Assistant** | Q&A systems learning from documents | Foundry, Storage, Cosmos, Search |
| **Multi-Agent Orchestrator** | Complex workflows with multiple agents | Foundry, Storage, Cosmos |
| **Semantic Search Engine** | Content discovery and retrieval | Foundry, Storage, Search |
| **Stateful Chatbot** | Conversational AI with session memory | Foundry, Cosmos |
| **Minimal LLM Service** | Quick prototyping and testing | Foundry only |

→ **Full details:** See `DEPLOYMENT_GUIDE.md`

---

## Available Resources

### Azure AI Foundry
- LLM endpoint for your applications
- Deploy one or more model variants
- Globally available models: gpt-4o, gpt-4o-mini, gpt-5.4-mini, gpt-5.6-terra

### Storage Account
- Blob storage for documents and artifacts
- `documents` container for RAG pipelines

### Cosmos DB
- NoSQL database (serverless, on-demand pricing)
- Pre-configured containers: `agent`, `sessions`
- Perfect for chat history and state persistence

### Azure AI Search
- Vector + semantic search
- Pre-configured for hybrid retrieval
- Scales with your document corpus

---

## After Deployment

### 1. Get Your Endpoints
```bash
TEAM=<your-team-name>
az deployment sub show \
  --name "hackathon-rbs2026-${TEAM}" \
  --query properties.outputs \
  --output json
```

### 2. Configure Your App
Create `.env` file with endpoints and API keys:
```env
AZURE_OPENAI_ENDPOINT=https://foundry-rbs2026-<team>.openai.azure.com/
AZURE_OPENAI_API_KEY=<your-key>
AZURE_OPENAI_DEPLOYMENT_NAME=chat
AZURE_STORAGE_ACCOUNT=st<team><hash>
AZURE_COSMOS_CONNECTION_STRING=<connection-string>
AZURE_SEARCH_ENDPOINT=https://search-rbs2026-<team>.search.windows.net/
AZURE_SEARCH_API_KEY=<search-key>
```

### 3. Start Building
Example starter code available in:
- `starters/python/` - Python client
- `starters/javascript/` - JavaScript/Node.js client
- `starters/java/` - Java client

### 4. Cleanup
```bash
# When finished, delete your resource group
TEAM=<your-team-name>
az group delete --name "rg-hackathon-rbs2026-${TEAM}" --yes
```

---

## For Organizers

### Setup Steps
1. Create Azure subscription (e.g., "Hackathon-RBS2026-Teams")
2. Distribute this repository to teams
3. Provide teams with `DEPLOYMENT_GUIDE.md` link
4. Monitor deployments (see below)

### Monitor Deployments
```bash
# List all team resource groups
az group list --query "[?contains(name, 'hackathon')].name" -o table

# Check deployment status for a team
az deployment sub show \
  --name "hackathon-rbs2026-<teamname>" \
  --query properties.provisioningState

# Get cost breakdown
az costmanagement query --type Usage --timeframe MonthToDate \
  --dataset '{"granularity":"Daily","aggregation":{"totalCost":{"name":"PreTaxCost","function":"Sum"}}}'
```

### Cleanup All Teams (Post-Hackathon)
```bash
# Delete all hackathon resource groups
az group list --query "[?contains(name, 'hackathon')].name" -o tsv | \
  xargs -I {} az group delete --name {} --yes --no-wait
```

→ **Full details:** See `ORGANIZER_GUIDE.md`

---

## Configuration

### Add Custom Use Case
Edit `infra/use-cases.json` to add new use cases:

```json
{
  "id": "my-use-case",
  "name": "My Use Case",
  "description": "What it's for",
  "defaultModels": [...],
  "resources": {
    "foundry": true,
    "storage": true,
    "cosmos": false,
    "search": true
  }
}
```

### Change Deployment Regions
Edit `infra/use-cases.json` `regions` section:

```json
"regions": [
  {
    "id": "westeurope",
    "name": "West Europe",
    "availableModels": ["gpt-4o", "gpt-4o-mini", "gpt-5.4-mini"]
  }
]
```

### Customize Parameter Files
Create `infra/main-<usecase>.bicepparam` template:

```bicep
using './main.bicep'

param teamName = 'myteam'
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

---

## Command Reference

### Teams

```bash
# Interactive deployment
bash infra/deploy.sh          # Linux/Mac
deploy.bat                    # Windows

# Manual deployment
az login
az account set --subscription "<sub-id>"
make -C infra deploy          # With default parameters
make deploy                   # From project root

# Check outputs
make outputs

# Delete resource group
make destroy
```

### Organizers

```bash
# Monitor all deployments
az group list --query "[?contains(name, 'hackathon')].name" --output table

# Get specific deployment status
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.provisioningState

# Retrieve team outputs
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.outputs --output json

# Cleanup
az group delete --name "rg-hackathon-rbs2026-<team>" --yes
```

---

## Resource Naming Convention

All resources follow this pattern:
- **Resource Group:** `rg-hackathon-rbs2026-<teamName>`
- **Foundry:** `foundry-rbs2026-<teamName>`
- **Foundry Project:** `rbs2026-<teamName>`
- **Storage Account:** `st<teamName><hash>`
- **Cosmos Account:** `cosmos-rbs2026-<teamName>`
- **Search Service:** `search-rbs2026-<teamName>`

Team names must be lowercase alphanumeric, 2-12 characters.

---

## Cost Estimation

Approximate monthly costs per team (minimum/light usage):

| Use Case | Cost |
|----------|------|
| RAG Assistant | ~$13 |
| Multi-Agent | ~$13 |
| Semantic Search | ~$11 |
| Stateful Chatbot | ~$7 |
| Minimal LLM | ~$5 |

*Actual costs depend on usage patterns and data volume. See Azure pricing for details.*

---

## Troubleshooting

### Deployment fails
```bash
# Check error details
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.error --output json

# Check operation logs
az deployment sub operation list --name "hackathon-rbs2026-<team>" \
  --query "[].properties.{status:provisioningState, error:statusMessage}"
```

### Can't authenticate
```bash
az login --use-device-code
# Or with specific tenant
az login --tenant <tenant-id>
```

### Resource group not found
```bash
# List all your resource groups
az group list --query "[].name" --output table

# List all in subscription
az group list --subscription "<sub-id>" --query "[].name" --output table
```

### Deployment stuck for >30 minutes
```bash
# Check if still running
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.provisioningState

# Check activity logs
az monitor activity-log list --resource-group "rg-hackathon-rbs2026-<team>" \
  --query "[].properties" --output table
```

→ **More details:** See `DEPLOYMENT_GUIDE.md` Troubleshooting section

---

## Files Overview

```
hackathon-rbs2026/
├── README.md                      # Main project documentation
├── DEPLOYMENT_GUIDE.md            # ← Team guide (start here)
├── ORGANIZER_GUIDE.md             # ← Organizer guide
├── RESOURCE_GROUP_SETUP.md        # ← This file
├── Makefile                       # Make-based deployment
├── infra/
│   ├── deploy.sh                  # Interactive bash script
│   ├── deploy.bat                 # Interactive batch script
│   ├── use-cases.json             # Use case definitions
│   ├── main.bicep                 # Bicep template (entry point)
│   ├── main.bicepparam            # Parameter template
│   ├── foundry.bicep              # Azure AI Foundry module
│   ├── storage.bicep              # Storage module
│   ├── cosmos.bicep               # Cosmos DB module
│   └── search.bicep               # Azure AI Search module
└── starters/
    ├── python/                    # Python starter code
    ├── javascript/                # JavaScript starter code
    └── java/                      # Java starter code
```

---

## Getting Help

### For Teams
1. **First:** Check `DEPLOYMENT_GUIDE.md` Troubleshooting section
2. **Then:** Run the deployment script again with verbose output
3. **Stuck?** Contact organizers with:
   - Your team name
   - The error message
   - Output of: `az account show`

### For Organizers
1. **Reference:** `ORGANIZER_GUIDE.md`
2. **Monitoring:** Check command reference above
3. **Issues:** See Troubleshooting for Organizers in `ORGANIZER_GUIDE.md`

### Links
- [Hackathon Repository](https://github.com/societe-generale/hackathon-rbs2026)
- [Azure CLI Docs](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure Bicep Docs](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Service](https://learn.microsoft.com/en-us/azure/ai-services/openai/)

---

## Summary

✅ **Teams:** Run `bash infra/deploy.sh` or `deploy.bat` to deploy your use case  
✅ **Organizers:** Distribute repository and point to `DEPLOYMENT_GUIDE.md`  
✅ **Documentation:** Full guides in `DEPLOYMENT_GUIDE.md` and `ORGANIZER_GUIDE.md`  
✅ **Support:** Check guides first, then contact organizers  

**Let's build something amazing!** 🚀
