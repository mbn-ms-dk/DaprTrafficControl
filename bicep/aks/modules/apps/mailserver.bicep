@secure()
param kubeConfig string

@description('The name of the service for the mail service. The name is use as Dapr App ID.')
param mailServiceName string


@description('The target and dapr port for the mail service.')
param mailPortNumber int

@description('Aks namespace where the mail service will be deployed.')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource appsDeployment_mailserver 'apps/Deployment@v1' = {
  metadata: {
    labels: {
      app: mailServiceName
      version: 'v1'
    }
    name: mailServiceName
    namespace: aksNameSpace
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: mailServiceName
        version: 'v1'
      }
    }
    template: {
      metadata: {
        labels: {
          app: mailServiceName
          version: 'v1'
        }
      }
      spec: {
        containers: [
          {
            image: 'maildev/maildev:2.0.5'
            imagePullPolicy: 'IfNotPresent'
            name: mailServiceName
            ports: [
              {
                name: 'smtp'
                containerPort: mailPortNumber
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
      app: mailServiceName
      version: 'v1'
    }
    name: mailServiceName
    namespace: aksNameSpace
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        name: 'smtp'
        port: 25
        #disable-next-line BCP036
        targetPort: mailPortNumber
        protocol: 'TCP'
      }
      {
        name: 'http'
        port: 4000
        #disable-next-line BCP036        
        targetPort: 1080
        protocol: 'TCP'
      }
    ]
    selector: {
      app: mailServiceName
      version: 'v1'
    }
  }
}
