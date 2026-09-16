# Deployment Guide: Azure Infrastructure

Deploy your team's infrastructure to build AI applications. Each team gets their own Azure resource group with preconfigured services.

**For admins?** See [ADMIN.md](ADMIN.md) for resource group management and cost monitoring.

---

## ⚡ Quick Start (3 steps)

### Step 1: Prerequisites
```bash
# Install Azure CLI: https://aka.ms/azure-cli
az login
az account set --subscription "<your-subscription-id>"
```

### Step 2: Create Parameter File
```bash
cp infra/main.bicepparam infra/main-<teamname>.bicepparam
```

Edit `infra/main-<teamname>.bicepparam`:
```bicep
param teamName = 'panthers'        # Your team name (lowercase, 2-12 chars)
param location = 'swedencentral'   # Region: swedencentral, westeurope, eastus
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

### Step 3: Deploy
```bash
make deploy TEAM=panthers
# Or manually:
cd infra
bash deploy.sh  # Linux/Mac
deploy.bat      # Windows
```

**Expected time:** 2 min setup + 5-15 min deployment

---

## 📊 Use Cases at a Glance

Choose the resources you need:

| Use Case | Best For | Foundry | Storage | Cosmos | Search |
|----------|----------|---------|---------|--------|--------|
| **RAG Assistant** | Q&A from your documents | ✅ | ✅ | ✅ | ✅ |
| **Multi-Agent Orchestrator** | Complex workflows | ✅ | ✅ | ✅ | — |
| **Semantic Search** | Content discovery | ✅ | ✅ | — | ✅ |
| **Stateful Chatbot** | Conversational AI | ✅ | — | ✅ | — |
| **Minimal LLM** | Quick prototyping | ✅ | — | — | — |

---

## 🏗️ Infrastructure Components

### Azure AI Foundry
LLM endpoint for your applications. Deploy one or more models:
- `gpt-4o` - Best quality, complex reasoning
- `gpt-4o-mini` - General purpose, cost-effective
- `gpt-5.4-mini` - Fast, optimized for chatbots
- `gpt-5.6-terra` - Latest features, cutting edge

### Storage Account
Blob storage for documents and artifacts. Includes a `documents` container for RAG pipelines.

### Cosmos DB
NoSQL database (serverless, on-demand pricing). Comes with:
- `agent` container - Store agent state
- `sessions` container - Store chat history and context

### Azure AI Search
Vector + semantic search. Optimized for hybrid retrieval over your documents.

---

## 📋 Available Regions & Models

| Region | Code | Models |
|--------|------|--------|
| Sweden Central | `swedencentral` | gpt-4o, gpt-4o-mini, gpt-5.4-mini, gpt-5.6-terra |
| West Europe | `westeurope` | gpt-4o, gpt-4o-mini, gpt-5.4-mini |
| East US | `eastus` | gpt-4o, gpt-4o-mini, gpt-5.4-mini, gpt-5.6-terra |

Choose based on latency requirements and model availability.

---

## Use Case Details

### RAG-Powered Assistant
Build intelligent Q&A systems that learn from your documents.

**Resources:** Foundry, Storage, Cosmos, Search

**Deploy:**
```bicep
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

### Multi-Agent Orchestrator
Complex workflows where multiple specialized agents work together.

**Resources:** Foundry (2 deployments), Storage, Cosmos

**Deploy:**
```bicep
param modelDeployments = [
  {
    deploymentName: 'orchestrator'
    modelName: 'gpt-4o'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 2
  }
  {
    deploymentName: 'worker'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
```

### Semantic Search Engine
High-performance content discovery and retrieval.

**Resources:** Foundry, Storage, Search

### Stateful Chatbot
Conversational AI with session memory and context.

**Resources:** Foundry, Cosmos (no document storage needed)

### Minimal LLM Service
Quick prototyping and testing with just LLM access.

**Resources:** Foundry only (minimal cost)

---

## ✅ After Deployment

### 1. Get Your Endpoints
```bash
make deploy-outputs TEAM=panthers
# Or manually:
az deployment sub show --name "hackathon-rbs2026-panthers" \
  --query properties.outputs --output json
```

### 2. Get API Keys
```bash
# Foundry key
az cognitiveservices account keys list \
  --name "foundry-rbs2026-panthers" \
  --resource-group "rg-hackathon-rbs2026-panthers" \
  --query key1 --output tsv

# Search key (if using)
az search admin-key show \
  --resource-group "rg-hackathon-rbs2026-panthers" \
  --service-name "search-rbs2026-panthers"

# Storage connection string (if using)
az storage account show-connection-string \
  --name "st<teamname><hash>" \
  --resource-group "rg-hackathon-rbs2026-panthers"
```

### 3. Configure Your Application
Create `.env` in your application root:

