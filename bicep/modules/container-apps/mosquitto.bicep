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

@description('The name of the service for the mosquitto service. The name is use as Dapr App ID.')
param mosquittoServiceName string

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerUserAssignedManagedIdentityId string

@description('The target and dapr port for the mosquitto service.')
param mosquittoPortNumber int

// ------------------
// RESOURCES
// ------------------

// ------------------
// MODULES
// ------------------

module buildMosquitto 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: mosquittoServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    buildWorkingDirectory: 'mosquitto'
    imageName: 'mosquitto'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

// ------------------
// RESOURCES
// ------------------
resource mosquittoService 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: mosquittoServiceName
  location: location
  tags: union(tags, { containerApp: mosquittoServiceName })
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
        targetPort: mosquittoPortNumber
        exposedPort: mosquittoPortNumber
        transport: 'tcp'
      }
      dapr: {
        enabled: true
        appId: mosquittoServiceName
        appProtocol: 'http'
        appPort: mosquittoPortNumber
        logLevel: 'info'
        enableApiLogging: true
      }
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
          name: mosquittoServiceName
          image: buildMosquitto.outputs.acrImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
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

@description('The name of the container app for the mosquitto service.')
output mosquittoServiceContainerAppName string = mosquittoService.name

@description('The endpoint of the mosquitto service.')
output mosquittoEndpoint string = mosquittoService.properties.configuration.ingress.fqdn
