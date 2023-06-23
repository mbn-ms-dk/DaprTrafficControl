targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@secure()
param kubeConfig string

@description('Service account namespace')
param serviceAccountNameSpace string
@description('Application insights secret name.')
param applicationInsightsSecretName string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource secretsStoreCsiXK8sIoSecretProviderClass_azureSync 'secrets-store.csi.x-k8s.io/SecretProviderClass@v1' = {
  metadata: {
    name: 'azure-sync'
    namespace: serviceAccountNameSpace
  }
  spec: {
    provider: 'azure'
    secretObjects: [
      {
        secretName: applicationInsightsSecretName
        type: 'Opaque'
        data: [
          {
            key: 'appinsights-connectionstring'
            objectName: 'appinsights-connectionstring'
          }
        ]
      }
      {
        secretName: 'smtp-user'
        type: 'Opaque'
        data: [
          {
            key: 'smtp.user'
            objectName: 'smtp.user'
          }
        ]
      }
      {
        secretName: 'smtp-password'
        type: 'Opaque'
        data: [
          {
            key: 'smtp.password'
            objectName: 'smtp.password'
          }
        ]
      }
    ]
  }
}
