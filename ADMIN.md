# Admin Guide: Resource Group Management

For hackathon administrators managing Azure infrastructure, cost, and team deployments.

**For team members?** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for deployment instructions.

---

## 🏗️ Deployment Architecture

### Approach 1: Subscription-Scoped (Self-Deploy)
Teams create their own resource groups. Simple, no admin overhead.
- **Teams:** Each creates their own resource group
- **Admin:** Just ensures everyone has subscription access
- **Cleanup:** Each team deletes their own group

### Approach 2: Resource-Group-Scoped (Pre-Created)
Admin creates groups upfront, teams deploy into them. Better control and governance.
- **Admin:** Creates all resource groups in advance
- **Teams:** Deploy infrastructure into pre-assigned groups
- **Cleanup:** Admin bulk-deletes all groups after hackathon
- **Benefits:** Ensure consistent naming, prevent resource sprawl, easier cost tracking

This guide covers both approaches.

---

## 🚀 Admin Setup (One-Time)

### Subscription-Scoped Approach
No setup needed! Just ensure teams have access:

```bash
# Verify your subscription
az login
az account show

# Share this with teams:
# - Subscription ID
# - Link to DEPLOYMENT_GUIDE.md
```

### Resource-Group-Scoped Approach
Create all resource groups upfront:

```bash
# Option 1: Using make
make admin-create-groups

# Option 2: Using script
bash admin/create-resource-groups.sh        # Linux/Mac
admin\create-resource-groups.bat            # Windows

# Option 3: Manually (for custom setup)
for i in {1..11}; do
  az group create \
    --name "rg-hackathon-rbs2026-uc$i" \
    --location swedencentral \
    --tags project=hackathon team=uc$i
done
```

---

## 📊 Monitor Deployments

### List All Resource Groups
```bash
# See all hackathon groups
az group list --query "[?contains(name, 'hackathon')].{name:name, location:location}" --output table

# Or using make
make list-teams
```

### Check Deployment Status
```bash
# One team
az deployment sub show \
  --name "hackathon-rbs2026-panthers" \
  --query properties.provisioningState

# All teams
az group list --query "[?contains(name, 'hackathon')].{name:name, status:properties.provisioningState}" --output table
```

### View Resources in a Group
```bash
# See what was deployed
az resource list \
  --resource-group "rg-hackathon-rbs2026-panthers" \
  --query "[].{name:name, type:type}" \
  --output table
```

### Monitor Specific Deployment
```bash
# Check what's happening right now
az deployment group operation list \
  --name deploy-panthers \
  --resource-group "rg-hackathon-rbs2026-panthers" \
  --query "[].properties" --output table

# Or check subscription-scoped deployment
az deployment sub operation list \
  --name "hackathon-rbs2026-panthers" \
  --query "[].properties" --output table
```

---

## 💰 Cost Management

### Set Budget Alerts
```bash
# Alert if costs exceed $500/month
az costmanagement budget create \
  --budget-name "Hackathon-Monthly-Budget" \
  --category "Cost" \
  --amount 500 \
  --time-period "Monthly" \
  --start-date 2026-03-01 \
  --notification-type "Forecasted" \
  --threshold 100
```

### Monitor Current Spend
```bash
# Get costs to date
az costmanagement query \
  --type "Usage" \
  --timeframe "MonthToDate" \
  --dataset '{"granularity":"Daily","aggregation":{"totalCost":{"name":"PreTaxCost","function":"Sum"}}}'
```

### View Costs by Resource Group
```bash
# See which teams are spending the most
az resource list \
  --resource-group "rg-hackathon-rbs2026-panthers" \
  --query "[].{name:name, type:type, id:id}" \
  --output table
```

---

## 🗑️ Cleanup

### Delete Single Resource Group
```bash
# Remove one team's resources
az group delete --name "rg-hackathon-rbs2026-panthers" --yes

# Using make
make deploy-to-group-destroy RG=rg-hackathon-rbs2026-panthers
```

### Delete All Resource Groups (Post-Hackathon)
```bash
# Option 1: Using make
make admin-destroy-all

# Option 2: Using Azure CLI
az group list \
  --query "[?contains(name, 'hackathon')].name" \
  --output tsv | xargs -I {} az group delete --name {} --yes --no-wait

# Monitor cleanup
az group list --query "[?contains(name, 'hackathon')].{name:name, status:properties.provisioningState}" --output table
```

---

## 👥 Team Handoff

