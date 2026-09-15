# Team Guide: Deploy to Your Resource Group

This guide explains how to deploy your infrastructure to your assigned Azure resource group.

## Prerequisites

- **Azure CLI** installed: https://aka.ms/azure-cli
- **Access to Azure** (login credentials)
- **Your assigned resource group name** (e.g., `rg-hackathon-rbs2026-uc1`)
- This repository cloned

## Quick Start (3 steps)

### Step 1: Copy the Parameter Template

```bash
cd infra-rg
cp main.bicepparam.template main-<yourteam>.bicepparam
```

### Step 2: Edit Your Parameters

Edit `main-<yourteam>.bicepparam`:

```bicep
# Change this:
param teamName = 'changeMe'

# To this:
param teamName = 'uc1'  # or your assigned team name

# Optionally customize:
param location = 'swedencentral'  # or westeurope, eastus

param modelDeployments = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-4o-mini'        # Choose your model
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
```

### Step 3: Deploy

```bash
# Linux/Mac
bash deploy.sh rg-hackathon-rbs2026-uc1 main-uc1.bicepparam

# Windows
deploy.bat rg-hackathon-rbs2026-uc1 main-uc1.bicepparam
```

The script will:
1. ✅ Verify your resource group exists
2. ✅ Validate your parameters
3. ✅ Show what will be created
4. ✅ Ask for confirmation
5. ✅ Deploy your infrastructure
6. ✅ Show your endpoints

**Expected time:** 2 minutes setup + 5-15 minutes deployment

## What You Get

Inside your resource group (`rg-hackathon-rbs2026-<team>`):

| Resource | Type | Purpose |
|----------|------|---------|
| `foundry-rbs2026-<team>` | Azure AI Foundry | LLM endpoint for your app |
| `st<team><hash>` | Storage Account | Document and artifact storage |
| `cosmos-rbs2026-<team>` | Cosmos DB | Chat history & state persistence |
| `search-rbs2026-<team>` | Azure AI Search | Vector & semantic search |

All resource names are automatically derived from your team name.

## Available Models

Choose the model that fits your use case:

| Model | Best For | Speed | Quality |
|-------|----------|-------|---------|
| `gpt-4o-mini` | General purpose, cost-effective | Fast | High |
| `gpt-4o` | Complex reasoning | Medium | Highest |
| `gpt-5.4-mini` | Chatbots, fast responses | Fastest | High |
| `gpt-5.6-terra` | Latest features | Medium | Cutting edge |

Check Azure docs for regional availability.

## Multi-Model Deployment

Deploy multiple models in one go:

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

Then call different deployments in your code:
```python
# Use orchestrator for main logic
client.create_deployment(deployment_name='orchestrator', ...)

# Use worker for helper tasks
client.create_deployment(deployment_name='worker', ...)
```

## After Deployment

### Get Your Endpoints

The script saves outputs to `outputs-<team>.json`. View anytime:

```bash
az deployment group show \
  --name deploy-uc1 \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --query properties.outputs \
  --output json
```

### Configure Your Application

Create `.env` in your app:

```env
# From deployment outputs:
AZURE_OPENAI_ENDPOINT=https://foundry-rbs2026-uc1.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME=chat
AZURE_OPENAI_API_KEY=<your-key>

# Get this:
AZURE_STORAGE_ACCOUNT=st<team><hash>
AZURE_COSMOS_CONNECTION_STRING=<from-outputs>
AZURE_SEARCH_ENDPOINT=https://search-rbs2026-uc1.search.windows.net/
AZURE_SEARCH_API_KEY=<your-key>
```

### Get API Keys

```bash
# OpenAI Foundry key
az cognitiveservices account keys list \
  --name "foundry-rbs2026-uc1" \
  --resource-group "rg-hackathon-rbs2026-uc1" \
  --query "key1" -o tsv

# Azure Search key
az search admin-key show \
  --resource-group "rg-hackathon-rbs2026-uc1" \
  --service-name "search-rbs2026-uc1"

# Storage connection string
az storage account show-connection-string \
  --name "st<team><hash>" \
  --resource-group "rg-hackathon-rbs2026-uc1"
```

### Start Coding

