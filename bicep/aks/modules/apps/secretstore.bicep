@secure()
param kubeConfig string

param keyVaultName string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource daprIoComponent_azurekeyvault 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: 'azurekeyvault'
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
