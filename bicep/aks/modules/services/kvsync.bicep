@secure()
param kubeConfig string

@description('Aks namespace')
param aksNameSpace string

@description('Secret Provider Class Name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param secretProviderClassName string

@description('Aks userassigned client id')
param aksUserAssignedClientId string

@description('The name of the keyvault')
param keyVaultName string

@description('Application insights secret name.')
param applicationInsightsSecretName string

@description('Mail server secret username')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerUserSecretsName string

@description('Mail server secret password name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerPasswordSecretsName string



import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
}

resource secretsStoreCsiXK8sIoSecretProviderClass_dtcAzureKvsync 'secrets-store.csi.x-k8s.io/SecretProviderClass@v1' = {
  metadata: {
    name: secretProviderClassName
    namespace: aksNameSpace
  }
  spec: {
    provider: 'azure'
    parameters: {
      usePodIdentity: 'false'
      useVMManagedIdentity: 'false' // set to true if using system identity
      clientID: aksUserAssignedClientId
      keyvaultName: keyVaultName
      cloudName: ''
      tenantId: subscription().tenantId
      objects: [
        {
          objectName: applicationInsightsSecretName
          objectType: 'secret'    // object types: secret, key, or cert
          objectVersion: ''       // default to latest if empty
        }
        {
          objectName: mailServerUserSecretsName
          objectType: 'secret'    // object types: secret, key, or cert
          objectVersion: ''       // default to latest if empty
        }
        {
          objectName: mailServerPasswordSecretsName
          objectType: 'secret'    // object types: secret, key, or cert
          objectVersion: ''       // default to latest if empty
        }
      ]
    }
    secretObjects: [
      {
        secretName: applicationInsightsSecretName
        type: 'Opaque'
        data: {
            key: 'appinsights-connection-string'
            objectName: applicationInsightsSecretName
          }
      }
      {
        secretName: mailServerUserSecretsName
        type: 'Opaque'
        data: {
            key: 'smtp.user'
            objectName: mailServerUserSecretsName
          }
      }
      {
        secretName: mailServerPasswordSecretsName
        type: 'Opaque'
        data: {
            key: 'smtp.password'
            objectName: mailServerPasswordSecretsName
          }
      }
    ]
  }
}
