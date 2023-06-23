@secure()
param kubeConfig string
@description('Aks workload identity id')
param userAssignedClientId string
@description('Aks workload identity service account name')
param serviceAccountName string = 'daprtrafficcontrol'
@description('Aks workload identity service account name')
param serviceAccountNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreServiceAccount_SERVICE_ACCOUNT_NAME 'core/ServiceAccount@v1' = {
  metadata: {
    annotations: {
      'azure.workload.identity/client-id': userAssignedClientId
    }
    labels: {
      'azure.workload.identity/use': 'true'
    }
    name: serviceAccountName
    namespace: serviceAccountNameSpace
  }
}
