targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The name of the container apps environment.')
param containerAppsEnvironmentName string

@description('The name of the service bus namespace.')
param serviceBusName string

@description('The name of Cosmos DB resource.')
param cosmosDbName string

@description('The name of Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string


@description('The name of the service for the traffic control service. The name is used as Dapr App ID.')
param trafficcontrolserviceServiceName string

@description('The name of the service for the finecollection service. The name is used as Dapr App ID and as the name of service bus topic subscription.')
param finecollectionserviceServiceName string

// ------------------
// RESOURCES
// ------------------

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosDbName
}

//Cosmos DB State Store Component
resource statestoreComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'statestore'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'state.azure.cosmosdb'
    version: 'v1'
    secrets: [
    ]
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
        value: cosmosDbCollectionName
      }
    ]
    scopes: [
      trafficcontrolserviceServiceName
    ]
  }
}

//PubSub service bus Component
resource pubsubComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'pubsub'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'pubsub.azure.servicebus'
    version: 'v1'
    secrets: [
    ]
    metadata: [
      {
        name: 'namespaceName'
        value: '${serviceBusName}.servicebus.windows.net'
      }
      {
        name: 'consumerID'
        value: finecollectionserviceServiceName
      }
    ]
    scopes: [
      trafficcontrolserviceServiceName
      finecollectionserviceServiceName
    ]
  }
}

// Entrycam component
resource entrycamComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'entrycam'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'bindings.mqtt'
    version: 'v1'
    metadata: [
      {
        name: 'url'
        value: 'mqtt://mosquitto:1883'
      }
      {
        name: 'topic'
        value: 'trafficcontrol/entrycam'
      }
      {
        name: 'consumerID'
        value: '{uuid}'
      }
    ]
    scopes: [
      trafficcontrolserviceServiceName
    ]
  }
}

// Exitcam component
resource exitcamComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'exitcam'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'bindings.mqtt'
    version: 'v1'
    metadata: [
      {
        name: 'url'
        value: 'mqtt://mosquitto:1883'
      }
      {
        name: 'topic'
        value: 'trafficcontrol/exitcam'
      }
      {
        name: 'consumerID'
        value: '{uuid}'
      }
    ]
    scopes: [
      trafficcontrolserviceServiceName
    ]
  }
}

//Email component
resource emailComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'sendmail'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'bindings.smtp'
    version: 'v1'
    metadata: [
      {
        name: 'host'
        value: 'mailserver'
      }
      {
         name: 'user'
         value: '_username'
      }
      {
          name: 'password'
          value: '_password'
      }
      {
          name: 'skipTLSVerify'
          value: 'true'
      }
    ]
    scopes: [
      trafficcontrolserviceServiceName
    ]
  }
}


