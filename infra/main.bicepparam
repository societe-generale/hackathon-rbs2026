using './main.bicep'

// Team identifier: each team picks their own. Drives default names for the
// resource group and every resource inside it.
param teamName = 'adam'

param location = 'swedencentral'

// Select models available in the chosen region. `deploymentName` is what your
// app sends as the model/deployment identifier (AZURE_OPENAI_DEPLOYMENT_NAME).
param modelDeployments = [
  {
    deploymentName: 'gpt-5.4-mini'
    modelName: 'gpt-5.4-mini'
    modelVersion: '2026-03-17'
    skuName: 'GlobalStandard'
    capacity: 1
  }
  {
    deploymentName: 'gpt-5.6-terra'
    modelName: 'gpt-5.6-terra'
    modelVersion: '2026-07-09'
    skuName: 'GlobalStandard'
    capacity: 1
  }
]
