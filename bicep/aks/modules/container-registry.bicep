targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The tags to be assigned to the created resources.')
param tags object = {}

@description('The id of the log analytics workspace to use for diagnostics.')
param logAnalyticsWorkspaceId string = ''

@description('The name of the exissting AKS cluster to integrate with the KeyVault')
param aksClusterName string = ''

@description('The principal ID of the service principal to assign the push role to the ACR')
param acrPushRolePrincipalId string = ''

@allowed([
  ''
  'Basic'
  'Standard'
  'Premium'
])
@description('The SKU to use for the Container Registry')
param registries_sku string = 'Basic'

resource aks 'Microsoft.ContainerService/managedClusters@2023-04-02-preview' existing = {
  name: aksClusterName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'acr-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: registries_sku
  }
  properties: {
    adminUserEnabled: true
  }
}

resource acrDiags 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(registries_sku)) {
  name: 'acrDiags'
  scope: acr
  properties: {
    workspaceId:logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        timeGrain: 'PT1M'
      }
    ]
  }
}

var AcrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var KubeletObjectId = any(aks.properties.identityProfile.kubeletidentity).objectId

resource aks_acr_pull 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(registries_sku)) {
  scope: acr // Use when specifying a scope that is different than the deployment scope
  name: guid(aks.id, 'Acr' , AcrPullRole)
  properties: {
    roleDefinitionId: AcrPullRole
    principalType: 'ServicePrincipal'
    principalId: KubeletObjectId
  }
}

var AcrPushRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8311e382-0749-4cb8-b61a-304f252e45ec')

resource aks_acr_push 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(registries_sku) && !empty(acrPushRolePrincipalId)) {
  scope: acr // Use when specifying a scope that is different than the deployment scope
  name: guid(aks.id, 'Acr' , AcrPushRole)
  properties: {
    roleDefinitionId: AcrPushRole
    principalType: 'ServicePrincipal'
    principalId: acrPushRolePrincipalId
  }
}

param imageNames array = []

module acrImport 'br/public:deployment-scripts/import-acr:3.0.1' = if (!empty(registries_sku) && !empty(imageNames)) {
  name: take('${deployment().name}-AcrImport',64)
  params: {
    acrName: acr.name
    location: location
    images: imageNames
    managedIdentityName: 'id-acrImport-${location}'
  }
}


output containerRegistryName string = !empty(registries_sku) ? acr.name : ''
output containerRegistryId string = !empty(registries_sku) ? acr.id : ''

