targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@secure()
param kubeConfig string

@description('Aks namespace')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreNamespace_dtc 'core/Namespace@v1' = {
  metadata: {
    name: aksNameSpace
    labels: {
      name: aksNameSpace
    }
  }
}
