# Hackathon Resource Group Deployment Guide

This guide explains how to deploy your team's resource group for the hackathon. Each team gets their own Azure resource group with pre-configured infrastructure optimized for their use case.

## Quick Start (5 minutes)

### Option 1: Interactive Deployment Script (Recommended)

The easiest way to deploy is using the interactive script that guides you through the process.

#### On Linux/macOS or in Dev Container:
```bash
cd infra
bash deploy.sh
```

#### On Windows (in PowerShell or Command Prompt):
```bash
cd infra
deploy.bat
```

The script will:
1. ✅ Check prerequisites (Azure CLI, jq)
2. ✅ Verify you're logged into Azure
3. ✅ Guide you to select your use case
4. ✅ Guide you to select your region
5. ✅ Create a parameter file for your team
6. ✅ Validate the deployment
7. ✅ Deploy your infrastructure
8. ✅ Display your resource endpoints

## Manual Deployment (if you prefer)

### Prerequisites

```bash
# Install Azure CLI
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli

# Login to Azure
az login

# Select your subscription
az account set --subscription "<subscription-id-or-name>"
```

### Step 1: Choose Your Use Case

Select from these pre-configured options:

| Use Case | Best For | Resources |
|----------|----------|-----------|
| **RAG-Powered Assistant** | Q&A systems that learn from your documents | Foundry, Storage, Cosmos, Search |
| **Multi-Agent Orchestrator** | Complex workflows with multiple specialized agents | Foundry, Storage, Cosmos |
| **Semantic Search Engine** | Content discovery and retrieval systems | Foundry, Storage, Search |
| **Stateful Chatbot** | Conversational AI with session management | Foundry, Cosmos |
| **Minimal LLM Service** | Basic LLM integration and API testing | Foundry only |

### Step 2: Create Your Parameter File

Create a file `infra/main-<teamname>.bicepparam`:

```bicep
using './main.bicep'

param teamName = 'panthers'          // Your team name (lowercase, 2-12 chars)
param location = 'swedencentral'     // Azure region

// Use case-specific model configuration
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

### Step 3: Validate Your Deployment

```bash
# Preview what will be deployed
az deployment sub what-if \
  --name hackathon-rbs2026-<teamname> \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main-<teamname>.bicepparam
```

### Step 4: Deploy

```bash
# Deploy your resource group and all resources
az deployment sub create \
  --name hackathon-rbs2026-<teamname> \
  --location swedencentral \
  --template-file infra/main.bicep \
  --parameters infra/main-<teamname>.bicepparam
```

This will take 5-15 minutes depending on the complexity of your use case.

### Step 5: Get Your Outputs

```bash
# Display your deployment endpoints
az deployment sub show \
  --name hackathon-rbs2026-<teamname> \
  --query properties.outputs \
  --output json
```

## Use Case Details

### 1. RAG-Powered Assistant

**Best for:** Building intelligent Q&A systems that can learn from your documents.

**Includes:**
- **Azure AI Foundry**: GPT-4o-mini deployment for LLM access
- **Storage Account**: Blob storage for your documents
- **Cosmos DB**: Store chat history and context
- **Azure AI Search**: Vector + semantic search for document retrieval

**Example:** Customer support bot that answers questions based on product documentation

**Deployment:**
```bash
# Edit infra/main-<teamname>.bicepparam
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

### 2. Multi-Agent Orchestrator

**Best for:** Complex workflows where multiple specialized agents work together.

**Includes:**
- **Azure AI Foundry**: GPT-4o (orchestrator) + GPT-4o-mini (workers)
- **Storage Account**: Store artifacts and intermediate results
- **Cosmos DB**: Persist agent state and conversation history
- **No Search**: Use your own retrieval logic

**Example:** Investment analysis system with research, analysis, and recommendation agents

