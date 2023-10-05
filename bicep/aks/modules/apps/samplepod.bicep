@secure()
param kubeConfig string

@description('Aks namespace')
param aksNameSpace string

@description('Secret Provider Class Name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param secretProviderClassName string

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
}

resource corePod_busyboxSecretsStoreInlineUserMsi 'core/Pod@v1' = {
  metadata: {
    name: 'busybox-secrets-store-inline'
    namespace: aksNameSpace
  }
  spec: {
    containers: [
      {
        name: 'busybox'
        image: 'k8s.gcr.io/e2e-test-images/busybox:1.29-1'
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
