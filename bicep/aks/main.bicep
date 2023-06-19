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
}

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

module aks 'modules/aks.bicep' = {
  name: 'aks-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    workspaceName: aks_law.outputs.LogAnalyticsName
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
    defenderForContainers: true
    daprAddon: true
  }
}

module acr 'modules/container-registry.bicep' = {
  name: 'acr-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    logAnalyticsWorkspaceId: aks_law.outputs.LogAnalyticsId
  }
}

module kv 'modules/key-vault.bicep' = {
  name: 'kv-${uniqueString(resourceGroup().id)}'
  params: {
    location: location
    tags: tags
    logAnalyticsWorkspaceId: aks_law.outputs.LogAnalyticsId
  }
}

module deploy 'modules/deployapps.bicep' = {
  name: 'deploy-${uniqueString(resourceGroup().id)}'
  params: {
    clusterName: aks.outputs.aksClusterName
  }
}

output aksOidcIssuerUrl string = aks.outputs.aksOidcIssuerUrl
output aksClusterName string = aks.outputs.aksClusterName
output aksAcrName string = acr.outputs.containerRegistryName
output keyVaultName string = kv.outputs.keyVaultName
