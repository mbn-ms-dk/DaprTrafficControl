@secure()
param kubeConfig string

@description('Aks namespace')
param aksNameSpace string

@description('Mail server secret username')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerUserSecretsName string


@description('Mail server secret password name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerPasswordSecretsName string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource daprIoComponent_sendmail 'dapr.io/Component@v1alpha1' = {
  metadata: {
    name: 'sendmail'
    namespace: aksNameSpace
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
          name: mailServerUserSecretsName
          key: 'smtp.user'
        }
      }
      {
        name: 'password'
        secretKeyRef: {
          name: mailServerPasswordSecretsName
          key: 'smtp.password'
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
