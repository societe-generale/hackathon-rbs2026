# Admin Guide: Resource Group Management

This guide is for hackathon administrators who manage Azure infrastructure.

## Architecture

This branch uses **resource-group scoped deployments**:
- **Admin:** Creates empty resource groups upfront
- **Teams:** Deploy their infrastructure into pre-assigned resource groups
- **Benefits:** Better control, easier cleanup, teams can't create resources outside their group

## Quick Start (Admin)

### Step 1: Create All Resource Groups

```bash
# Linux/Mac
bash admin/create-resource-groups.sh

# Windows
admin\create-resource-groups.bat
```

The script will:
- Verify your Azure login
- Create 11 resource groups: `rg-hackathon-rbs2026-uc1` through `rg-hackathon-rbs2026-uc11`
- Confirm all were created successfully

### Step 2: Share Resource Groups with Teams

Distribute to each team:
- Their assigned resource group name: `rg-hackathon-rbs2026-uc1`, etc.
- Link to `TEAM_GUIDE.md`

### Step 3: Monitor Deployments

```bash
# List all resource groups
az group list --query "[?contains(name, 'hackathon')].{name:name, location:location}" -o table

# Check deployment status
az deployment group show --name deploy-uc1 --resource-group rg-hackathon-rbs2026-uc1 --query properties.provisioningState

# Check resource creation in a group
az resource list --resource-group rg-hackathon-rbs2026-uc1 -o table
```

## Configuration

### Customize Resource Groups

Edit `admin/create-resource-groups.sh` (or `.bat`):

```bash
# Change these teams:
TEAMS=("uc1" "uc2" "uc3" "uc4" "uc5" "uc6" "uc7" "uc8" "uc9" "uc10" "uc11")

# Change location:
LOCATION="westeurope"
```

### Pre-configure Resource Groups (Optional)

Create resource groups with custom settings:

```bash
# Custom resource group with tags
az group create \
  --name rg-hackathon-rbs2026-uc1 \
  --location swedencentral \
  --tags project=hackathon team=uc1
```

## Cost Management

### Set Budget Alerts

```bash
# Alert if costs exceed $500/month
az costmanagement budget create \
  --budget-name "Hackathon-Budget" \
  --category "Cost" \
  --amount 500 \
  --time-period "Monthly" \
  --start-date 2026-03-01 \
  --notification-type Forecasted \
  --threshold 100 \
  --threshold-type Forecasted
```

### Monitor Usage

```bash
# View costs by resource group
az costmanagement query \
  --type "Usage" \
  --timeframe "MonthToDate" \
  --dataset '{"granularity":"Daily","aggregation":{"totalCost":{"name":"PreTaxCost","function":"Sum"}}}'
```

## Cleanup

### Delete All Resource Groups

```bash
# Delete everything
for i in {1..11}; do
  az group delete --name "rg-hackathon-rbs2026-uc$i" --yes --no-wait
done

# Monitor deletion progress
az group list --query "[?contains(name, 'hackathon')].{name:name, state:properties.provisioningState}" -o table
```

### Delete Specific Group

```bash
az group delete --name "rg-hackathon-rbs2026-uc1" --yes
```

## Troubleshooting

### Resource group creation fails

```bash
# Check your subscription quota
az account show --query "{subscription:id, displayName:name}"

# Verify you have permissions
az role assignment list --assignee $(az account show --query user.principalName -o tsv)
```

### Deployment fails in a resource group

```bash
# Check the deployment status
az deployment group list --resource-group "rg-hackathon-rbs2026-uc1" --output table

# Get detailed error
az deployment group show \
  --name deploy-uc1 \
  --resource-group rg-hackathon-rbs2026-uc1 \
  --query properties.error
```

### Teams can't deploy to their group

```bash
# Verify group exists and team has access
az group show --name rg-hackathon-rbs2026-uc1

# Grant team member access (if needed)
az role assignment create \
  --assignee <user-email> \
  --role "Contributor" \
  --resource-group rg-hackathon-rbs2026-uc1
```

## Team Handoff

### What to Give Teams

1. **Their resource group name:**
   ```
   rg-hackathon-rbs2026-uc1
   ```

2. **Deployment command:**
   ```bash
   cd infra-rg
   bash deploy.sh rg-hackathon-rbs2026-uc1 main-uc1.bicepparam
   ```

3. **Link to this repository** with `TEAM_GUIDE.md`

### What Teams Do

1. Copy parameter template: `cp main.bicepparam.template main-uc1.bicepparam`
2. Edit team name: `param teamName = 'uc1'`
3. Run deploy: `bash deploy.sh rg-hackathon-rbs2026-uc1 main-uc1.bicepparam`

## Advanced: Custom Team Configurations

### Different teams, different resources

Create variation templates:

```bash
# Limited: Only Foundry
cp infra-rg/main.bicepparam.template limited.bicepparam
# Edit to include only foundry module

# Full: All resources  
cp infra-rg/main.bicepparam.template full.bicepparam
# Edit to include all modules
```

### Pre-stage configurations

Create parameter files for each team before hackathon:

```bash
for i in {1..11}; do
  cp infra-rg/main.bicepparam.template infra-rg/main-uc$i.bicepparam
  sed -i "s/changeMe/uc$i/" infra-rg/main-uc$i.bicepparam
done
```

Then teams just run:
```bash
bash deploy.sh rg-hackathon-rbs2026-uc1 main-uc1.bicepparam
```

## Commands Reference

### Admin Commands

```bash
# Create resource groups
bash admin/create-resource-groups.sh

# List teams and status
az group list --query "[?contains(name, 'hackathon')].name" -o table

# Monitor specific team
az deployment group list --resource-group "rg-hackathon-rbs2026-uc1" -o table

# Get team resources
az resource list --resource-group "rg-hackathon-rbs2026-uc1" -o table

# Cleanup
az group delete --name "rg-hackathon-rbs2026-uc1" --yes
```

### Team Commands (they receive these)

```bash
# Deploy
bash deploy.sh rg-hackathon-rbs2026-uc1 main-uc1.bicepparam

# Get outputs
az deployment group show --name deploy-uc1 --resource-group rg-hackathon-rbs2026-uc1 --query properties.outputs

# Get API keys
az cognitiveservices account keys list \
  --name "foundry-rbs2026-uc1" \
  --resource-group rg-hackathon-rbs2026-uc1
```

## Files

```
admin/
├── create-resource-groups.sh      ← Admin: Create all RGs
└── create-resource-groups.bat     ← Admin: Windows version

infra-rg/
├── main.bicep                     ← Resource-group scoped template
├── main.bicepparam.template       ← Teams copy this
├── deploy.sh                      ← Team: Deploy script
├── deploy.bat                     ← Team: Windows version
├── foundry.bicep                  ← Shared modules
├── storage.bicep
├── cosmos.bicep
└── search.bicep
```

## See Also

- `TEAM_GUIDE.md` - Share with hackathon teams
- `infra/` - Subscription-scoped approach (alternative)
- Original README.md - Full project documentation
