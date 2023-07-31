@secure()
param kubeConfig string
@description('Aks workload identity client id')
param aksUserAssignedClientId string
@description('Aks workload identity service account name')
param serviceAccountName string = 'daprtrafficcontrol'
@description('Aks namespace')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
}

resource coreServiceAccount_SERVICE_ACCOUNT_NAME 'core/ServiceAccount@v1' = {
  metadata: {
    annotations: {
      'azure.workload.identity/client-id': aksUserAssignedClientId
    }
    labels: {
      'azure.workload.identity/use': 'true'
    }
    name: serviceAccountName
    namespace: aksNameSpace
  }
}
