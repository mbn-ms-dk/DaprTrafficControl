targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@secure()
param kubeConfig string

@description('Aks workload identity service account name')
param serviceAccountNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreNamespace_dtc 'core/Namespace@v1' = {
  metadata: {
    name: serviceAccountNameSpace
    labels: {
      name: serviceAccountNameSpace
    }
  }
}
