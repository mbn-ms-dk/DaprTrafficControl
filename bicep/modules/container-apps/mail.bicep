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

@description('The name of the service for the mail service. The name is use as Dapr App ID.')
param mailServiceName string

@description('The target and dapr port for the mail service.')
param mailPortNumber int


// ------------------
// RESOURCES
// ------------------

resource mailService 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: mailServiceName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: false
        targetPort: mailPortNumber
      }
      dapr: {
        enabled: true
        appId: mailServiceName
        appProtocol: 'http'
        appPort: mailPortNumber
        logLevel: 'info'
        enableApiLogging: true
      }
    }
    template: {
      containers: [
        {
          name: mailServiceName
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
output mailServiceContainerAppName string = mailService.name
