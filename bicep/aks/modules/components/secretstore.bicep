targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@secure()
param kubeConfig string
@description('The name of the keyvault')
param keyVaultName string
@description('Aks namespace')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
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
