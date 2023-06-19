targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@secure()
param kubeConfig string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreNamespace_dtc 'core/Namespace@v1' = {
  metadata: {
    name: 'dtc'
    labels: {
      name: 'dtc'
    }
  }
}
