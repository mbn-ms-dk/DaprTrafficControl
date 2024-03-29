targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The prefix to be used for all resources created by this template.')
param prefix string = ''

@description('Optional. The suffix to be used for all resources created by this template.')
param suffix string = ''

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {
  solution: 'daprtrafficcontrol'
  shortName: 'dtc'
  iac: 'bicep'
  environment: 'aca'
}

// Container Apps Env / Log Analytics Workspace / Application Insights
@description('Optional. The name of the container apps environment. If set, it overrides the name generated by the template.')
param containerAppsEnvironmentName string = '${prefix}cae-${uniqueString(resourceGroup().id)}${suffix}'

@description('Optional. The name of the log analytics workspace. If set, it overrides the name generated by the template.')
param logAnalyticsWorkspaceName string = '${prefix}log-${uniqueString(resourceGroup().id)}${suffix}'

@description('Optional. The name of the application insights. If set, it overrides the name generated by the template.')
param applicationInsightName string = '${prefix}appi-${uniqueString(resourceGroup().id)}${suffix}'

// Dapr
@description('The name of Dapr component for the secret store building block.')
// We disable lint of this line as it is not a secret but the name of the Dapr component
#disable-next-line secure-secrets-in-params
param secretStoreComponentName string

// Services
@description('The name of the service for the mosquitto service. The name is use as Dapr App ID.')
param mosquittoServiceName string  

@description('The name of the service for the mail service. The name is use as Dapr App ID.')
param mailServiceName string

@description('The name of the service for the finecollection service. The name is use as Dapr App ID and as the name of service bus topic subscription.')
param finecollectionServiceName string

@description('The name of the service for the trafficcontrol service. The name is use as Dapr App ID.')
param trafficcontrolServiceName string

@description('The name of the service for the trafficsimulation service. The name is use as Dapr App ID.')
param trafficsimulationServiceName string

@description('The name of the service for the visualsimulation service. The name is use as Dapr App ID.')
param visualsimulationServiceName string

@description('The name of the service for the vehicleregistration service. The name is use as Dapr App ID.')
param vehicleregistrationServiceName string

// Service Bus
@description('Optional. The name of the service bus namespace. If set, it overrides the name generated by the template.')
param serviceBusName string = '${prefix}sb-${uniqueString(resourceGroup().id)}${suffix}'

@description('The name of the service bus topic.')
param serviceBusTopicName string

@description('The name of the service bus topic\'s authorization rule.')
param serviceBusTopicAuthorizationRuleName string

// Cosmos DB
@description('Optional. The name of Cosmos DB resource. If set, it overrides the name generated by the template.')
param cosmosDbName string ='${prefix}cosno-${uniqueString(resourceGroup().id)}${suffix}'

