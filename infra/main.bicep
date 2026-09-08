targetScope = 'subscription'

@description('Name of the resource group that will contain the Azure AI Foundry resource.')
param resourceGroupName string

@description('Azure region in which to deploy the Azure AI Foundry resource and model.')
param location string

@description('Globally unique name for the Microsoft Foundry resource.')
@minLength(2)
@maxLength(64)
param foundryName string

@description('Name of the Microsoft Foundry project.')
@minLength(3)
@maxLength(64)
param foundryProjectName string

@description('Display name for the Microsoft Foundry project.')
param foundryProjectDisplayName string = foundryProjectName

@description('Description displayed for the Microsoft Foundry project.')
param foundryProjectDescription string = 'Hackathon Microsoft Foundry project.'

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

@description('Tags applied to all supported resources.')
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module foundry './foundry.bicep' = {
  name: 'foundry-${modelDeployments[0].deploymentName}'
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

output foundryEndpoint string = foundry.outputs.foundryEndpoint
output foundryProjectName string = foundry.outputs.foundryProjectName
output llmDeploymentName string = foundry.outputs.llmDeploymentName
output llmDeploymentNames array = foundry.outputs.llmDeploymentNames
output deployedResourceGroupName string = resourceGroup.name
