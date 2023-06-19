targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@description('The name of AKS cluster.')
param clusterName string

@description('The name of the keyvault')
param keyVaultName string

// ------------------
//    RESOURCES
// ------------------
resource aks 'Microsoft.ContainerService/managedClusters@2023-04-02-preview' existing = {
  name: clusterName
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

@description('Deploy secret store')
module secretstore 'apps/secretstore.bicep' = {
  name: 'secretstore-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
    keyVaultName: keyVaultName
  }
}

@description('Create namespace for the application')
module ns 'apps/ns.bicep' = {
  name: 'ns-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
} 

@description('Deploy Zipkin')
module zipkin 'apps/zipkin.bicep' = {
  name: 'zipkin-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
}

@description('Deploy email secrets and assign kube secret reader role')
module mailsecretsetup 'apps/secrets.bicep' = {
  name: 'mailsecretsetup-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
}

@description('Deploy email dapr component')
module maildapr 'apps/email-dapr.bicep' = {
  name: 'maildapr-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
}

@description('Deploy mailserver service')
module mailserver 'apps/mailserver.bicep' = {
  name: 'mailserver-${uniqueString(resourceGroup().id)}'
  params: {
    kubeConfig: aks.listClusterAdminCredential().kubeconfigs[0].value
  }
}
