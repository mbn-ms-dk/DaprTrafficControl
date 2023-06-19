@secure()
param kubeConfig string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource appsDeployment_mailserver 'apps/Deployment@v1' = {
  metadata: {
    labels: {
      app: 'mailserver'
      version: 'v1'
    }
    name: 'mailserver'
    namespace: 'dtc'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'mailserver'
        version: 'v1'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'mailserver'
          version: 'v1'
        }
      }
      spec: {
        containers: [
          {
            image: 'maildev/maildev:2.0.5'
            imagePullPolicy: 'IfNotPresent'
            name: 'mailserver'
            ports: [
              {
                name: 'smtp'
                containerPort: 1025
                protocol: 'TCP'
              }
              {
                name: 'http'
                containerPort: 1080
                protocol: 'TCP'
              }
            ]
          }
        ]
        restartPolicy: 'Always'
      }
    }
  }
}

resource coreService_mailserver 'core/Service@v1' = {
  metadata: {
    labels: {
      app: 'mailserver'
      version: 'v1'
    }
    name: 'mailserver'
    namespace: 'dtc'
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        name: 'smtp'
        port: 25
        targetPort: 1025
        protocol: 'TCP'
      }
      {
        name: 'http'
        port: 4000
        targetPort: 1080
        protocol: 'TCP'
      }
    ]
    selector: {
      app: 'mailserver'
      version: 'v1'
    }
  }
}
