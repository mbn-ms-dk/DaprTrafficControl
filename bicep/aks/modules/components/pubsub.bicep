@secure()
param kubeConfig string

@description('The name of the service bus namespace.')
param serviceBusName string

@description('The name of the service for the traffic control service. The name is used as Dapr App ID.')
param trafficcontrolserviceServiceName string

@description('The name of the service for the finecollection service. The name is used as Dapr App ID and as the name of service bus topic subscription.')
param finecollectionserviceServiceName string

@description('Aks namespace')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource daprIoComponent_pubsub 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: 'pubsub'
    namespace: aksNameSpace
  }
  spec: {
    type: 'pubsub.azure.servicebus'
    version: 'v1'
    metadata: [
      {
        name: 'namespaceName'
        value: '${serviceBusName}.servicebus.windows.net'
      }
      {
        name: 'consumerID'
        value: finecollectionserviceServiceName
      }
    ]
  }
  scopes: [
    trafficcontrolserviceServiceName
    finecollectionserviceServiceName
  ]
}
