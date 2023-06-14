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

@secure()
@description('The Application Insights Instrumentation.')
param appInsightsInstrumentationKey string

@description('The name of the service for the trafficsimulation service. The name is use as Dapr App ID.')
param trafficsimulationServiceName string

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerUserAssignedManagedIdentityId string

@description('The target and dapr port for the trafficsimulation service.')
param trafficsimulationPortNumber int

@description('Use the mosquitto broker for MQTT communication. if false it uses Http')
param useMosquitto bool = false

@description('The name of traffic control service')
param trafficControlServiceName string = 'dtc-trafficcontrol'

// @description('The dapr port for the trafficcontrol service.')
// param trafficcontrolPortNumber int

@description('The name of the mosquitto broker.')
param mosquittoBrokerName string = 'dtc-mosquitto'


// ------------------
// MODULES
// ------------------

module buildtrafficsimulation 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: trafficsimulationServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    //buildWorkingDirectory: 'TrafficSimulationServiceConsole'
    dockerfileDirectory: 'TrafficSimulationServiceConsole'
    imageName: 'trafficsimulation'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

// ------------------
// RESOURCES
// ------------------

resource trafficsimulationService 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: trafficsimulationServiceName
  location: location
  tags: tags
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
        targetPort: trafficsimulationPortNumber
        allowInsecure: true
      }
      dapr: {
        enabled: false
        appId: trafficsimulationServiceName
        appProtocol: 'http'
        appPort: trafficsimulationPortNumber
        logLevel: 'info'
        enableApiLogging: true
      }
      secrets: [
        {
          name: 'appinsights-key'
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
          name: trafficsimulationServiceName
          image: buildtrafficsimulation.outputs.acrImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'ApplicationInsights__InstrumentationKey'
              secretRef: 'appinsights-key'
            }
            {
              name: 'USE_MOSQUITTO'
              value: '${useMosquitto}'
            }
            {
              name: 'MQTT_HOST'
              value: mosquittoBrokerName
            }
            {
              name: 'TRAFFIC_CONTROL_ENDPOINT'
              value: 'http://${trafficControlServiceName}'
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

@description('The name of the container app for the simulation service.')
output trafficsimulationServiceContainerAppName string = trafficsimulationService.name