### What to Give Each Team (Subscription-Scoped)
1. **Subscription ID:** `az account show --query id --output tsv`
2. **Link to guide:** Point to [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
3. **Sample command:**
   ```bash
   make deploy TEAM=panthers
   ```

### What to Give Each Team (Resource-Group-Scoped)
1. **Their resource group name:** `rg-hackathon-rbs2026-uc1`
2. **Link to guide:** Point to [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
3. **Sample command:**
   ```bash
   make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1
   ```

### What Teams Do
1. Copy parameter template: `cp infra/main.bicepparam infra/main-uc1.bicepparam`
2. Edit team name: `param teamName = 'uc1'`
3. Run deployment: `make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1`
4. Get endpoints: `make deploy-to-group-outputs TEAM=uc1 RG=rg-hackathon-rbs2026-uc1`

---

## 🎯 Advanced Configurations

### Pre-Configure Parameter Files
Create customized parameter files for each team before the hackathon:

```bash
#!/bin/bash
# Script to pre-stage all team configurations

TEAMS=("uc1" "uc2" "uc3" "uc4" "uc5" "uc6" "uc7" "uc8" "uc9" "uc10" "uc11")

for team in "${TEAMS[@]}"; do
    cat > "infra/main-${team}.bicepparam" << EOF
using './main.bicep'

param teamName = '$team'
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
EOF
done

echo "Created parameter files for all teams"
```

Then teams just run:
```bash
make deploy TEAM=uc1
```

### Custom Use Cases per Team
Create variations for different team needs:

```bash
# Limited: Only Foundry (low cost)
cat > infra/main-limited.bicepparam << EOF
param teamName = 'limited-team'
param location = 'swedencentral'
param modelDeployments = [{...}]
# Set other resources to disabled
EOF

# Full: All resources (maximum capability)
cat > infra/main-full.bicepparam << EOF
param teamName = 'full-team'
param location = 'swedencentral'
param modelDeployments = [{...}]
# Enable all resources
EOF
```

### Batch Deployments
Deploy infrastructure for all teams at once:

```bash
#!/bin/bash
# Deploy all teams in parallel

for i in {1..11}; do
    make deploy-to-group TEAM=uc$i RG=rg-hackathon-rbs2026-uc$i &
done
wait

echo "All deployments complete"
```

---

## 🔧 Commands Reference

### Admin (Subscription-Scoped)
```bash
# Create groups (if using resource-group-scoped)
make admin-create-groups

# List all teams
make list-teams

# Monitor all deployments
az group list --query "[?contains(name, 'hackathon')].{name:name, status:properties.provisioningState}" --output table

# Cleanup all
make admin-destroy-all
```

### Team (Subscription-Scoped)
```bash
# Deploy
make deploy TEAM=panthers

# Preview
make deploy-validate TEAM=panthers

# Get outputs
make deploy-outputs TEAM=panthers

# Cleanup
make deploy-destroy TEAM=panthers
```

### Team (Resource-Group-Scoped)
```bash
# Deploy to assigned resource group
make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1

# Preview
make deploy-to-group-validate TEAM=uc1 RG=rg-hackathon-rbs2026-uc1

# Get outputs
make deploy-to-group-outputs TEAM=uc1 RG=rg-hackathon-rbs2026-uc1

# Cleanup
make deploy-to-group-destroy RG=rg-hackathon-rbs2026-uc1
```

### Manual Azure CLI
```bash
# List resource groups
az group list --query "[].name" --output table

# Get deployment status
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.provisioningState

# Get deployment outputs
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.outputs --output json

# Get resource list
az resource list --resource-group "rg-hackathon-rbs2026-<team>" --output table

# Delete group
az group delete --name "rg-hackathon-rbs2026-<team>" --yes
```

---

## ❌ Troubleshooting

### Resource group creation fails
```bash
# Check subscription quota
az account show --query "{subscription:id, displayName:name}"

# Check your permissions
az role assignment list --assignee $(az account show --query user.principalName -o tsv)
```

### Team can't deploy to their resource group
```bash
# Verify group exists
az group show --name "rg-hackathon-rbs2026-uc1"

# Grant team member access
az role assignment create \
  --assignee "<user-email>" \
  --role "Contributor" \
  --resource-group "rg-hackathon-rbs2026-uc1"
```

### Deployment fails with "Quota exceeded"
```bash
# Check current quota usage
az provider show --namespace Microsoft.CognitiveServices \
  --query "registrationState"

# Request quota increase through Azure portal:
# Home → Subscriptions → Usage + quotas
```

### Deployment stuck for >30 minutes
```bash
# Check status
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.provisioningState

# Check error details
az deployment sub show --name "hackathon-rbs2026-<team>" \
  --query properties.error --output json
```

### Can't delete resource group
```bash
# Check for locks
az group lock list --resource-group "rg-hackathon-rbs2026-uc1"

# Remove lock if needed
az group lock delete \
  --name "<lock-name>" \
  --resource-group "rg-hackathon-rbs2026-uc1"

# Then delete group
az group delete --name "rg-hackathon-rbs2026-uc1" --yes
```

---

## 📋 Pre-Hackathon Checklist

- [ ] Create Azure subscription for hackathon
- [ ] Verify subscription access for admin team
- [ ] Decide on deployment approach (subscription-scoped vs resource-group-scoped)
- [ ] If resource-group-scoped: Pre-create all resource groups
- [ ] Test deployment with a sample team
- [ ] Pre-stage parameter files (optional but recommended)
- [ ] Set up budget alerts
- [ ] Create communication channel for infrastructure support
- [ ] Document team names and resource group assignments
- [ ] Prepare cleanup script for post-hackathon

---

## 📞 Getting Help

1. **Check this guide** - Most admin issues are covered above
2. **Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - For team-level details
3. **Azure CLI docs** - `az --help` or https://learn.microsoft.com/cli/azure/
4. **Azure Bicep docs** - https://learn.microsoft.com/azure/azure-resource-manager/bicep/

---

## 📚 Reference

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Team-level deployment instructions
- [README.md](README.md) - Developer setup and getting started
- [Azure CLI Documentation](https://learn.microsoft.com/cli/azure/)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
