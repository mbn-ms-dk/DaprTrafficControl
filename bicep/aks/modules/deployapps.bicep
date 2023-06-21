targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@description('The name of AKS cluster.')
param clusterName string

@description('The name of the keyvault')
param keyVaultName string

@description('The name of the application insights.')
param applicationInsightsName string

@description('Application insights secret name.')
param applicationInsightsSecretName string

@description('The name of the service for the visualsimulation service. The name is use as Dapr App ID.')
param visualsimulationServiceName string

@description('The location where the resources will be created.')
param location string = resourceGroup().location

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

// ------------------
//    RESOURCES
// ------------------
resource aks 'Microsoft.ContainerService/managedClusters@2023-04-02-preview' existing = {
  name: clusterName
}

resource appi 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

// ------------------
//    DEPLOYMENT
// ------------------
@description('Dapr configuration')
module dapr_config 'apps/config.bicep' = {
  name: 'dapr-config-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
}

@description('Create namespace for the application')
module ns 'apps/ns.bicep' = {
  name: 'ns-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
}

@description('Deploy secret store')
module secretstore 'apps/secretstore.bicep' = {
  name: 'secretstore-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
    keyVaultName: keyVaultName
  }
} 

@description('Deploy email secrets to secret store - keyvault')
module mailsecretstore 'apps/mail-server-secrets.bicep' = {
  name: 'mailsecretstore-${uniqueString(resourceGroup().id)}'
  params: {
    keyVaultName: keyVaultName
  }
  dependsOn: [
    secretstore
  ]
}


@description('Deploy application insights secrets to secret store - keyvault')
module appinsightssecretstore 'apps/app-insights-secrets.bicep' = {
  name: 'appinsightssecretstore-${uniqueString(resourceGroup().id)}'
  params: {
    keyVaultName: keyVaultName
    applicationInsightsName: applicationInsightsName
    applicationInsightsSecretName: applicationInsightsSecretName
  }
  dependsOn: [
    secretstore
  ]
}

@description('Deploy Zipkin')
module zipkin 'apps/zipkin.bicep' = {
  name: 'zipkin-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
  dependsOn: [
    ns
  ]
}

@description('Deploy email AKS secrets and assign kube secret reader role')
module mailsecretsetup 'apps/secrets.bicep' = {
  name: 'mailsecretsetup-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
  dependsOn: [
    ns
    mailsecretstore
  ]
}

@description('Deploy email dapr component')
module maildapr 'apps/email-dapr.bicep' = {
  name: 'maildapr-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
  dependsOn: [
    ns
    mailsecretsetup
  ]
}

@description('Deploy mailserver service')
module mailserver 'apps/mailserver.bicep' = {
  name: 'mailserver-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
  dependsOn: [
    ns
    mailsecretsetup
    maildapr
  ]
}

@description('Deploy visualsimulation service')
module visualsimulation 'apps/visualsimulation.bicep' = {
  name: 'visualsimulation-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
    location: location
    visualsimulationServiceName: visualsimulationServiceName
    containerRegistryName: containerRegistryName
    applicationInsightsSecretName: applicationInsightsSecretName
  }
  dependsOn: [
    ns
    secretstore
  ]
}
