targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The tags to be assigned to the created resources.')
param tags object = {}

@description('The name of the container apps environment.')
param containerAppsEnvironmentName string

@description('The key vault name store secrets')
param keyVaultName string

// Services
@description('The name of the service for the mosquitto service. The name is use as Dapr App ID.')
param mosquittoServiceName string

@description('The name of the service for the mail service. The name is use as Dapr App ID and as the name of service bus topic subscription.')
param mailServiceName string

@description('The name of the service for the finecollection service. The name is use as Dapr App ID.')
param finecollectionServiceName string

@description('The name of the service for the trafficcontrol service. The name is use as Dapr App ID.')
param trafficcontrolServiceName string

@description('The name of the service for the trafficsimulation service. The name is use as Dapr App ID.')
param trafficsimulationServiceName string

@description('The name of the service for the vehicleregistration service. The name is use as Dapr App ID.')
param vehicleregistrationServiceName string

// Service Bus
@description('The name of the service bus namespace.')
param serviceBusName string

@description('The name of the service bus topic.')
param serviceBusTopicName string

@description('The name of the service bus topic\'s authorization rule.')
param serviceBusTopicAuthorizationRuleName string

// Cosmos DB
@description('The name of the provisioned Cosmos DB resource.')
param cosmosDbName string 

@description('The name of the provisioned Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string

// Container Registry & Images
@description('The name of the container registry.')
param containerRegistryName string

@description('The name of the application insights.')
param applicationInsightsName string

@description('Application insights secret name.')
param applicationInsightsSecretName string

// App Ports
@description('The target and dapr port for the mosquitto service.')
param mosquittoPortNumber int

@description('The target and dapr port for the email service.')
param mailPortNumber int

@description('The dapr port for the finecollection service.')
param finecollectionPortNumber int

@description('The dapr port for the trafficcontrol service.')
param trafficcontrolPortNumber int

@description('The dapr port for the trafficsimulation service.')
param trafficsimulationPortNumber int

@description('The dapr port for the vehicleregistration service.')
param vehicleregistrationPortNumber int

// ------------------
// VARIABLES
// ------------------

var containerRegistryPullRoleGuid='7f951dda-4ed3-4680-a7ca-43fe172d538d'
var keyVaultSecretUserRoleGuid = '4633458b-17de-408a-b874-0445c86b69e6'

// ------------------
// RESOURCES
// ------------------

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: containerAppsEnvironmentName
}
//Reference to AppInsights resource
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource containerRegistryUserAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'aca-user-identity-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
}

resource containerRegistryPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(containerRegistryName)) {
  name: guid(subscription().id, containerRegistry.id, containerRegistryUserAssignedIdentity.id) 
  scope: containerRegistry
  properties: {
    principalId: containerRegistryUserAssignedIdentity.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', containerRegistryPullRoleGuid)
    principalType: 'ServicePrincipal'
  }
}

// resource keyVaultSecretUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(subscription().id, keyVault.id, containerRegistryUserAssignedIdentity.id, keyVaultSecretUserRoleGuid) 
//   scope: keyVault
//   properties: {
//     principalId: containerRegistryUserAssignedIdentity.properties.principalId
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretUserRoleGuid)
//     principalType: 'ServicePrincipal'
//   }
// }

module applicationInsightsSecret 'secrets/app-insights-secrets.bicep' = {
  name: 'appInsightsSecret-${uniqueString(resourceGroup().id)}'
  params: {
    applicationInsightsSecretName: applicationInsightsSecretName
    applicationInsightsName: applicationInsights.name
    keyVaultName: keyVaultName
  }
}

module mailService 'container-apps/mail.bicep' = {
  name: 'mailService-${uniqueString(resourceGroup().id)}'
  params: {
    mailServiceName: mailServiceName
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
    mailPortNumber: mailPortNumber
  }
}