**Deployment:**
```bash
param teamName = 'tigers'
param location = 'swedencentral'
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

### 3. Semantic Search Engine

**Best for:** Building high-performance content discovery and retrieval systems.

**Includes:**
- **Azure AI Foundry**: LLM for query understanding
- **Storage Account**: Store your content corpus
- **Azure AI Search**: Optimized for vector + semantic retrieval
- **No Cosmos**: Data is ephemeral (no session state needed)

**Example:** Product recommendation engine, document library search

**Deployment:**
```bash
param teamName = 'eagles'
param location = 'swedencentral'
param modelDeployments = [
  {
    deploymentName: 'search'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
```

### 4. Stateful Chatbot

**Best for:** Creating conversational interfaces with session and context awareness.

**Includes:**
- **Azure AI Foundry**: GPT-5.4-mini for faster responses
- **Cosmos DB**: Persistent chat history and user context
- **No Storage**: Chat-only, no document uploads
- **No Search**: No retrieval needed

**Example:** Personal assistant, customer service chatbot with memory

**Deployment:**
```bash
param teamName = 'lions'
param location = 'swedencentral'
param modelDeployments = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-5.4-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
```

### 5. Minimal LLM Service

**Best for:** Getting started quickly with just LLM access for testing and prototyping.

**Includes:**
- **Azure AI Foundry**: GPT-4o-mini deployment
- **No additional resources**: Keep costs minimal

**Example:** Proof of concept, API testing, learning

**Deployment:**
```bash
param teamName = 'hawks'
param location = 'swedencentral'
param modelDeployments = [
  {
    deploymentName: 'gpt-4o-mini'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
```

## Available Regions

Choose based on your location and latency requirements:

| Region | Code | Available Models |
|--------|------|------------------|
| Sweden Central | `swedencentral` | gpt-4o, gpt-4o-mini, gpt-5.4-mini, gpt-5.6-terra |
| West Europe | `westeurope` | gpt-4o, gpt-4o-mini, gpt-5.4-mini |
| East US | `eastus` | gpt-4o, gpt-4o-mini, gpt-5.4-mini, gpt-5.6-terra |

## Available Models

All models are available through Azure OpenAI deployments:

| Model | Version | Best For | Performance |
|-------|---------|----------|-------------|
| `gpt-4o` | 2026-03-17 | Complex reasoning, multi-step tasks | Highest quality |
| `gpt-4o-mini` | 2026-03-17 | General purpose, cost-effective | Good balance |
| `gpt-5.4-mini` | 2026-03-17 | Chatbots, fast responses | Fast + capable |
| `gpt-5.6-terra` | 2026-07-09 | Latest features, advanced tasks | Cutting edge |

## After Deployment

### 1. Get Your Endpoints

```bash
# Get all deployment outputs
DEPLOYMENT_NAME="hackathon-rbs2026-<teamname>"
az deployment sub show --name $DEPLOYMENT_NAME --query properties.outputs --output json
```

### 2. Configure Your Application

Create a `.env` file in your application root:

```env
# Azure AI Foundry
AZURE_OPENAI_ENDPOINT=https://foundry-rbs2026-<teamname>.openai.azure.com/
AZURE_OPENAI_API_KEY=<your-key>
AZURE_OPENAI_DEPLOYMENT_NAME=chat

# Storage
AZURE_STORAGE_ACCOUNT_NAME=st<teamname><hash>
AZURE_STORAGE_CONTAINER_NAME=documents

# Cosmos DB (if using)
AZURE_COSMOS_CONNECTION_STRING=<connection-string>

# Azure AI Search (if using)
AZURE_SEARCH_ENDPOINT=https://search-rbs2026-<teamname>.search.windows.net/
AZURE_SEARCH_API_KEY=<search-key>
```

### 3. Get API Keys

```bash
# Azure AI Foundry API key
az cognitiveservices account keys list \
  --name "foundry-rbs2026-<teamname>" \
  --resource-group "rg-hackathon-rbs2026-<teamname>" \
  --query key1 --output tsv

# Storage account connection string
az storage account show-connection-string \
  --name "st<teamname><hash>" \
  --resource-group "rg-hackathon-rbs2026-<teamname>"

# Azure AI Search API key
az search admin-key show \
  --resource-group "rg-hackathon-rbs2026-<teamname>" \
  --service-name "search-rbs2026-<teamname>"
```

### 4. Start Building

Use the starter code in `starters/` directory:
- `starters/python/` - Python client
- `starters/javascript/` - Node.js client
- `starters/java/` - Java client

## Cleanup

When you're done, delete your resource group:

```bash
# Delete everything
az group delete \
  --name "rg-hackathon-rbs2026-<teamname>" \
  --yes
```

Or use the Makefile:
```bash
DEPLOYMENT_NAME="hackathon-rbs2026-<teamname>" make destroy
```

## Troubleshooting

### Deployment fails with "Quota exceeded"

**Solution:** Your subscription may have reached quota limits. Contact the hackathon organizers.

### Cannot find resource after deployment

**Solution:** Ensure you're using the correct resource group name:
```bash
az group list --output table | grep hackathon
```

### API key authentication fails

**Solution:** Make sure you're using the correct endpoint and key:
```bash
# Verify endpoint
az deployment sub show --name "hackathon-rbs2026-<teamname>" \
  --query properties.outputs.foundryEndpoint.value

# Get fresh key
az cognitiveservices account keys list \
  --name "foundry-rbs2026-<teamname>" \
  --resource-group "rg-hackathon-rbs2026-<teamname>"
```

### Deployment takes too long

**Normal:** First deployment can take 5-15 minutes. Don't cancel it.

**Stuck:** If it's been >30 minutes, check the status:
```bash
az deployment sub show --name "hackathon-rbs2026-<teamname>" \
  --query properties.provisioningState
```

## Getting Help

1. **Check this guide** - Most issues are covered above
2. **Check Azure CLI docs** - `az --help` or online
3. **Contact organizers** - Slack/email with your team name and error

## Team Naming Convention

Team names must be:
- ✅ Lowercase letters and numbers only
- ✅ 2-12 characters long
- ❌ No spaces, underscores, or hyphens
- ❌ No uppercase letters

**Examples:**
- `panthers` ✅
- `team1` ✅
- `rai-team` ❌ (hyphens not allowed)
- `RAI_TEAM` ❌ (uppercase not allowed)
- `a` ❌ (too short)
- `verylongteamnamethatistoolong` ❌ (too long)

## Cost Estimation

Approximate monthly costs for each use case (minimum):

| Use Case | Foundry | Storage | Cosmos | Search | Total |
|----------|---------|---------|--------|--------|-------|
| RAG Assistant | $5 | $1 | $2 | $5 | ~$13 |
| Multi-Agent | $10 | $1 | $2 | — | ~$13 |
| Semantic Search | $5 | $1 | — | $5 | ~$11 |
| Chatbot | $5 | — | $2 | — | ~$7 |
| Minimal LLM | $5 | — | — | — | ~$5 |

*Note: Costs are approximate and will vary based on actual usage and request volume. Prices are per-region and per-tier.*

## Need a Different Configuration?

If none of the predefined use cases match your needs:

1. Create a custom parameter file: `infra/main-<teamname>.bicepparam`
2. Include any combination of:
   - `foundry.bicep` - Always included
   - `storage.bicep` - For document/artifact storage
   - `cosmos.bicep` - For session/state persistence
   - `search.bicep` - For vector/semantic retrieval

3. Deploy as normal

## More Information

- [Hackathon Project README](../README.md)
- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/)
- [Azure AI Search Documentation](https://learn.microsoft.com/en-us/azure/search/)
- [Azure Cosmos DB Documentation](https://learn.microsoft.com/en-us/azure/cosmos-db/)
