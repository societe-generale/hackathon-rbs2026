# Quick Start: Deploy Your Resource Group

## 30-Second Setup

1. **Copy the template parameter file:**
   ```bash
   cp infra/main.bicepparam.template infra/main-<teamname>.bicepparam
   ```

2. **Edit with your team name:**
   ```bash
   # Edit infra/main-<teamname>.bicepparam
   # Change: param teamName = 'changeMe'
   # To:     param teamName = 'panthers'  (your team name)
   ```

3. **Deploy:**
   ```bash
   # Linux/Mac
   bash infra/deploy.sh infra/main-<teamname>.bicepparam
   
   # Windows
   infra\deploy.bat infra\main-<teamname>.bicepparam
   ```

That's it! The script guides you through the rest.

---

## What You Get

All resources in your own resource group: `rg-hackathon-rbs2026-<teamname>`

- ✅ **Azure AI Foundry** - LLM access
- ✅ **Storage Account** - Document storage  
- ✅ **Cosmos DB** - State & history persistence
- ✅ **Azure AI Search** - Vector search
- ✅ Custom resource names automatically derived from your team name

---

## Customizing Your Parameters

Edit `infra/main-<teamname>.bicepparam`:

```bicep
param teamName = 'panthers'           # Your team name

param location = 'swedencentral'      # Region: swedencentral, westeurope, eastus

# Add more models if needed
param modelDeployments = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
  # Add another model:
  # {
  #   deploymentName: 'analysis'
  #   modelName: 'gpt-4o'
  #   modelVersion: '2026-03-17'
  #   skuName: 'GlobalStandard'
  #   capacity: 1
  # }
]
```

---

## Commands

**Deploy:**
```bash
bash infra/deploy.sh infra/main-panthers.bicepparam
```

**Monitor deployment:**
```bash
az deployment sub show --name hackathon-rbs2026-panthers --query properties.provisioningState
```

**Get your endpoints:**
```bash
az deployment sub show --name hackathon-rbs2026-panthers --query properties.outputs -o json
```

**Delete when done:**
```bash
az group delete --name rg-hackathon-rbs2026-panthers --yes
```

---

## Templates and Examples

**Single model deployment:**
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

**Multi-model deployment:**
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

---

## Available Models

- `gpt-4o` - Best quality, for complex reasoning
- `gpt-4o-mini` - Great balance of quality and speed
- `gpt-5.4-mini` - Fast, optimized for chatbots
- `gpt-5.6-terra` - Latest features (regional availability varies)

All available in swedencentral and eastus. Check Azure docs for regional availability.

---

## Getting Help

1. Check your parameter file syntax matches `main.bicepparam.template`
2. Ensure `teamName` is lowercase, 2-12 characters
3. Run the deploy script - it will tell you what's wrong
4. Check Azure CLI docs: `az --help`

---

## See Also

- `DEPLOYMENT_GUIDE.md` - Detailed deployment guide
- `ORGANIZER_GUIDE.md` - For hackathon coordinators  
- `starters/` - Example code in Python, JavaScript, Java