module mosquittoService 'container-apps/mosquitto.bicep' = {
  name: 'mosquittoService-${uniqueString(resourceGroup().id)}'
  params: {
    mosquittoServiceName: mosquittoServiceName
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
    containerRegistryUserAssignedIdentityId: containerRegistryUserAssignedIdentity.id
    containerRegistryName: containerRegistryName
    mosquittoPortNumber: mosquittoPortNumber
  }
}
module trafficsimulationService 'container-apps/trafficsimulation-service.bicep' = {
  name: 'trafficsimulationService-${uniqueString(resourceGroup().id)}'
  params: {
    trafficsimulationServiceName: trafficsimulationServiceName
    location: location
    tags: tags
    containerAppsEnvironmentId: containerAppsEnvironment.id
    keyVaultName: keyVaultName
    appInsightsInstrumentationKey: applicationInsights.properties.InstrumentationKey
    containerRegistryName: containerRegistryName
    containerRegistryUserAssignedIdentityId: containerRegistryUserAssignedIdentity.id
    applicationInsightsSecretName: applicationInsightsSecretName
    trafficsimulationPortNumber: trafficsimulationPortNumber
  }
}

// module trafficcontrolService 'container-apps/trafficcontrol-service.bicep' = {
//   name: 'trafficcontrolService-${uniqueString(resourceGroup().id)}'
//   params: {
//     trafficcontrolServiceName: trafficcontrolServiceName
//     location: location
//     tags: tags
//     containerAppsEnvironmentId: containerAppsEnvironment.id
//     serviceBusName: serviceBusName
//     serviceBusTopicName: serviceBusTopicName
//     containerRegistryName: containerRegistryName
//     containerRegistryUserAssignedIdentityId: containerRegistryUserAssignedIdentity.id
//     cosmosDbName: cosmosDbName
//     cosmosDbDatabaseName: cosmosDbDatabaseName
//     cosmosDbCollectionName: cosmosDbCollectionName
//     appInsightsInstrumentationKey: applicationInsights.properties.InstrumentationKey
//     trafficcontrolPortNumber: trafficcontrolPortNumber
//   }
// }

// module finecollectionService 'container-apps/finecollection-service.bicep' = {
//   name: 'finecollectionService-${uniqueString(resourceGroup().id)}'
//   params: {
//     finecollectionServiceName: finecollectionServiceName
//     location: location
//     tags: tags
//     containerAppsEnvironmentId: containerAppsEnvironment.id
//     serviceBusName: serviceBusName
//     containerRegistryName: containerRegistryName
//     containerRegistryUserAssignedIdentityId: containerRegistryUserAssignedIdentity.id
//     appInsightsInstrumentationKey: applicationInsights.properties.InstrumentationKey
//     finecollectionPortNumber: finecollectionPortNumber
//   }
// }

// module vehicleregistrationService 'container-apps/vehicleregistration-service.bicep' = {
//   name: 'vehicleregistrationService-${uniqueString(resourceGroup().id)}'
//   params: {
//     vehicleregistrationServiceName: vehicleregistrationServiceName
//     location: location
//     tags: tags
//     containerAppsEnvironmentId: containerAppsEnvironment.id
//     containerRegistryName: containerRegistryName
//     containerRegistryUserAssignedIdentityId: containerRegistryUserAssignedIdentity.id
//     appInsightsInstrumentationKey: applicationInsights.properties.InstrumentationKey
//     vehicleregistrationPortNumber: vehicleregistrationPortNumber
//   }
// }

// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the mail service.')
output mailServiceContainerAppName string = mailService.outputs.mailServiceContainerAppName

@description('The name of the container app for the mosquitto service.')
output mosquittoServiceContainerAppName string = mosquittoService.outputs.mosquittoServiceContainerAppName

// @description('The name of the container app for the front end finecollection service.')
// output finecollectionServiceContainerAppName string = finecollectionService.outputs.finecollectionServiceContainerAppName

// @description('The name of the container app for the front end trafficcontrol service.')
// output trafficcontrolServiceContainerAppName string = trafficcontrolService.outputs.trafficcontrolServiceContainerAppName

// @description('The name of the container app for the front end trafficsimulation service.')
// output trafficsimulationServiceContainerAppName string = trafficsimulationService.outputs.trafficsimulationServiceContainerAppName

// @description('The name of the container app for the front end vehicleregistration service.')
// output vehicleregistrationServiceContainerAppName string = vehicleregistrationService.outputs.vehicleregistrationServiceContainerAppName

