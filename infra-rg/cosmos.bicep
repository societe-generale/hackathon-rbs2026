targetScope = 'resourceGroup'

@description('Azure region for the Cosmos DB account.')
param location string

@description('Globally unique Cosmos DB account name (3-44 chars, lowercase letters, numbers, hyphens).')
@minLength(3)
@maxLength(44)
param cosmosAccountName string

@description('Name of the Cosmos DB SQL database.')
param databaseName string = 'agent'

@description('Name of the container that stores agent chat sessions / memory.')
param sessionsContainerName string = 'sessions'

@description('Tags applied to the Cosmos DB account.')
param tags object = {}

// Serverless: pay-per-request, ideal for hackathon usage.
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
  tags: tags
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-11-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource sessionsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-11-15' = {
  parent: database
  name: sessionsContainerName
  properties: {
    resource: {
      id: sessionsContainerName
      partitionKey: {
        paths: [
          '/sessionId'
        ]
        kind: 'Hash'
      }
    }
  }
}

output cosmosAccountName string = cosmosAccount.name
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
output databaseName string = database.name
output sessionsContainerName string = sessionsContainer.name
