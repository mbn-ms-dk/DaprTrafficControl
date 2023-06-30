@secure()
param kubeConfig string

param keyVaultName string
@description('Aks namespace')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource daprIoComponent_azurekeyvault 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: 'azurekeyvault'
    namespace: aksNameSpace
  }
  spec: {
    type: 'secretstores.azure.keyvault'
    version: 'v1'
    metadata: [
      {
        name: 'vaultName'
        value: keyVaultName
      }
    ]
  }
}
