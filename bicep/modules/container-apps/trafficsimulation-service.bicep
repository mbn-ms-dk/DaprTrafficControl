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

@description('The name of the Key Vault.')
param keyVaultName string

@secure()
@description('The Application Insights Instrumentation.')
param appInsightsInstrumentationKey string

@description('The name of the service for the trafficsimulation service. The name is use as Dapr App ID.')
param trafficsimulationServiceName string

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The resource ID of the user assigned managed identity for the container registry to be able to pull images from it.')
param containerRegistryUserAssignedIdentityId string

@description('Application insights secret name.')
param applicationInsightsSecretName string

@description('The target and dapr port for the trafficsimulation service.')
param trafficsimulationPortNumber int


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
        '${containerRegistryUserAssignedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentId
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: false
        targetPort: trafficsimulationPortNumber
      }
      dapr: {
        enabled: true
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
          identity: containerRegistryUserAssignedIdentityId
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
              secretRef: applicationInsightsSecretName
            }
            {
              name: 'MQTT_HOST'
              value: 'dtc-mosquitto'
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


//RBAC on keyvault
module rbacTrafficeSimulationService 'kv-rbac.bicep' = {
  name: 'rbacTrafficSimulationService'
  params: {
    keyVaultName: keyVaultName
    servicePrincipalId: trafficsimulationService.identity.principalId
  }
}
// ------------------
// OUTPUTS
// ------------------

@description('The name of the container app for the simulation service.')
output trafficsimulationServiceContainerAppName string = trafficsimulationService.name