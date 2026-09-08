## Makefile for deploying the Azure AI Foundry infrastructure (infra/).
##
## The Bicep templates are subscription-scoped: `deploy` creates the resource
## group and all resources inside it in one shot via `az deployment sub create`.

SHELL := /bin/bash

# Location used for the deployment operation itself (can differ from the
# resource group's own location, which is set in main.bicepparam).
LOCATION ?= swedencentral
DEPLOYMENT_NAME ?= foundry-llm

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
outputs: ## Show the endpoint, project, deployment names and resource group from the last deploy
	@echo "Foundry endpoint:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.foundryEndpoint.value --output tsv
	@echo "Foundry project name:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.foundryProjectName.value --output tsv
	@echo "LLM deployment names:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.llmDeploymentNames.value --output tsv
	@echo "Resource group name:"
	@az deployment sub show --name $(DEPLOYMENT_NAME) --query properties.outputs.deployedResourceGroupName.value --output tsv

RESOURCE_GROUP_NAME := $(shell grep -oP "param resourceGroupName\s*=\s*'\K[^']+" $(PARAMETERS_FILE))

.PHONY: destroy
destroy: ## Delete the resource group and everything it contains
	az group delete --name "$(RESOURCE_GROUP_NAME)" --yes
