targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@secure()
param kubeConfig string


@description('Aks namespace')
param aksNameSpace string

@description('Dapr config name')
param daprConfigName string = 'appconfig'

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig

}

resource daprIoConfiguration_daprConfig 'dapr.io/Configuration@v1alpha1' = {
  metadata: {
    name: daprConfigName
    namespace: aksNameSpace
  }
  spec: {
    tracing: {
      samplingRate: '1'
      zipkin: {
        endpointAddress: 'http://${aksNameSpace}-zipkin:9411/api/v2/spans'
      }
    }
  }
}