See example starters:
- `starters/python/` - Python client
- `starters/javascript/` - JavaScript/Node.js
- `starters/java/` - Java client

## Customization

### Change Resource Names

Edit parameter file (uncomment to customize):

```bicep
// Override default names
param foundryName = 'my-custom-foundry'
param storageAccountName = 'mystorageaccount'
param cosmosAccountName = 'my-cosmos'
param searchServiceName = 'my-search'
```

### Add Custom Tags

```bicep
param tags = {
  environment: 'dev'
  project: 'hackathon-rbs2026'
  team: teamName
  costCenter: 'engineering'
  owner: 'your-name@company.com'
}
```

### Control Network Access

```bicep
// Restrict to private endpoints
param publicNetworkAccess = 'Disabled'
```

## Monitoring

### Check Deployment Status

```bash
az deployment group show \
  --name deploy-uc1 \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --query properties.provisioningState
```

### View All Resources in Your Group

```bash
az resource list \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --output table
```

### Monitor Costs

```bash
# View resources and their types
az resource list \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --query "[].{name:name, type:type}" \
  --output table
```

## Troubleshooting

### "Resource group not found"

```bash
# Check your resource group name
az group list --query "[?contains(name, 'hackathon')].name" -o table

# Verify the exact name
az group show --name rg-hackathon-rbs2026-uc1
```

### "Parameter file not found"

Make sure you're in the right directory:
```bash
cd infra-rg
ls -la main*.bicepparam*
```

### Parameter validation fails

Check your `.bicepparam` file:
- `teamName` must be lowercase, 2-12 chars
- `location` must be: swedencentral, westeurope, eastus
- `modelDeployments` must be valid JSON/Bicep array

### Deployment times out

Normal deployments take 5-15 minutes. If stuck >30 mins:
```bash
# Check what's happening
az deployment group operation list \
  --name deploy-uc1 \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --query "[].properties" \
  --output table
```

### Can't access resource after deployment

```bash
# Verify role assignment
az role assignment list \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --assignee $(az account show --query user.principalName -o tsv)

# You should have "Owner" or "Contributor" role
```

## Cleanup

When you're done:

```bash
# Delete all resources in your group (keeps the group)
az resource delete \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --confirm-delete-all-resources

# Or delete the entire group (one command, slower)
az group delete \
  --name rg-hackathon-rbs2026-uc1 \
  --yes
```

## Commands Reference

```bash
# Deploy
bash deploy.sh rg-hackathon-rbs2026-uc1 main-uc1.bicepparam

# Check status
az deployment group show --name deploy-uc1 --resource-group rg-hackathon-rbs2026-uc1 --query properties.provisioningState

# Get outputs
az deployment group show --name deploy-uc1 --resource-group rg-hackathon-rbs2026-uc1 --query properties.outputs -o json

# List resources
az resource list --resource-group rg-hackathon-rbs2026-uc1 -o table

# Get API keys
az cognitiveservices account keys list --name foundry-rbs2026-uc1 --resource-group rg-hackathon-rbs2026-uc1

# Delete resources
az group delete --name rg-hackathon-rbs2026-uc1 --yes
```

## Getting Help

1. **Check this guide** - Most issues are covered
2. **Run deploy script** - It will tell you what's wrong
3. **Check Azure docs** - https://learn.microsoft.com/azure/
4. **Ask organizers** - Contact via Slack/email with your error

## Parameters File Example

Complete example with all options:

```bicep
using './main.bicep'

// Team identifier (must match your resource group)
param teamName = 'uc1'

// Region (must match resource group location)
param location = 'swedencentral'

// Models to deploy
param modelDeployments = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
  {
    deploymentName: 'analysis'
    modelName: 'gpt-4o'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]

// Custom resource names (optional)
param foundryName = 'foundry-rbs2026-uc1'
param foundryProjectName = 'rbs2026-uc1'

// Custom tags (optional)
param tags = {
  environment: 'dev'
  project: 'hackathon-rbs2026'
  team: 'uc1'
  owner: 'uc1-team@company.com'
}
```

## See Also

- `ADMIN_GUIDE.md` - For hackathon administrators
- `README.md` - Full project documentation
- `starters/` - Example code in multiple languages
