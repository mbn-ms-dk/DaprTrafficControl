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

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerUserAssignedManagedIdentityId string

@description('The name of the service for the visualsimulation service. The name is use as Dapr App ID.')
param visualsimulationServiceName string

@description('The target and dapr port for the visualsimulation service.')
param visualsimulationPortNumber int

@secure()
@description('The Application Insights Instrumentation.')
param appInsightsInstrumentationKey string

@description('Application Insights secret name')
param applicationInsightsSecretName string

// ------------------
// MODULES
// ------------------

module buildvisualsimulation 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: visualsimulationServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'VisualSimulation'
    imageName: 'dtc/visualsimulation'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

// ------------------
// RESOURCES
// ------------------

resource visualsimulationService 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: visualsimulationServiceName
  location: location
  tags: union(tags, { containerApp: visualsimulationServiceName })
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
        external: true
        targetPort: visualsimulationPortNumber
        allowInsecure: false
      }
      dapr: {
        enabled: false
        appId: visualsimulationServiceName  
        appProtocol: 'http'
        appPort: visualsimulationPortNumber
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
          name: visualsimulationServiceName
          image: buildvisualsimulation.outputs.acrImage
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
// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the visual simulation service.')
output visualsimulationServiceContainerAppName string = visualsimulationService.name
