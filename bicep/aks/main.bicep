targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('Optional. The tags to be assigned to the created resources.')
param tags object = {
  solution: 'daprtrafficcontrol'
  shortName: 'dtc'
  iac: 'bicep'
  environment: 'aks'
  namespace: aksNameSpace
}

@description('Application Insights secret name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param applicationInsightsSecretName string 

// Service Bus
@description('Optional. The name of the service bus namespace. If set, it overrides the name generated by the template.')
param serviceBusName string = 'sb-${uniqueString(resourceGroup().id)}'

@description('The name of the service bus topic.')
param serviceBusTopicName string

@description('The name of the service bus topic\'s authorization rule.')
param serviceBusTopicAuthorizationRuleName string

// Cosmos DB
@description('Optional. The name of Cosmos DB resource. If set, it overrides the name generated by the template.')
param cosmosDbName string ='cosmo-${uniqueString(resourceGroup().id)}'

@description('The name of Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string

// Services
@description('The name of the service for the mosquitto service. The name is use as Dapr App ID.')
param mosquittoServiceName string  = '${aksNameSpace}-mosquitto'

@description('The name of the service for the mail service. The name is use as Dapr App ID.')
param mailServiceName string = '${aksNameSpace}-mail'

@description('The name of the service for the finecollection service. The name is use as Dapr App ID and as the name of service bus topic subscription.')
param finecollectionServiceName string = '${aksNameSpace}-finecollection'

@description('The name of the service for the trafficcontrol service. The name is use as Dapr App ID.')
param trafficcontrolServiceName string = '${aksNameSpace}-trafficcontrol'

@description('The name of the service for the trafficsimulation service. The name is use as Dapr App ID.')
param trafficsimulationServiceName string = '${aksNameSpace}-trafficsimulation'

@description('The name of the service for the visualsimulation service. The name is use as Dapr App ID.')
param visualsimulationServiceName string = '${aksNameSpace}-visualsimulation'

@description('The name of the service for the vehicleregistration service. The name is use as Dapr App ID.')
param vehicleregistrationServiceName string = '${aksNameSpace}-vehicleregistration'

// App Ports
@description('The target and dapr port for the mosquitto service.')
param mosquittoPortNumber int = 1883

@description('The target and dapr port for the mail service.')
param mailPortNumber int = 1025

@description('The dapr port for the finecollection service.')
param finecollectionPortNumber int = 5158

@description('The dapr port for the trafficcontrol service.')
param trafficcontrolPortNumber int = 5047

@description('The dapr port for the trafficsimulation service.')
param trafficsimulationPortNumber int = 5286

@description('The dapr port for the vehicleregistration service.')
param vehicleregistrationPortNumber int = 5287

@description('The target and dapr port for the visualsimulation service.')
param visualsimulationPortNumber int = 5123

@description('Use the mosquitto broker for MQTT communication. if false it uses Http')
param useMosquitto bool = false

@description('Use actors in traffic control service')
param useActors bool = false

@description('Aks workload identity service account name')
param serviceAccountName string

@description('Aks workload identity namespace')
param aksNameSpace string

@description('Secret Provider Class Name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param secretProviderClassName string

@description('Mail server secret username')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerUserSecretsName string


@description('Mail server secret password name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerPasswordSecretsName string

@description('Optional. The principal ID to assign the AKS/grafana admin role.')
param adminPrincipalId string = '2f6b4e5f-aa31-4446-b0d4-045883ff2ce9'

// ------------------
//    MODULES
// ------------------
module aks_law 'modules/law.bicep' = {
    name: 'aks_law-${uniqueString(resourceGroup().id)}'
    params: {
        location: location
        tags: tags
    }
}

module serviceBus 'modules/service-bus.bicep' = {
  name: 'serviceBus-${uniqueString(resourceGroup().id)}'
  params: {
    serviceBusName: serviceBusName
    location: location
    tags: tags
    serviceBusTopicName: serviceBusTopicName
    serviceBusTopicAuthorizationRuleName: serviceBusTopicAuthorizationRuleName
    finecollectionServiceName: finecollectionServiceName
  }
}

module cosmosDb 'modules/cosmos-db.bicep' = {
  name: 'cosmosDb-${uniqueString(resourceGroup().id)}'
  params: {
    cosmosDbName: cosmosDbName
    location: location
    tags: tags
    cosmosDbDatabaseName: cosmosDbDatabaseName
    cosmosDbCollectionName: cosmosDbCollectionName 
  }
}

module aks 'modules/aks.bicep' = {
  name: 'aks-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    workspaceName: aks_law.outputs.LogAnalyticsName
    serviceAccountName: serviceAccountName
    aksNameSpace: aksNameSpace
    adminPrincipalId: adminPrincipalId
    omsagent: true
    enable_aad: true
    enableAzureRBAC: true
    agentCount: 1
    agentCountMax: 3
    //enable workload identity
    workloadIdentity: true
    //workload identity requires OIDCIssuer to be configured on AKS
    oidcIssuer: true
    //enable CSI driver for Keyvault
    keyVaultAksCSI: true
    //enable defender for containers
    defenderForContainers: true
    //enable dapr
    daprAddon: true
    //enable dapr HA
    daprAddonHA: true
    //enable prometheus and grafana
    enableMonitoring: true
  }
  dependsOn: [
    aks_law
    cosmosDb
  ] 
}

module cosmosrbac 'modules/cosmosRbac.bicep' = {
  name: 'cosmosrbac-${uniqueString(resourceGroup().id)}'
  params: {
    cosmosDbName: cosmosDbName
    appclientId: aks.outputs.appIdentityPrincipalId
  }
  dependsOn: [
    aks
  ]
}

module acr 'modules/container-registry.bicep' = {
  name: 'acr-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    aksClusterName: aks.outputs.aksClusterName
  }
  dependsOn: [
    aks
  ]
}

module kv 'modules/key-vault.bicep' = {
  name: 'kv-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    keyVaultCreate: true
    keyVaultAksCSI: true
    aksClusterName: aks.outputs.aksClusterName
    keyVaultPurgeProtection: false
    keyVaultSoftDelete: false
  }
  dependsOn: [
    aks
  ]
}

var secretofficer = [
    aks.outputs.appIdentityPrincipalId
    aks.outputs.kvIdentityClientId
    aks.outputs.kubeletIdenedityClientId
]
module kvrbc 'modules/keyvaultrbac.bicep' = {
  name: 'kvrbc-${uniqueString(resourceGroup().id)}'
  params: {
    keyVaultName: kv.outputs.keyVaultName
    rbacSecretOfficerSps: secretofficer
  }
  dependsOn: [
    kv
  ]
}

module deploy 'modules/deployapps.bicep' = {
  name: 'deploy-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    aksNameSpace: aksNameSpace
    secretProviderClassName: secretProviderClassName
    aksUserAssignedClientId: aks.outputs.appIdentityClientId
    aksUserAssignedPrincipalId: aks.outputs.appIdentityPrincipalId
    containerRegistryName: acr.outputs.containerRegistryName
    clusterName: aks.outputs.aksClusterName
    keyVaultName: kv.outputs.keyVaultName
    cosmosDbName: cosmosDb.outputs.cosmosDbName
    cosmosDbCollectionName: cosmosDb.outputs.cosmosDbCollectionName
    cosmosDbDatabaseName: cosmosDb.outputs.cosmosDbDatabaseName
    serviceBusName: serviceBus.outputs.serviceBusName
    serviceBusTopicName: serviceBus.outputs.serviceBusTopicName
    applicationInsightsName: aks_law.outputs.applicationInsightsName
    applicationInsightsSecretName: applicationInsightsSecretName
    serviceAccountName: serviceAccountName
    visualsimulationServiceName: visualsimulationServiceName
    visualsimulationPortNumber: visualsimulationPortNumber
    mailServiceName: mailServiceName
    mosquittoServiceName: mosquittoServiceName
    trafficcontrolServiceName: trafficcontrolServiceName
    trafficcontrolPortNumber: trafficcontrolPortNumber
    useMosquitto: useMosquitto
    useActors: useActors
    finecollectionServiceName: finecollectionServiceName
    mailServerUserSecretsName: mailServerUserSecretsName
    mailServerPasswordSecretsName: mailServerPasswordSecretsName
  }
  dependsOn: [
    aks
    acr
    kv
    cosmosDb
    serviceBus
  ]
}

// output aksOidcIssuerUrl string = aks.outputs.aksOidcIssuerUrl
// output aksClusterName string = aks.outputs.aksClusterName
// output aksAcrName string = acr.outputs.containerRegistryName
// output keyVaultName string = kv.outputs.keyVaultName