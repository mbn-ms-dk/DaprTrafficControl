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

@description('The name of the service for the vehicleregistration service. The name is use as Dapr App ID.')
param vehicleregistrationServiceName string

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerUserAssignedManagedIdentityId string

@secure()
@description('The Application Insights Instrumentation.')
param appInsightsInstrumentationKey string

@description('The target and dapr port for the vehicleregistration service.')
param vehicleregistrationPortNumber int

@description('Application Insights secret name')
param applicationInsightsSecretName string


// ------------------
// MODULES
// ------------------

module buildvehicleregistration 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: vehicleregistrationServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'VehicleRegistrationService'
    imageName: 'dtc/vehicleregistration'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

// ------------------
// RESOURCES
// ------------------

resource vehicleregistrationService 'Microsoft.App/containerApps@2023-04-01-preview' = {
  name: vehicleregistrationServiceName
  location: location
  tags: union(tags, { containerApp: vehicleregistrationServiceName })
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
        targetPort: vehicleregistrationPortNumber
      }
      dapr: {
        enabled: true
        appId: vehicleregistrationServiceName
        appProtocol: 'http'
        appPort: vehicleregistrationPortNumber
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
          name: vehicleregistrationServiceName
          image: buildvehicleregistration.outputs.acrImage
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

@description('The name of the container app for the frontend web app service.')
output vehicleregistrationServiceContainerAppName string = vehicleregistrationService.name
