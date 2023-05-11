@description('The name of the environment')
param environment_name string = 'env-${uniqueSuffix}'
@description('The location of the resource group')
param location string = resourceGroup().location
param uniqueSeed string = '${subscription().subscriptionId}-${resourceGroup().name}'
param uniqueSuffix string = uniqueString(uniqueSeed)
@description('The name of the log analytics workspace')
var logAnalyticsWorkspaceName = 'logs-${environment_name}'
@description('The name of the application insights instance')
var appInsightsName = 'appins-${environment_name}'
@description('The name of the container registry')
param tmp string  = replace(environment_name, '-', '')
param containerRegistryName string = 'acr${tmp}'
@description('Use service bus for pub/sub')
param useServiceBus bool = false
param serviceBusName string = 'sb${tmp}'

//Resource log analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    retentionInDays: 30
    features: {
      search: {
        enabled: true
      }
    }
    sku: {
      name: 'PerGB2018'
    }
  }
}

//Resource application insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

//Resource container app environment
resource environment 'Microsoft.App/managedEnvironments@2022-11-01-preview' = {
  name: environment_name
  location: location
  properties: {
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

//Resource container registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

//Resource service bus
resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = if(useServiceBus) {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
}

//Resource trafficcontrol topic
resource trafficControlTopic 'Microsoft.ServiceBus/namespaces/topics@2022-10-01-preview' = if(useServiceBus) {
  parent: serviceBus
  name: 'trafficcontrol'
  properties: {
    enablePartitioning: true
  }
}

//Resource trafficcontrol/entrycam subscription
resource trafficControlEntryCamSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = if(useServiceBus) {
  parent: trafficControlTopic
  name: 'entrycam'
}

//Resource trafficcontrol/exitcam subscription
resource trafficControlExitCamSubscription 'Microsoft.ServiceBus/namespaces/topics/subscriptions@2022-10-01-preview' = if(useServiceBus) {
  parent: trafficControlTopic
  name: 'exitcam'
}

//Module publish mosquitto
module  publishMosquittoImage 'br/public:deployment-scripts/build-acr:2.0.1' = if(!useServiceBus) {
  name: 'publishMosquitto'
  params: {
    AcrName: containerRegistry.name
    location: location
    gitRepositoryUrl: 'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    buildWorkingDirectory: 'mosquitto'
    imageName: 'dtc-mosquitto'
    imageTag: 'latest'
  }
}

//module run mosquitto
module mosquitto 'br/public:app/dapr-containerapp:1.0.1' = if(!useServiceBus) {
  name: 'dtc-mosquitto'
  params: {
      location: location
      containerAppEnvName:  environment.name
      containerAppName: 'dtc-mosquitto'
      containerImage: publishMosquittoImage.outputs.acrImage
      azureContainerRegistry: containerRegistry.name
      targetPort: 1883
      enableIngress: false
  }
}

//Module publish TrafficSimulationServiceConsole
module  publishTrafficSimulationServiceConsole 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: 'publishTrafficSimulationServiceConsole'
  params: {
    AcrName: containerRegistry.name
    location: location
    gitRepositoryUrl: 'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    buildWorkingDirectory: 'TrafficSimulationServiceConsole'
    dockerfileName: 'DockerfileAca'
    imageName: 'dtc-simulation-console'
    imageTag: 'latest'
  }
}
//Resource service bus authrule for listkeys
resource listKeysAuthRule 'Microsoft.ServiceBus/namespaces/authorizationRules@2022-10-01-preview' = if(useServiceBus) {
  parent: serviceBus
  name: 'RootManageSharedAccessKey'
  properties: {
    rights: [
      'Listen'
      'Send'
      'Manage'
    ]
  }
}

// variable pub sub connection string
var sbConnectionString = useServiceBus ? listKeysAuthRule.listKeys().primaryConnectionString : ''//serviceBus.listKeys().primaryConnectionString : ''
var dtcSimConsoleEnvVars = [
  {
    name: 'SB_CONN_STRING'
    value: sbConnectionString
  }
  {
    name: 'MQTT_HOST'
    value: 'dtc-mosquitto'
  }
]

//module run mosquitto
module simServiceConsole 'br/public:app/dapr-containerapp:1.0.1' = {
  name: 'dtc-simulation-console'
  params: {
      location: location
      containerAppEnvName:  environment.name
      containerAppName: 'dtc-simulation-console'
      containerImage: publishTrafficSimulationServiceConsole.outputs.acrImage
      azureContainerRegistry: containerRegistry.name
      enableIngress: false
      environmentVariables: dtcSimConsoleEnvVars
  }
}

//resource run rabbitmq
resource rabbitmq 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'dtc-rabbitmq'
  location: location
  properties: {
    environmentId: environment.id
    configuration: {
      ingress: {
        external: false
        targetPort:5672
      }
      dapr: {
        enabled: false
      }
    }
    template: {
    containers: [
      {
        name: 'rabbitmq'
        image: 'rabbitmq:3-management-alpine'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
      }
      ]
    }
  }
}

//resource run mail-dev
resource maildev 'Microsoft.App/containerApps@2022-11-01-preview' = {
  name: 'dtc-maildev'
  location: location
  properties: {
    environmentId: environment.id
    configuration: {
      ingress: {
        external: false
        targetPort:1025
      }
      dapr: {
        enabled: false
      }
    }
    template: {
    containers: [
      {
        name: 'maildev'
        image: 'maildev/maildev:2.0.5'
        resources: {
          cpu: json('0.5')
          memory: '1.0Gi'
        }
      }
      ]
    }
  }
}
