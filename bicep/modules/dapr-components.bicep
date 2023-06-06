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

@description('The name of Dapr component for the secret store building block.')
// We disable lint of this line as it is not a secret but the name of the Dapr component
#disable-next-line secure-secrets-in-params
param secretStoreComponentName string

@description('The name of the email user')
param emailUserSecretName string

@description('The password of the email user')
param emailPasswordSecretName string

@description('The name of the key vault resource.')
param keyVaultName string

@description('The name of the service for the traffic simulation service. The name is used as Dapr App ID.')
param trafficSimulationServiceName string

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

//Secret Store Component
resource secretstoreComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-03-01' = {
  name: secretStoreComponentName
  parent: containerAppsEnvironment
  properties: {
    componentType: 'secretstores.azure.keyvault'
    version: 'v1'
    metadata: [
      {
        name: 'vaultName'
        value: keyVaultName
      }
    ]
    scopes: [
      trafficSimulationServiceName
      trafficcontrolserviceServiceName
      finecollectionserviceServiceName
    ]
  }
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
        value: 'dtc-mosquitto'
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
      trafficSimulationServiceName
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
        value: 'dtc-mosquitto'
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
      trafficSimulationServiceName
      trafficcontrolserviceServiceName
    ]
  }
}

//mail secrets
module emailSecrets 'secrets/mail-server-secrets.bicep' = {
  name: 'emailSecrets'
  params: {
    keyVaultName: keyVaultName
    emailUserSecretName: emailUserSecretName
    emailPasswordSecretName: emailPasswordSecretName
  }
}

//Email component
resource emailComponent 'Microsoft.App/managedEnvironments/daprComponents@2022-06-01-preview' = {
  name: 'sendmail'
  parent: containerAppsEnvironment
  properties: {
    componentType: 'bindings.smtp'
    version: 'v1'
    secretStoreComponent: secretStoreComponentName
    metadata: [
      {
        name: 'host'
        value: 'dtc-mail'
      }
      {
         name: 'user'
         secretRef: emailUserSecretName
      }
      {
          name: 'password'
          secretRef: emailPasswordSecretName
      }
      {
          name: 'skipTLSVerify'
          value: 'true'
      }
    ]
    scopes: [
      finecollectionserviceServiceName
    ]
  }
  dependsOn: [
    secretstoreComponent
  ]
}

