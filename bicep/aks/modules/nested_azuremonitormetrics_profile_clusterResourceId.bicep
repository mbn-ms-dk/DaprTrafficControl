targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@description('The AKS cluster name.')
param variables_clusterName string
@description('The location of the AKS cluster.')
param clusterLocation string
@description('The metric labels to be allowed for the kube-state-metrics.')
param metricLabelsAllowlist string = ''
@description('The metric annotations to be allowed for the kube-state-metrics.')
param metricAnnotationsAllowList string = ''
@description('The tags to be assigned to the created resources.')
param tags object = {}

// ------------------
//    RESOURCES
// ------------------
resource variables_cluster 'Microsoft.ContainerService/managedClusters@2023-01-01' = {
  name: variables_clusterName
  location: clusterLocation
  tags: tags
  properties: {
    azureMonitorProfile: {
      metrics: {
        enabled: true
        kubeStateMetrics: {
          metricLabelsAllowlist: metricLabelsAllowlist
          metricAnnotationsAllowList: metricAnnotationsAllowList
        }
      }
    }
  }
}
