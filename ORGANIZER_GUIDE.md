# Hackathon Organizer Guide: Providing Resource Groups to Teams

This guide explains how to distribute the resource group deployment process to your hackathon teams.

## Overview

Each team gets their own Azure resource group with pre-configured infrastructure. The deployment process is:
1. **Team selects their use case** (RAG assistant, chatbot, etc.)
2. **Team runs a deployment script** (interactive wizard)
3. **Infrastructure is deployed** in ~5-15 minutes
4. **Team gets their endpoints** and can start building immediately

## For Hackathon Organizers

### Step 1: Create an Azure Subscription for the Hackathon

```bash
# You should already have a dedicated subscription for the hackathon
# Example: "Hackathon-RBS2026-Teams"

# Verify the subscription
az account list --output table | grep Hackathon
```

### Step 2: Share These Resources with Teams

Provide teams with:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/societe-generale/hackathon-rbs2026
   cd hackathon-rbs2026
   ```

2. **Use Case Guide** - Point them to: `DEPLOYMENT_GUIDE.md`

3. **Deployment Script** - Located at: `infra/deploy.sh` (Linux/Mac) or `infra/deploy.bat` (Windows)

### Step 3: Brief Your Teams

Share this quick overview with each team:

```
🚀 Hackathon Infrastructure Setup

Your team will each get your own Azure resource group with:
- Azure AI Foundry (LLM access)
- Plus additional services based on your use case

⏱️  Setup takes ~5 minutes (+ 5-15 min for deployment)

📋 What You Need:
1. Clone: git clone https://github.com/societe-generale/hackathon-rbs2026
2. Navigate: cd infra
3. Run: 
   - Linux/Mac: bash deploy.sh
   - Windows: deploy.bat

🎯 The script will guide you through:
- Selecting your use case
- Choosing a region
- Picking a team name
- Deploying your infrastructure
- Getting your resource endpoints

💡 Questions? Check DEPLOYMENT_GUIDE.md or contact organizers
```

### Step 4: Provide Pre-Configured Parameter Files (Optional)

If you want to pre-define some configurations:

**Option A: Provide starter parameter files**

```bash
# Create in infra/ directory:
infra/main-usecase-rag.bicepparam
infra/main-usecase-chatbot.bicepparam
infra/main-usecase-minimal.bicepparam
```

Teams can then copy and customize.

**Option B: Provide a preset selection**

Modify `infra/use-cases.json` to only show relevant use cases for your hackathon.

### Step 5: Monitor Deployments

Track team deployments:

```bash
# List all resource groups in the subscription
az group list --query "[].name" --output table | grep hackathon

# Monitor a specific team's deployment
az deployment sub show \
  --name "hackathon-rbs2026-<teamname>" \
  --query "{status: properties.provisioningState, duration: properties.duration}"

# List all deployment operations for a team
az deployment sub operation list \
  --name "hackathon-rbs2026-<teamname>" \
  --output table
```

### Step 6: Managing Costs

**Set up budget alerts:**

```bash
# Create a budget alert for the hackathon subscription
az costmanagement budget create \
  --budget-name "Hackathon-Daily-Budget" \
  --category "Cost" \
  --amount 500 \
  --time-period "Monthly" \
  --start-date $(date +%Y-%m-01) \
  --resource-group "Hackathon-RBS2026"
```

**Cleanup after hackathon:**

```bash
# Delete all hackathon resource groups
az group list --query "[?contains(name, 'hackathon')].name" -o tsv | \
  xargs -I {} az group delete --name {} --yes --no-wait

# Monitor cleanup progress
az group list --query "[?contains(name, 'hackathon')].{name:name, state:properties.provisioningState}" -o table
```

## Customizing the Deployment for Your Hackathon

### Scenario 1: All Teams Use the Same Use Case

Edit `infra/use-cases.json` to include only your use case, or modify the deployment script to skip selection.

### Scenario 2: Teams Have Different Quotas

The bicep templates support custom capacity parameters. Create variations:

```bicepparam
# main-enterprise.bicepparam - for high-demand teams
param modelDeployments = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-4o'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 5  # Higher capacity
  }
]

# main-startup.bicepparam - for low-demand teams
param modelDeployments = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1  # Standard capacity
  }
]
```

### Scenario 3: Centralized Deployment by Organizers

If you want to deploy all resource groups yourself:

```bash
#!/bin/bash
# deploy-all-teams.sh

TEAMS=("panthers" "tigers" "eagles" "lions" "hawks")
REGION="swedencentral"

for team in "${TEAMS[@]}"; do
    echo "Deploying for team: $team"
    
    # Create parameter file
    cat > "infra/main-${team}.bicepparam" << EOF
using './main.bicep'
param teamName = '$team'
param location = '$REGION'
param modelDeployments = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
EOF

    # Deploy
    az deployment sub create \
        --name "hackathon-rbs2026-${team}" \
        --location "$REGION" \
        --template-file infra/main.bicep \
        --parameters "infra/main-${team}.bicepparam"
done
```

## Team Communication Templates

### Pre-Hackathon Email

Subject: 🚀 Get Your Azure Resource Group Ready

```
Hi Team,

