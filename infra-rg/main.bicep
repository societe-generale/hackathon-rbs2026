targetScope = 'resourceGroup'

@description('Short team identifier used to compose default resource names (lowercase letters and numbers, keep under ~10 chars).')
@minLength(2)
@maxLength(12)
param teamName string

@description('Azure region in which to create resources.')
param location string = 'swedencentral'

// --- Azure AI Foundry (LLM) ---------------------------------------------------

@description('Globally unique name for the Microsoft Foundry (AI Services) resource.')
param foundryName string = 'foundry-rbs2026-${teamName}'

@description('Name of the Microsoft Foundry project.')
param foundryProjectName string = 'rbs2026-${teamName}'

@description('Display name for the Microsoft Foundry project.')
param foundryProjectDisplayName string = 'RBS 2026 Hackathon - ${teamName}'

@description('Description displayed for the Microsoft Foundry project.')
param foundryProjectDescription string = 'Microsoft Foundry project for team ${teamName}.'

@description('Model deployments to create. Each deploymentName is the value applications use as the model/deployment identifier.')
@minLength(1)
param modelDeployments array = [
  {
    deploymentName: 'chat'
    modelName: 'gpt-4o-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]

@description('Whether the Foundry endpoint accepts public network traffic.')
param publicNetworkAccess string = 'Enabled'

// --- Storage (blob) -----------------------------------------------------------

@description('Globally unique storage account name (3-24 chars, lowercase letters and numbers only).')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'st${teamName}${substring(uniqueString(resourceGroup().id, teamName), 0, 8)}'

// --- Cosmos DB (NoSQL) --------------------------------------------------------

@description('Globally unique Cosmos DB account name (3-44 chars, lowercase letters, numbers, hyphens).')
param cosmosAccountName string = 'cosmos-rbs2026-${teamName}'

// --- Azure AI Search ----------------------------------------------------------

@description('Globally unique Azure AI Search service name (2-60 chars, lowercase letters, numbers, hyphens).')
param searchServiceName string = 'search-rbs2026-${teamName}'

// --- Common -------------------------------------------------------------------

@description('Tags applied to all resources.')
param tags object = {
  environment: 'dev'
  project: 'hackathon-rbs2026'
  team: teamName
}

// Resource group scope - resources are created directly in the pre-existing resource group

module foundry './foundry.bicep' = {
  name: 'foundry'
  params: {
    location: location
    foundryName: foundryName
    foundryProjectName: foundryProjectName
    foundryProjectDisplayName: foundryProjectDisplayName
    foundryProjectDescription: foundryProjectDescription
    modelDeployments: modelDeployments
    publicNetworkAccess: publicNetworkAccess
    tags: tags
  }
}

module storage './storage.bicep' = {
  name: 'storage'
  params: {
    location: location
    storageAccountName: toLower(storageAccountName)
    tags: tags
  }
}

module cosmos './cosmos.bicep' = {
  name: 'cosmos'
  params: {
    location: location
    cosmosAccountName: cosmosAccountName
    tags: tags
  }
}

module search './search.bicep' = {
  name: 'search'
  params: {
    location: location
    searchServiceName: searchServiceName
    tags: tags
  }
}

output foundryEndpoint string = foundry.outputs.foundryEndpoint
output foundryProjectName string = foundry.outputs.foundryProjectName
output llmDeploymentNames array = foundry.outputs.llmDeploymentNames
output storageAccountName string = storage.outputs.storageAccountName
output blobEndpoint string = storage.outputs.blobEndpoint
output documentsContainerName string = storage.outputs.documentsContainerName
output cosmosAccountName string = cosmos.outputs.cosmosAccountName
output cosmosEndpoint string = cosmos.outputs.cosmosEndpoint
output searchServiceName string = search.outputs.searchServiceName
output searchEndpoint string = search.outputs.searchEndpoint