```env
# Required
AZURE_OPENAI_ENDPOINT=https://foundry-rbs2026-panthers.openai.azure.com/
AZURE_OPENAI_API_KEY=<your-key>
AZURE_OPENAI_DEPLOYMENT_NAME=chat
AZURE_OPENAI_API_VERSION=2025-04-01-preview

# Optional (if using Storage)
AZURE_STORAGE_ACCOUNT=st<teamname><hash>
AZURE_STORAGE_CONTAINER=documents

# Optional (if using Cosmos)
AZURE_COSMOS_CONNECTION_STRING=<connection-string>

# Optional (if using Search)
AZURE_SEARCH_ENDPOINT=https://search-rbs2026-panthers.search.windows.net/
AZURE_SEARCH_API_KEY=<search-key>
```

### 4. Start Building
Use the Python starter as a reference:

```python
from openai import AzureOpenAI

client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_version="2025-04-01-preview",
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)

response = client.chat.completions.create(
    model="chat",  # deployment name
    messages=[
        {"role": "system", "content": "You are helpful"},
        {"role": "user", "content": "Hello!"}
    ]
)
print(response.choices[0].message.content)
```

---

## 🎯 Customization

### Multi-Model Deployment
Deploy multiple models at once:

```bicep
param modelDeployments = [
  {
    deploymentName: 'orchestrator'
    modelName: 'gpt-4o'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 2
  }
  {
    deploymentName: 'worker'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
```

Then call different deployments:
```python
# Use orchestrator
response = client.chat.completions.create(
    model="orchestrator",  # different deployment
    messages=[...]
)
```

### Custom Resource Names
Edit parameter file:

```bicep
param foundryName = 'my-custom-foundry'
param storageAccountName = 'mystorageaccount'
param cosmosAccountName = 'my-cosmos'
param searchServiceName = 'my-search'
```

### Custom Tags
```bicep
param tags = {
  environment: 'dev'
  project: 'hackathon-rbs2026'
  team: teamName
  owner: 'your-email@company.com'
}
```

---

## 🔧 Commands Reference

### Deploy
```bash
# Create/update infrastructure
make deploy TEAM=panthers

# Preview what will change
make deploy-validate TEAM=panthers

# Get deployment endpoints
make deploy-outputs TEAM=panthers

# Delete everything
make deploy-destroy TEAM=panthers
```

### Manual Deployment
```bash
# Validate
az deployment sub what-if \
  --name hackathon-rbs2026-panthers \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main-panthers.bicepparam

# Deploy
az deployment sub create \
  --name hackathon-rbs2026-panthers \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main-panthers.bicepparam

# Get outputs
az deployment sub show \
  --name hackathon-rbs2026-panthers \
  --query properties.outputs --output json
```

---

## ❌ Troubleshooting

### Deployment fails with "Quota exceeded"
**Solution:** Your subscription hit quota limits. Contact the hackathon organizers.

### "Deployment fails with authentication error"
**Solution:** Ensure you're logged in and have the right subscription:
```bash
az login
az account show  # Check subscription
az account set --subscription "<id>"
```

### Deployment is stuck for >30 minutes
**Solution:** Check status:
```bash
az deployment sub show --name "hackathon-rbs2026-panthers" \
  --query properties.provisioningState
```

Normal deployments complete in 5-15 minutes. If stuck, cancel and retry:
```bash
# Stop deployment
az deployment sub cancel --name "hackathon-rbs2026-panthers"
```

### "Resource group not found"
**Solution:** List your resource groups:
```bash
az group list --query "[?contains(name, 'hackathon')].name" --output table
```

Make sure your `teamName` in the parameter file matches your resource group.

### Parameter validation fails
**Solution:** Check your `.bicepparam` file:
- `teamName`: lowercase, 2-12 characters
- `location`: `swedencentral`, `westeurope`, or `eastus`
- `modelDeployments`: valid JSON/Bicep array syntax

---

## 🗑️ Cleanup

When you're done:

```bash
# Delete your resource group (one command)
make deploy-destroy TEAM=panthers

# Or manually
az group delete --name "rg-hackathon-rbs2026-panthers" --yes
```

---

## 🔐 Cost Estimation

Approximate monthly costs per team (light usage):

| Use Case | Cost |
|----------|------|
| RAG Assistant | ~$13 |
| Multi-Agent | ~$13 |
| Semantic Search | ~$11 |
| Chatbot | ~$7 |
| Minimal LLM | ~$5 |

*Actual costs depend on usage patterns and request volume. See [Azure pricing](https://azure.microsoft.com/pricing/) for details.*

---

## 📞 Need Help?

1. **Check this guide's Troubleshooting section** - Most issues are covered
2. **Check the deployment logs** - `make deploy TEAM=panthers` shows detailed output
3. **For advanced issues** - Contact admins (see [ADMIN.md](ADMIN.md))
4. **For developer questions** - See [README.md](README.md)

---

## 🚀 Next Steps

- ✅ Deployed infrastructure
- 👉 **Next:** Go to [README.md](README.md) and run the Python starter to start building
- 🏆 Build your AI application during the hackathon
