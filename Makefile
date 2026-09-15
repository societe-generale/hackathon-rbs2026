## Makefile for Hackathon Resource Group Deployment
##
## Two deployment approaches:
##   1. Subscription-scoped (infra/) - Teams create their own resource groups
##   2. Resource-group-scoped (infra-rg/) - Admin creates groups, teams deploy to them
##
## Usage:
##   make help                           # Show all targets
##   make login                          # Sign in to Azure
##
##   # Subscription approach (self-service)
##   make deploy TEAM=panthers           # Deploy team's RG + resources
##
##   # Resource-group approach (admin-managed)
##   make admin-create-groups            # Admin: Create all 11 RGs
##   make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1

SHELL := /bin/bash

# Configuration
LOCATION ?= swedencentral
DEPLOYMENT_NAME ?= hackathon-rbs2026

# Subscription-scoped (infra/)
INFRA_DIR := infra
TEMPLATE_FILE := $(INFRA_DIR)/main.bicep
PARAMETERS_FILE := $(INFRA_DIR)/main.bicepparam

# Resource-group-scoped (infra-rg/)
INFRA_RG_DIR := infra-rg
TEMPLATE_RG_FILE := $(INFRA_RG_DIR)/main.bicep

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
	@echo "$(BLUE)Subscription-Scoped (teams self-deploy - infra/):$(NC)"
	@grep -E '^  deploy|^  deploy-validate|^  deploy-outputs|^  deploy-destroy' $(MAKEFILE_LIST) | grep '##' | awk 'BEGIN {FS = ":.*?## "}; {printf "    %-30s %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Resource-Group-Scoped (admin + teams - infra-rg/):$(NC)"
	@grep -E '^  admin-|^  deploy-to-' $(MAKEFILE_LIST) | grep '##' | awk 'BEGIN {FS = ":.*?## "}; {printf "    %-30s %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "    make login"
	@echo "    make deploy TEAM=panthers                    # Subscription approach"
	@echo "    make admin-create-groups                     # Resource-group approach (step 1)"
	@echo "    make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1  # (step 2)"

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

# ============================================================================
# SUBSCRIPTION-SCOPED DEPLOYMENT (infra/)
# Teams create their own resource groups
# ============================================================================

.PHONY: validate
validate: ## Validate Bicep template
	@az bicep build --file $(TEMPLATE_FILE)
	@echo "$(GREEN)✓ Template valid$(NC)"

.PHONY: deploy-validate
deploy-validate: validate ## Preview subscription-scoped deployment
	@if [ -z "$(TEAM)" ]; then \
		echo "$(BLUE)Usage: make deploy-validate TEAM=<teamname>$(NC)"; \
		exit 1; \
	fi
	@PARAMS=$(INFRA_DIR)/main-$(TEAM).bicepparam; \
	if [ ! -f "$$PARAMS" ]; then \
		echo "$(BLUE)Creating parameters file from template...$(NC)"; \
		cp $(INFRA_DIR)/main.bicepparam.template $$PARAMS; \
		sed -i "s/changeMe/$(TEAM)/" $$PARAMS; \
	fi
	@echo "$(BLUE)Validating deployment for team: $(TEAM)$(NC)"
	@az deployment sub what-if \
		--name $(DEPLOYMENT_NAME)-$(TEAM) \
		--location $(LOCATION) \
		--template-file $(TEMPLATE_FILE) \
		--parameters $(INFRA_DIR)/main-$(TEAM).bicepparam

.PHONY: deploy
deploy: validate ## Deploy subscription-scoped (team: make deploy TEAM=<teamname>)
	@if [ -z "$(TEAM)" ]; then \
		echo "$(BLUE)Usage: make deploy TEAM=<teamname>$(NC)"; \
		echo "  Example: make deploy TEAM=panthers"; \
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
	@echo "$(BLUE)Deploying for team: $(TEAM)$(NC)"
	@az deployment sub create \
		--name $(DEPLOYMENT_NAME)-$(TEAM) \
		--location $(LOCATION) \
		--template-file $(TEMPLATE_FILE) \
		--parameters $$PARAMS

.PHONY: deploy-outputs
deploy-outputs: ## Show deployment outputs (make deploy-outputs TEAM=<teamname>)
	@if [ -z "$(TEAM)" ]; then \
		echo "$(BLUE)Usage: make deploy-outputs TEAM=<teamname>$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Outputs for team: $(TEAM)$(NC)"
	@az deployment sub show --name $(DEPLOYMENT_NAME)-$(TEAM) --query properties.outputs -o json

