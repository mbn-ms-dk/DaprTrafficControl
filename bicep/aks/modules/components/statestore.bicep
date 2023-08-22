targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@secure()
param kubeConfig string

@description('The name of Cosmos DB resource.')
param cosmosDbName string

@description('The name of Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string

@description('The name of the service for the trafficcontrol service. The name is use as Dapr App ID.')
param trafficcontrolServiceName string

@description('Use actors in traffic control service')
param useActors bool

@description('Aks namespace')
param aksNameSpace string

// ------------------
// RESOURCES
// ------------------
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosDbName
}

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
}

resource daprIoComponent_NAME 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: 'statestore'
    namespace: aksNameSpace
  }
  spec: {
    type: 'state.azure.cosmosdb'
    version: 'v1'
    metadata: [
      {
        name: 'url'
        value: cosmosDbAccount.properties.documentEndpoint
      }
      {
        name: 'database'
        value: cosmosDbDatabaseName
      }
      {
        name: 'collection'
        value:  cosmosDbCollectionName
      }
      {
        name: 'actorStateStore'
        value: useActors
      }
    ]
  }
  scopes: [
    trafficcontrolServiceName
  ]
}
