targetScope = 'subscription'

@description('Short team identifier used to compose default resource names (lowercase letters and numbers, keep under ~10 chars). Each team deploys their own resource group by picking a unique teamName.')
@minLength(2)
@maxLength(12)
param teamName string

@description('Azure region in which to create the resource group and all resources.')
param location string = 'swedencentral'

@description('Name of the resource group that will contain every hackathon resource for this team.')
param resourceGroupName string = 'rg-hackathon-rbs2026-${teamName}'

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
param storageAccountName string = 'st${teamName}${substring(uniqueString(subscription().id, teamName), 0, 8)}'

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

// -----------------------------------------------------------------------------

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module foundry './foundry.bicep' = {
  name: 'foundry'
  scope: az.resourceGroup(resourceGroupName)
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
  dependsOn: [
    resourceGroup
  ]
}

module storage './storage.bicep' = {
  name: 'storage'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    storageAccountName: toLower(storageAccountName)
    tags: tags
  }
  dependsOn: [
    resourceGroup
  ]
}

module cosmos './cosmos.bicep' = {
  name: 'cosmos'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    cosmosAccountName: cosmosAccountName
    tags: tags
  }
  dependsOn: [
    resourceGroup
  ]
}

module search './search.bicep' = {
  name: 'search'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    location: location
    searchServiceName: searchServiceName
    tags: tags
  }
  dependsOn: [
    resourceGroup
  ]
}

output resourceGroupName string = resourceGroup.name
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