Your Azure infrastructure for the hackathon is ready to deploy!

📦 What you get:
- Azure AI Foundry (LLM access)
- Specialized resources for your use case
- ~5 minutes to deploy

🎯 Quick Start:
1. git clone https://github.com/societe-generale/hackathon-rbs2026
2. cd infra
3. bash deploy.sh  (or deploy.bat on Windows)

📚 Full Guide: DEPLOYMENT_GUIDE.md in the repository

⏰ Expected deployment time: 5-15 minutes

Got stuck? Check the troubleshooting section or ping us on Slack!

Let's build something amazing! 🎉
```

### During Hackathon (Deployment Help)

```
💬 Resource Group Deployment Help

Having trouble with deployment?

Common Issues:
❌ "az: command not found"
   → Install Azure CLI: https://aka.ms/azure-cli

❌ "Not authenticated"
   → Run: az login

❌ "Deployment still running after 30 mins"
   → This is normal for first deployment. Monitor with:
   → az deployment sub show --name hackathon-rbs2026-<teamname> --query properties.provisioningState

❌ Different error?
   → Share the error message and team name in #hackathon-help

📞 Support available on Slack during: [hours]
```

### Post-Deployment Confirmation

```
✅ Your resource group is ready!

Resource Group: rg-hackathon-rbs2026-<teamname>

🔑 Next Steps:
1. Get your API endpoints:
   az deployment sub show --name hackathon-rbs2026-<teamname> --query properties.outputs

2. Create .env file in your app:
   AZURE_OPENAI_ENDPOINT=...
   AZURE_OPENAI_API_KEY=...

3. Start coding!

Need help? Check starters/ for example code in Python
```

## Monitoring Dashboard (Optional)

Create a simple monitoring script:

```bash
#!/bin/bash
# monitor-deployments.sh

echo "🔍 Hackathon Deployment Status"
echo "================================"
echo ""

# Get all hackathon resource groups
GROUPS=$(az group list --query "[?contains(name, 'hackathon')].name" -o tsv)

echo "Resource Groups: $(echo $GROUPS | wc -w)"
echo ""

# Show status of each
az group list --query "[?contains(name, 'hackathon')].{Team:name, Status:properties.provisioningState}" -o table

echo ""
echo "Estimated Monthly Costs:"
az costmanagement query --type "Usage" --timeframe "MonthToDate" \
  --dataset "{granularity:'Monthly',aggregation:{totalCost:{name:'PreTaxCost',function:'Sum'}}}" \
  --filter "properties/dimensions/name eq 'ResourceGroup' and ... contains 'hackathon'" || \
  echo "(Cost data updating...)"
```

## Troubleshooting for Organizers

### Problem: Teams can't see each other's resources

**This is expected** - Each team has their own resource group. They cannot access other teams' resources.

### Problem: One team keeps exhausting quota

**Solution:**
```bash
# Check that team's quota usage
az deployment sub show --name "hackathon-rbs2026-<teamname>" \
  --query properties.deploymentProperties

# Increase their quota (if supported in your subscription)
az provider update --namespace Microsoft.CognitiveServices --registration
```

### Problem: Cleanup failed for some teams

```bash
# Force delete a resource group
az group delete --name "rg-hackathon-rbs2026-<teamname>" --yes --no-wait

# Check for lock
az group lock list --resource-group "rg-hackathon-rbs2026-<teamname>"
az group lock delete --name "lock-name" -g "rg-hackathon-rbs2026-<teamname>"
```

### Problem: Bills from teams not cleaning up

```bash
# Set up automatic cleanup after hackathon date
# Using Azure Automation or scheduled task

# List all resource groups with last modified time
az group list --query "[?contains(name, 'hackathon')].{name:name, created:managedBy}" -o table
```

## Advanced: CI/CD Integration

Automatically deploy team resource groups:

```yaml
# .github/workflows/deploy-team.yml
name: Deploy Team Infrastructure

on:
  workflow_dispatch:
    inputs:
      teamName:
        description: 'Team Name'
        required: true
      useCase:
        description: 'Use Case'
        required: true
        type: choice
        options:
          - rag-assistant
          - multi-agent-orchestrator
          - semantic-search
          - stateful-chatbot
          - minimal-llm

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy
        run: |
          cd infra
          # Create parameter file based on use case
          # Run deployment
```

## Checklist for Organizers

- [ ] Create Azure subscription
- [ ] Verify subscription access for your team
- [ ] Test deployment script with a sample team
- [ ] Copy DEPLOYMENT_GUIDE.md to your internal wiki/docs
- [ ] Create Slack channel for #hackathon-infrastructure-help
- [ ] Send pre-hackathon email to teams
- [ ] Have backup plan if Azure service goes down
- [ ] Set up cost monitoring/alerts
- [ ] Prepare cleanup script for post-hackathon
- [ ] Document any custom configurations for your hackathon

## Questions?

For detailed deployment instructions, see: `DEPLOYMENT_GUIDE.md`
For bicep template details, see: `infra/README.md` (if present)
For Azure documentation: https://learn.microsoft.com/en-us/azure/
