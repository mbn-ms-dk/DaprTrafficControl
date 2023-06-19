targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@description('The name of AKS cluster.')
param clusterName string

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
