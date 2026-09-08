## Makefile for deploying the hackathon Azure infrastructure (infra/).
##
## The Bicep templates are subscription-scoped: `deploy` creates the team's
## resource group and every resource inside it (Foundry, Storage, Cosmos,
## AI Search) in one shot via `az deployment sub create`.

SHELL := /bin/bash

# Location used for the deployment operation itself (can differ from the
# resource group's own location, which is set in main.bicepparam).
LOCATION ?= swedencentral
DEPLOYMENT_NAME ?= hackathon-rbs2026

INFRA_DIR := infra
TEMPLATE_FILE := $(INFRA_DIR)/main.bicep
PARAMETERS_FILE := $(INFRA_DIR)/main.bicepparam

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.PHONY: login
login: ## Sign in to Azure (interactive)
	az login --use-device-code

.PHONY: build
build: ## Validate/compile the Bicep template
	az bicep build --file $(TEMPLATE_FILE)

.PHONY: whatif
whatif: build ## Preview the changes that `deploy` would make
	az deployment sub what-if \
		--name $(DEPLOYMENT_NAME) \
		--location $(LOCATION) \
		--template-file $(TEMPLATE_FILE) \
		--parameters $(PARAMETERS_FILE)

.PHONY: deploy
deploy: build ## Deploy the resource group and all Foundry resources in it
	az deployment sub create \
		--name $(DEPLOYMENT_NAME) \
		--location $(LOCATION) \
		--template-file $(TEMPLATE_FILE) \
		--parameters $(PARAMETERS_FILE)

.PHONY: outputs
outputs: ## Show the endpoints and resource names from the last deploy
	@echo "Resource group:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.resourceGroupName.value --output tsv
	@echo "Foundry endpoint:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.foundryEndpoint.value --output tsv
	@echo "Foundry project name:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.foundryProjectName.value --output tsv
	@echo "LLM deployment names:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.llmDeploymentNames.value --output tsv
	@echo "Storage account / blob endpoint / documents container:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.storageAccountName.value --output tsv
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.blobEndpoint.value --output tsv
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.documentsContainerName.value --output tsv
	@echo "Cosmos account / endpoint:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.cosmosAccountName.value --output tsv
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.cosmosEndpoint.value --output tsv
	@echo "AI Search service / endpoint:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.searchServiceName.value --output tsv
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.searchEndpoint.value --output tsv

RESOURCE_GROUP_NAME := $(shell az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.resourceGroupName.value --output tsv 2>/dev/null)

.PHONY: destroy
destroy: ## Delete the resource group and everything it contains
	az group delete --name "$(RESOURCE_GROUP_NAME)" --yes
