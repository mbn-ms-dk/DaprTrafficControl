targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {}

@description('The resource Id of the container apps environment.')
param containerAppsEnvironmentId string

@description('The key vault name store secrets')
param keyVaultName string

@description('The name of the service for the finecollection service. The name is use as Dapr App ID.')
param finecollectionServiceName string

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerUserAssignedManagedIdentityId string

// Service Bus
@description('The name of the service bus namespace.')
param serviceBusName string

@secure()
@description('The Application Insights Instrumentation.')
param appInsightsInstrumentationKey string

@description('Application Insights secret name')
param applicationInsightsSecretName string

@description('The target and dapr port for the finecollection service.')
param finecollectionPortNumber int


// ------------------
// MODULES
// ------------------

module buildfinecollection 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: finecollectionServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'FineCollectionService'
    imageName: 'finecollection'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

// ------------------
// RESOURCES
// ------------------

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}
  
resource finecollectionService 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: finecollectionServiceName
  location: location
  tags: union(tags, { containerApp: finecollectionServiceName })
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
        '${containerUserAssignedManagedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: false
        targetPort: finecollectionPortNumber
      }
      dapr: {
        enabled: true
        appId: finecollectionServiceName
        appProtocol: 'http'
        appPort: finecollectionPortNumber
        logLevel: 'info'
        enableApiLogging: true
      }
      secrets: [
        {
          name: applicationInsightsSecretName
          value: appInsightsInstrumentationKey
        }
      ]
      registries: !empty(containerRegistryName) ? [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: containerUserAssignedManagedIdentityId
        }
      ] : []
    }
    template: {
      containers: [
        {
          name: finecollectionServiceName
          image: buildfinecollection.outputs.acrImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'ApplicationInsights__InstrumentationKey'
              secretRef: applicationInsightsSecretName
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

// Enable consume from servicebus using system managed identity.
resource finecollectionService_sb_role_assignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, finecollectionService.name, '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0')
  properties: {
    principalId: finecollectionService.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0') // Azure Service Bus Data Receiver.
    principalType: 'ServicePrincipal'
  } 
  scope: serviceBusNamespace
}

//add access tro keyvault
module kvr 'kv-rbac.bicep' = {
  name: 'kvrbac-${uniqueString(resourceGroup().id)}'
  params: {
    keyVaultName: keyVaultName
    servicePrincipalId: finecollectionService.identity.principalId
  }
}

// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the frontend web app service.')
output finecollectionServiceContainerAppName string = finecollectionService.name