@description('The name of Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string

// KeyVault
@description('The key vault name store secrets')
param keyVaultName string = '${prefix}kv-${uniqueString(resourceGroup().id)}${suffix}'

@secure()
@description('The name of the email user')
param emailUserSecretName string

@secure()
@description('The password of the email user')
param emailPasswordSecretName string

@secure()
@description('Application Insights secret name')
param applicationInsightsSecretName string

@description('Use the mosquitto broker for MQTT communication. if false it uses Http')
param useMosquitto bool

@description('Use actors in traffic control service')
param useActors bool

// App Ports
@description('The target and dapr port for the mosquitto service.')
param mosquittoPortNumber int = 1883

@description('The target and dapr port for the mail service.')
param mailPortNumber int = 1025

@description('The dapr port for the finecollection service.')
param finecollectionPortNumber int = 5158

@description('The dapr port for the trafficcontrol service.')
param trafficcontrolPortNumber int = 5047

@description('The dapr port for the trafficsimulation service.')
param trafficsimulationPortNumber int = 5286

@description('The dapr port for the vehicleregistration service.')
param vehicleregistrationPortNumber int = 5287

@description('The target and dapr port for the visualsimulation service.')
param visualsimulationPortNumber int = 5123


// ------------------
// RESOURCES
// ------------------

module containerAppsEnvironment 'modules/container-apps-environment.bicep' ={
  name: 'containerAppsEnv-${uniqueString(resourceGroup().id)}'
  params: {
   containerAppsEnvironmentName: containerAppsEnvironmentName
   logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
   applicationInsightName: applicationInsightName
    location: location
    tags: tags
  }
}

module serviceBus 'modules/service-bus.bicep' = {
  name: 'serviceBus-${uniqueString(resourceGroup().id)}'
  params: {
    serviceBusName: serviceBusName
    location: location
    tags: tags
    serviceBusTopicName: serviceBusTopicName
    serviceBusTopicAuthorizationRuleName: serviceBusTopicAuthorizationRuleName
    finecollectionServiceName: finecollectionServiceName
  }
}

module cosmosDb 'modules/cosmos-db.bicep' = {
  name: 'cosmosDb-${uniqueString(resourceGroup().id)}'
  params: {
    cosmosDbName: cosmosDbName
    location: location
    tags: tags
    cosmosDbDatabaseName: cosmosDbDatabaseName
    cosmosDbCollectionName: cosmosDbCollectionName 
  }
}

module daprComponents 'modules/dapr-components.bicep' = {
  name: 'daprComponents-${uniqueString(resourceGroup().id)}'
  params: {
    containerAppsEnvironmentName: containerAppsEnvironmentName    
    serviceBusName: serviceBus.outputs.serviceBusName
    cosmosDbName: cosmosDb.outputs.cosmosDbName
    cosmosDbDatabaseName: cosmosDb.outputs.cosmosDbDatabaseName
    cosmosDbCollectionName: cosmosDb.outputs.cosmosDbCollectionName  
    keyVaultName: keyVaultName  
    secretStoreComponentName: secretStoreComponentName
    emailPortNumber: mailPortNumber
    emailUserSecretName: emailUserSecretName
    emailPasswordSecretName: emailPasswordSecretName
    trafficcontrolserviceServiceName: trafficcontrolServiceName
    finecollectionserviceServiceName: finecollectionServiceName
    useMosquitto: useMosquitto
  }
  dependsOn: [
    containerAppsEnvironment
  ]
}

module acr 'modules/container-registry.bicep' = {
  name: 'acr-${uniqueString(resourceGroup().id)}'
  params: {
    acrName: 'acr${uniqueString(resourceGroup().id)}'
    location: location
    tags: tags
  }
}

module keyVault 'modules/key-vault.bicep' = {
  name: keyVaultName
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
  }
}
module containerApps 'modules/container-apps.bicep' = {
  name: 'containerApps-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
    mosquittoServiceName: mosquittoServiceName
    mailServiceName: mailServiceName
    finecollectionServiceName: finecollectionServiceName
    trafficcontrolServiceName: trafficcontrolServiceName
    trafficsimulationServiceName: trafficsimulationServiceName
    visualsimulationServiceName: visualsimulationServiceName
    vehicleregistrationServiceName: vehicleregistrationServiceName
    containerAppsEnvironmentName: containerAppsEnvironmentName
    serviceBusName: serviceBus.outputs.serviceBusName
    serviceBusTopicName: serviceBus.outputs.serviceBusTopicName
    cosmosDbName: cosmosDb.outputs.cosmosDbName
    cosmosDbDatabaseName: cosmosDb.outputs.cosmosDbDatabaseName
    cosmosDbCollectionName: cosmosDb.outputs.cosmosDbCollectionName    
    containerRegistryName: acr.outputs.acrName
    applicationInsightsName: containerAppsEnvironment.outputs.applicationInsightsName
    applicationInsightsSecretName: applicationInsightsSecretName
    mosquittoPortNumber: mosquittoPortNumber
    mailPortNumber: mailPortNumber  
    finecollectionPortNumber: finecollectionPortNumber
    trafficcontrolPortNumber: trafficcontrolPortNumber
    trafficsimulationPortNumber: trafficsimulationPortNumber
    visualsimulationPortNumber: visualsimulationPortNumber 
    vehicleregistrationPortNumber: vehicleregistrationPortNumber
    useMosquitto: useMosquitto
    useActors: useActors
  }
  dependsOn: [
    daprComponents
  ]
}

// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the mail service.')
output mailServiceContainerAppName string = containerApps.outputs.mailServiceContainerAppName

@description('The name of the container app for the mosquitto service.')
output mosquittoServiceContainerAppName string = containerApps.outputs.mosquittoServiceContainerAppName

@description('The name of the container app for the trafficsimulation service.')
output trafficsimulationServiceContainerAppName string = containerApps.outputs.trafficsimulationServiceContainerAppName

@description('The name of the container app for the visual simulation service.')
output visualsimulationServiceContainerAppName string = containerApps.outputs.visualsimulationServiceContainerAppName

@description('The name of the container app for the trafficcontrol service.')
output trafficcontrolServiceContainerAppName string = containerApps.outputs.trafficcontrolServiceContainerAppName

@description('The name of the container app for the finecollection service.')
output finecollectionServiceContainerAppName string = containerApps.outputs.finecollectionServiceContainerAppName

@description('The name of the container app for the vehicleregistration service.')
output vehicleregistrationServiceContainerAppName string = containerApps.outputs.vehicleregistrationServiceContainerAppName


