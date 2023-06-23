@secure()
param kubeConfig string

@description('Aks workload identity service account name')
param serviceAccountNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource daprIoComponent_sendmail 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: 'sendmail'
    namespace: serviceAccountNameSpace
  }
  spec: {
    type: 'bindings.smtp'
    version: 'v1'
    metadata: [
      {
        name: 'host'
        value: 'mailserver'
      }
      {
        name: 'port'
        value: 25
      }
      {
        name: 'user'
        secretKeyRef: {
          name: 'trafficcontrol-secrets'
          key: 'smtp-user'
        }
      }
      {
        name: 'password'
        secretKeyRef: {
          name: 'trafficcontrol-secrets'
          key: 'smtp-password'
        }
      }
      {
        name: 'skipTLSVerify'
        value: true
      }
    ]
  }
  scopes: [
    'finecollectionservice'
  ]
}
