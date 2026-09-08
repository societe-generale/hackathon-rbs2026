targetScope = 'resourceGroup'

@description('Azure region for the storage account.')
param location string

@description('Globally unique storage account name (3-24 chars, lowercase letters and numbers).')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Name of the blob container used to store RAG source documents.')
param documentsContainerName string = 'documents'

@description('Tags applied to the storage account.')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
  tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource documentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: blobService
  name: documentsContainerName
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storageAccount.name
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
output documentsContainerName string = documentsContainer.name
