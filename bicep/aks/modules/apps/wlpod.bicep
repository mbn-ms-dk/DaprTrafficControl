@secure()
param kubeConfig string

@description('Aks namespace')
param aksNameSpace string

@description('Secret Provider Class Name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param secretProviderClassName string

@description('Application insights secret name.')
param applicationInsightsSecretName string

@description('Aks workload identity service account name')
param serviceAccountName string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource corePod_busyboxSecretsStoreInlineUserMsi 'apps/Deployment@v1' = {
  metadata: {
    name: '${aksNameSpace}-testpod'
    namespace: aksNameSpace
    labels: {
      'azure.workload.identity/use': 'true'
    }
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'busybox'
      }
    }
    strategy: {
      type: 'Recreate'
    }
    template: {
      metadata:{
        labels: {
          app: 'busybox'
        }
      }
      spec: {
        serviceAccountName: serviceAccountName
        containers: [
          {
            name: 'busybox'
            image: 'registry.k8s.io/e2e-test-images/busybox:1.29-1'
            env: [
              {
                name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                valueFrom: {
                  secretKeyRef: {
                    name: applicationInsightsSecretName
                    key: 'appinsights-connection-string'
                  }
                }
              }
            ]
            command: [
              '/bin/sleep'
              '10000'
            ]
            volumeMounts: [
              {
                name: 'secrets-store01-inline'
                mountPath: '/mnt/secrets-store'
                readOnly: true
              }
            ]
          }
        ]
        volumes: [
          {
            name: 'secrets-store01-inline'
            csi: {
              driver: 'secrets-store.csi.k8s.io'
              readOnly: true
              volumeAttributes: {
                secretProviderClass: secretProviderClassName
              }
            }
          }
        ]
      }
    }
  }
}