.PHONY: deploy-destroy
deploy-destroy: ## Destroy subscription-scoped deployment (make deploy-destroy TEAM=<teamname>)
	@if [ -z "$(TEAM)" ]; then \
		echo "$(BLUE)Usage: make deploy-destroy TEAM=<teamname>$(NC)"; \
		exit 1; \
	fi
	@RG=$$(az deployment sub show --name $(DEPLOYMENT_NAME)-$(TEAM) --query properties.outputs.resourceGroupName.value -o tsv 2>/dev/null); \
	if [ -z "$$RG" ]; then \
		echo "$(BLUE)Resource group not found for team: $(TEAM)$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Deleting resource group: $$RG$(NC)"
	@az group delete --name "$$RG" --yes

# ============================================================================
# RESOURCE-GROUP-SCOPED DEPLOYMENT (infra-rg/)
# Admin creates resource groups, teams deploy to them
# ============================================================================

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

.PHONY: deploy-to-group
deploy-to-group: ## Deploy to resource group (make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1)
	@if [ -z "$(TEAM)" ] || [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy-to-group TEAM=<name> RG=<resource-group>$(NC)"; \
		echo "  Example: make deploy-to-group TEAM=uc1 RG=rg-hackathon-rbs2026-uc1"; \
		exit 1; \
	fi
	@if ! az group show --name "$(RG)" &> /dev/null; then \
		echo "$(BLUE)Resource group not found: $(RG)$(NC)"; \
		exit 1; \
	fi
	@PARAMS=$(INFRA_RG_DIR)/main-$(TEAM).bicepparam; \
	if [ ! -f "$$PARAMS" ]; then \
		echo "$(BLUE)Creating parameters file from template...$(NC)"; \
		cp $(INFRA_RG_DIR)/main.bicepparam.template $$PARAMS; \
		sed -i "s/changeMe/$(TEAM)/" $$PARAMS; \
		echo "$(GREEN)✓ Created $$PARAMS$(NC)"; \
		echo "$(BLUE)Edit the file to customize, then run again$(NC)"; \
		exit 0; \
	fi
	@echo "$(BLUE)Deploying to resource group: $(RG)$(NC)"
	@az deployment group create \
		--name "deploy-$(TEAM)" \
		--resource-group "$(RG)" \
		--template-file $(TEMPLATE_RG_FILE) \
		--parameters $$PARAMS

.PHONY: deploy-to-group-validate
deploy-to-group-validate: ## Preview resource-group deployment (make deploy-to-group-validate TEAM=uc1 RG=rg-xxx)
	@if [ -z "$(TEAM)" ] || [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy-to-group-validate TEAM=<name> RG=<resource-group>$(NC)"; \
		exit 1; \
	fi
	@PARAMS=$(INFRA_RG_DIR)/main-$(TEAM).bicepparam; \
	if [ ! -f "$$PARAMS" ]; then \
		echo "$(BLUE)Creating parameters file from template...$(NC)"; \
		cp $(INFRA_RG_DIR)/main.bicepparam.template $$PARAMS; \
		sed -i "s/changeMe/$(TEAM)/" $$PARAMS; \
	fi
	@echo "$(BLUE)Validating deployment for: $(RG)$(NC)"
	@az deployment group what-if \
		--name "deploy-$(TEAM)" \
		--resource-group "$(RG)" \
		--template-file $(TEMPLATE_RG_FILE) \
		--parameters $$PARAMS

.PHONY: deploy-to-group-outputs
deploy-to-group-outputs: ## Show resource-group deployment outputs (make deploy-to-group-outputs TEAM=uc1 RG=rg-xxx)
	@if [ -z "$(TEAM)" ] || [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy-to-group-outputs TEAM=<name> RG=<resource-group>$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Outputs for: $(TEAM) in $(RG)$(NC)"
	@az deployment group show --name "deploy-$(TEAM)" --resource-group "$(RG)" --query properties.outputs -o json

.PHONY: deploy-to-group-destroy
deploy-to-group-destroy: ## Delete resource group deployment (make deploy-to-group-destroy RG=rg-xxx)
	@if [ -z "$(RG)" ]; then \
		echo "$(BLUE)Usage: make deploy-to-group-destroy RG=rg-hackathon-rbs2026-uc1$(NC)"; \
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
	@rm -f $(INFRA_RG_DIR)/main-*.bicepparam
	@echo "$(GREEN)✓ Cleaned parameter files$(NC)"

.PHONY: list-teams
list-teams: ## List all active hackathon resource groups
	@az group list --query "[?contains(name, 'hackathon-rbs2026')].{team:name, location:location}" -o table
