## Makefile for Hackathon Resource Group Deployment
##
## Deployment model:
##   - Admin: Deploy at subscription level (creates resource groups)
##   - Teams: Deploy at resource group level (into pre-existing groups)
##
## Usage:
##   make help                           # Show all targets
##   make login                          # Sign in to Azure
##   make admin-create-groups            # Admin: Create all 11 RGs
##   make deploy TEAM=uc1 RG=rg-hackathon-rbs2026-uc1  # Team: Deploy to RG

SHELL := /bin/bash

# Configuration
LOCATION ?= swedencentral
DEPLOYMENT_NAME ?= hackathon-rbs2026

# Team deployment (resource-group-scoped)
INFRA_DIR := infra
TEMPLATE_FILE := $(INFRA_DIR)/main.bicep

# Admin deployment (subscription-scoped)
ADMIN_DIR := admin
ADMIN_TEMPLATE_FILE := $(ADMIN_DIR)/main.bicep

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
NC := \033[0m

.PHONY: help
help: ## Show all available targets
	@echo "$(BLUE)Hackathon Resource Group Deployment$(NC)"
	@echo ""
	@echo "$(BLUE)Authentication:$(NC)"
	@grep -E '^  login|^  azure-account' $(MAKEFILE_LIST) | grep '##' | awk 'BEGIN {FS = ":.*?## "}; {printf "    %-30s %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Admin (subscription-level, admin/):$(NC)"
	@grep -E '^  admin-' $(MAKEFILE_LIST) | grep '##' | awk 'BEGIN {FS = ":.*?## "}; {printf "    %-30s %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Teams (resource-group-level, infra/):$(NC)"
	@grep -E '^  deploy|^  deploy-validate|^  deploy-outputs|^  deploy-destroy' $(MAKEFILE_LIST) | grep '##' | awk 'BEGIN {FS = ":.*?## "}; {printf "    %-30s %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "    make login"
	@echo "    make admin-create-groups                     # Step 1: Admin creates RGs"
	@echo "    make deploy TEAM=uc1 RG=rg-hackathon-rbs2026-uc1  # Step 2: Team deploys"

# ============================================================================
# AUTHENTICATION
# ============================================================================

.PHONY: login
login: ## Sign in to Azure (interactive)
	az login --use-device-code

.PHONY: azure-account
azure-account: ## Show current Azure account and subscription
	@echo "$(GREEN)Current Account:$(NC)"
	@az account show --query "{account:user.name, subscription:name, id:id}" -o table

.PHONY: admin-validate
admin-validate: ## Validate admin bicep template
	@az bicep build --file $(ADMIN_TEMPLATE_FILE)
	@echo "$(GREEN)✓ Admin template valid$(NC)"

.PHONY: admin-create-groups
admin-create-groups: ## Admin: Create all 11 resource groups
	@echo "$(BLUE)Creating resource groups...$(NC)"
	@for i in {1..11}; do \
		RG="rg-hackathon-rbs2026-uc$$i"; \
		echo -n "  $$RG... "; \
		if az group show --name "$$RG" &> /dev/null; then \
			echo "$(GREEN)exists$(NC)"; \
		else \
			az group create --name "$$RG" --location $(LOCATION) > /dev/null; \
			echo "$(GREEN)created$(NC)"; \
		fi; \
	done
	@echo ""
	@echo "$(GREEN)✓ All resource groups ready$(NC)"
	@echo ""
	@echo "$(BLUE)Share these with teams:$(NC)"
	@for i in {1..11}; do echo "  rg-hackathon-rbs2026-uc$$i"; done

.PHONY: admin-list-groups
admin-list-groups: ## Admin: List all hackathon resource groups
	@az group list --query "[?contains(name, 'hackathon-rbs2026')].{name:name, location:location}" -o table

.PHONY: admin-monitor
admin-monitor: ## Admin: Monitor all deployments (optional: GROUP=rg-xxx)
	@if [ -z "$(GROUP)" ]; then \
		echo "$(BLUE)All hackathon deployments:$(NC)"; \
		az deployment group list --resource-group "$$(az group list --query '[0].name' -o tsv)" --query "[?contains(name, 'deploy-')].{name:name, state:properties.provisioningState}" -o table 2>/dev/null || \
		echo "No deployments yet"; \
	else \
		echo "$(BLUE)Deployments in: $(GROUP)$(NC)"; \
		az deployment group list --resource-group "$(GROUP)" -o table; \
	fi

.PHONY: admin-destroy-all
admin-destroy-all: ## Admin: Delete all hackathon resource groups (destructive!)
	@echo "$(BLUE)This will delete ALL hackathon resource groups:$(NC)"
	@for i in {1..11}; do echo "  rg-hackathon-rbs2026-uc$$i"; done
	@echo ""
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		for i in {1..11}; do \
			az group delete --name "rg-hackathon-rbs2026-uc$$i" --yes --no-wait; \
		done; \
		echo "$(GREEN)✓ Deletion started (running in background)$(NC)"; \
	else \
		echo "Cancelled"; \
	fi


# ============================================================================
# RESOURCE-GROUP-SCOPED DEPLOYMENT (infra/)
# Teams deploy to pre-created resource groups
# ============================================================================

.PHONY: validate
validate: ## Validate team bicep template
	@az bicep build --file $(TEMPLATE_FILE)
	@echo "$(GREEN)✓ Template valid$(NC)"

.PHONY: deploy-validate
deploy-validate: validate ## Preview team deployment (make deploy-validate TEAM=uc1 RG=rg-hackathon-rbs2026-uc1)
	@if [ -z "$(TEAM)" ] || [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy-validate TEAM=<name> RG=<resource-group>$(NC)"; \
		exit 1; \
	fi
	@PARAMS=$(INFRA_DIR)/main-$(TEAM).bicepparam; \
	if [ ! -f "$$PARAMS" ]; then \
		echo "$(BLUE)Creating parameters file from template...$(NC)"; \
		cp $(INFRA_DIR)/main.bicepparam.template $$PARAMS; \
		sed -i "s/changeMe/$(TEAM)/" $$PARAMS; \
	fi
	@echo "$(BLUE)Validating deployment for: $(RG)$(NC)"
	@az deployment group what-if \
		--name "deploy-$(TEAM)" \
		--resource-group "$(RG)" \
		--template-file $(TEMPLATE_FILE) \
		--parameters $$PARAMS

.PHONY: deploy
deploy: validate ## Deploy to resource group (make deploy TEAM=uc1 RG=rg-hackathon-rbs2026-uc1)
	@if [ -z "$(TEAM)" ] || [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy TEAM=<name> RG=<resource-group>$(NC)"; \
		echo "  Example: make deploy TEAM=uc1 RG=rg-hackathon-rbs2026-uc1"; \
		exit 1; \
	fi
	@if ! az group show --name "$(RG)" &> /dev/null; then \
		echo "$(BLUE)Resource group not found: $(RG)$(NC)"; \
		exit 1; \
	fi
	@PARAMS=$(INFRA_DIR)/main-$(TEAM).bicepparam; \
	if [ ! -f "$$PARAMS" ]; then \
		echo "$(BLUE)Creating parameters file from template...$(NC)"; \
		cp $(INFRA_DIR)/main.bicepparam.template $$PARAMS; \
		sed -i "s/changeMe/$(TEAM)/" $$PARAMS; \
		echo "$(GREEN)✓ Created $$PARAMS$(NC)"; \
		echo "$(BLUE)Edit the file to customize, then run again$(NC)"; \
		exit 0; \
	fi
	@echo "$(BLUE)Deploying to resource group: $(RG)$(NC)"
	@az deployment group create \
		--name "deploy-$(TEAM)" \
		--resource-group "$(RG)" \
		--template-file $(TEMPLATE_FILE) \
		--parameters $$PARAMS

.PHONY: deploy-outputs
deploy-outputs: ## Show deployment outputs (make deploy-outputs TEAM=uc1 RG=rg-xxx)
	@if [ -z "$(TEAM)" ] || [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy-outputs TEAM=<name> RG=<resource-group>$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Outputs for: $(TEAM) in $(RG)$(NC)"
	@az deployment group show --name "deploy-$(TEAM)" --resource-group "$(RG)" --query properties.outputs -o json

.PHONY: deploy-destroy
deploy-destroy: ## Delete resource group deployment (make deploy-destroy RG=rg-xxx)
	@if [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy-destroy RG=rg-hackathon-rbs2026-uc1$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Deleting resource group: $(RG)$(NC)"
	@az group delete --name "$(RG)" --yes

# ============================================================================
# UTILITY
# ============================================================================

.PHONY: clean
clean: ## Remove generated parameter files
	@rm -f $(INFRA_DIR)/main-*.bicepparam
	@echo "$(GREEN)✓ Cleaned parameter files$(NC)"

.PHONY: list-teams
list-teams: ## List all active hackathon resource groups
	@az group list --query "[?contains(name, 'hackathon-rbs2026')].{team:name, location:location}" -o table
