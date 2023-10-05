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

@description('The name of the service for the zipkin service. The name is use as Dapr App ID.')
param zipkinServiceName string

@description('The target and dapr port for the zipkin service.')
param zipkinPortNumber int


// ------------------
// RESOURCES
// ------------------

resource zipkinService 'Microsoft.App/containerApps@2023-05-02-preview' = {
  name: zipkinServiceName
  location: location
  tags: union(tags, { containerApp: zipkinServiceName })
  identity: {
    type: 'SystemAssigned'
    }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: false
        targetPort: zipkinPortNumber
      }
      dapr: {
        enabled: true
        appId: zipkinServiceName
        appProtocol: 'http'
        appPort: zipkinPortNumber
        logLevel: 'info'
        enableApiLogging: true
      }
    }
    template: {
      containers: [
        {
          name: zipkinServiceName
          image: 'maildev/maildev:2.0.5'
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

@description('The name of the container app for the frontend web app service.')
output zipkinServiceContainerAppName string = zipkinService.name
