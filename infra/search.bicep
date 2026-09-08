targetScope = 'resourceGroup'

@description('Azure region for the Azure AI Search service.')
param location string

@description('Globally unique Azure AI Search service name (2-60 chars, lowercase letters, numbers, hyphens).')
@minLength(2)
@maxLength(60)
param searchServiceName string

@description('SKU tier for the search service. Basic is the cheapest tier that supports vector + semantic search needed for RAG.')
@allowed([
  'basic'
  'standard'
])
param sku string = 'basic'

@description('Tags applied to the search service.')
param tags object = {}

resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: searchServiceName
  location: location
  sku: {
    name: sku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    semanticSearch: 'free'
  }
  tags: tags
}

output searchServiceName string = searchService.name
output searchEndpoint string = 'https://${searchService.name}.search.windows.net'
