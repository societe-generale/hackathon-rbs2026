using './main.bicep'

param resourceGroupName = 'rg-hackathon-rbs2026-adam'
param location = 'swedencentral'
param foundryName = 'foundry-hackathon-rbs2026-adam'
param foundryProjectName = 'rbs2026-adam'
param foundryProjectDisplayName = 'RBS 2026 Hackathon Dev'
param foundryProjectDescription = 'Microsoft Foundry project for the RBS 2026 hackathon.'

// Select a model and version available in the selected Azure region.
param modelDeployments = [
  {
    deploymentName: 'gpt-5.6-terra'
    modelName: 'gpt-5.6-terra'
    modelVersion: '2026-07-09'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]

param tags = {
  environment: 'dev'
  project: 'hackathon-rbs2026'
}
