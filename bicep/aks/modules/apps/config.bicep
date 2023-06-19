@secure()
param kubeConfig string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource daprIoConfiguration_daprConfig 'dapr.io/Configuration@v1alpha1' = {
  metadata: {
    name: 'daprconfig'
  }
  spec: {
    tracing: {
      samplingRate: '1'
      zipkin: {
        endpointAddress: 'http://zipkin:9411/api/v2/spans'
      }
    }
  }
}
