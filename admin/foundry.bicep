targetScope = 'resourceGroup'

@description('Azure region in which to deploy the Foundry resource, project, and model.')
param location string

@description('Globally unique name for the Microsoft Foundry resource.')
@minLength(2)
@maxLength(64)
param foundryName string

@description('Name of the Microsoft Foundry project.')
@minLength(2)
@maxLength(64)
param foundryProjectName string

@description('Display name for the Microsoft Foundry project.')
param foundryProjectDisplayName string = foundryProjectName

@description('Description displayed for the Microsoft Foundry project.')
param foundryProjectDescription string = 'Hackathon Microsoft Foundry project.'

@description('Model deployments to create. Each deploymentName is the value applications use as the model/deployment identifier.')
@minLength(1)
param modelDeployments array

@description('Whether the Foundry endpoint accepts public network traffic.')
param publicNetworkAccess string

@description('Tags applied to all supported resources.')
param tags object

// An AIServices resource with project management is the current Microsoft Foundry resource.
resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: foundryName
    publicNetworkAccess: publicNetworkAccess
  }
  tags: tags
}

resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundry
  name: foundryProjectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: foundryProjectDisplayName
    description: foundryProjectDescription
  }
  tags: tags
}

// Serialized after the project: the account rejects concurrent write operations.
resource llmDeployments 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = [for deployment in modelDeployments: {
  parent: foundry
  name: deployment.deploymentName
  sku: {
    name: deployment.skuName
    capacity: deployment.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: deployment.modelName
      version: deployment.modelVersion
    }
  }
  dependsOn: [
    foundryProject
  ]
}]

output foundryEndpoint string = foundry.properties.endpoint
output foundryProjectName string = foundryProject.name
output llmDeploymentName string = llmDeployments[0].name
output llmDeploymentNames array = [for (deployment, index) in modelDeployments: llmDeployments[index].name]
