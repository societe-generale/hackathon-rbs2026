# Makefile Quick Reference: Resource Group Deployment

All deployment workflows use simple `make` commands. No platform-specific scripts needed!

## Quick Start

### Show all available commands:
```bash
make help
```

### Authenticate:
```bash
make login
make azure-account    # Verify you're logged in
```

---

## Subscription-Scoped (Teams Self-Deploy)

Teams create their own resource groups. Simple workflow for each team.

### Team 1: Deploy
```bash
# First time: creates parameter file and exits (for review)
make deploy TEAM=panthers

# Edit infra/main-panthers.bicepparam if needed

# Run again: deploys the infrastructure
make deploy TEAM=panthers
```

### Team 1: Get outputs
```bash
make deploy-outputs TEAM=panthers
```

### Team 1: Preview before deploying
```bash
make deploy-validate TEAM=panthers
```

### Team 1: Cleanup
```bash
make deploy-destroy TEAM=panthers
```

---

## Resource-Group-Scoped (Admin + Teams)

Admin creates groups upfront, teams deploy to pre-assigned groups.

### Admin: One-time setup
```bash
# Create all 11 resource groups
make admin-create-groups

# Optional: Verify they were created
make admin-list-groups

# Optional: Monitor deployments
make admin-monitor
```

### Admin: Cleanup everything (after hackathon)
```bash
make admin-destroy-all
```

### Team 1: Deploy to assigned resource group
```bash
# First time: creates parameter file and exits
make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1

# Edit infra-rg/main-uc1.bicepparam if needed

# Run again: deploys infrastructure
make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1
```

### Team 1: Preview before deploying
```bash
make deploy-to-group-validate TEAM=uc1 RG=rg-hackathon-rbs2026-uc1
```

### Team 1: Get outputs
```bash
make deploy-to-group-outputs TEAM=uc1 RG=rg-hackathon-rbs2026-uc1
```

### Team 1: Cleanup
```bash
make deploy-to-group-destroy RG=rg-hackathon-rbs2026-uc1
```

---

## Common Admin Commands

```bash
# List all active hackathon resource groups
make list-teams

# Monitor deployments in a specific group
make admin-monitor GROUP=rg-hackathon-rbs2026-uc1

# Create just one resource group
az group create --name rg-hackathon-rbs2026-custom --location swedencentral
```

---

## Examples

### Scenario 1: Team "panthers" deploys (subscription-scoped)
```bash
make deploy TEAM=panthers
# Creates and deploys rg-hackathon-rbs2026-panthers
```

### Scenario 2: Admin setup + Team "uc1" deploys (resource-group-scoped)
```bash
# Admin (1 time)
make admin-create-groups
# Creates rg-hackathon-rbs2026-uc1 through uc11

# Team uc1
make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1
# Deploys infrastructure into existing RG
```

### Scenario 3: Team customization
```bash
# Auto-creates parameter file first time
make deploy TEAM=tigers

# Edit the file
nano infra/main-tigers.bicepparam

# Deploy with custom settings
make deploy TEAM=tigers
```

---

## Parameter File Management

Makefile automatically:
- ✅ Creates parameter files from template on first run
- ✅ Leaves existing files untouched (safe for edits)
- ✅ Stores subscription-scoped params in `infra/main-*.bicepparam`
- ✅ Stores resource-group-scoped params in `infra-rg/main-*.bicepparam`

Clean up generated files:
```bash
make clean
```

---

## Windows Users

All commands work on Windows with:
- **WSL 2 + Bash** (recommended)
- **Git Bash**
- **Windows Subsystem for Linux**

Or use Azure Cloud Shell directly (no local setup needed).

---

## Available Make Targets

### Authentication
- `make login` - Sign in to Azure
- `make azure-account` - Show current account/subscription

### Subscription-Scoped (infra/)
- `make deploy TEAM=<name>` - Deploy (creates param file on first run)
- `make deploy-validate TEAM=<name>` - Preview changes
- `make deploy-outputs TEAM=<name>` - Get deployment endpoints
- `make deploy-destroy TEAM=<name>` - Delete resource group

### Resource-Group-Scoped (infra-rg/)
- `make admin-create-groups` - Create all 11 RGs
- `make admin-list-groups` - List all RGs
- `make admin-monitor [GROUP=...]` - Monitor deployments
- `make admin-destroy-all` - Delete all RGs
- `make deploy-to-group TEAM=<name> RG=<rg>` - Deploy to RG
- `make deploy-to-group-validate TEAM=<name> RG=<rg>` - Preview
- `make deploy-to-group-outputs TEAM=<name> RG=<rg>` - Get outputs
- `make deploy-to-group-destroy RG=<rg>` - Delete RG

### Utilities
- `make help` - Show all targets with descriptions
- `make list-teams` - List all hackathon resource groups
- `make clean` - Remove generated parameter files
- `make validate` - Validate Bicep template

---

## Tips

**Pro tip 1: Create a shell alias**
```bash
alias hc="make"
hc help
hc deploy TEAM=panthers
```

**Pro tip 2: Use environment variables**
```bash
export TEAM=panthers
export RG=rg-hackathon-rbs2026-panthers
make deploy TEAM=$TEAM
make deploy-to-group TEAM=$TEAM RG=$RG
```

**Pro tip 3: Batch operations (admin)**
```bash
# Deploy all teams at once
for i in {1..11}; do
  make deploy-to-group TEAM=uc$i RG=rg-hackathon-rbs2026-uc$i &
done
wait
```

---

## Troubleshooting

### "Command not found: make"
Install `make`:
- **Ubuntu/Debian:** `sudo apt-get install make`
- **macOS:** `brew install make`
- **Windows:** Use WSL 2, Git Bash, or Cloud Shell

### "Azure CLI not found"
Install Azure CLI: https://aka.ms/azure-cli

### Makefile not found
Make sure you're in the repository root directory:
```bash
cd hackathon-rbs2026
make help
```

### Parameter file already exists
The Makefile protects existing parameter files. To regenerate:
```bash
make clean
make deploy TEAM=panthers  # Creates new file
```

---

## See Also

- `ADMIN_GUIDE.md` - Detailed admin documentation
- `TEAM_GUIDE.md` - Detailed team documentation
- `Makefile` - View all available targets and implementation
