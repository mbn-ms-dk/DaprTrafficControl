@secure()

param kubeConfig string

@description('Aks workload identity service account name')
param serviceAccountNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource appsDeployment_zipkin 'apps/Deployment@v1' = {
  metadata: {
    name: 'zipkin'
    namespace: serviceAccountNameSpace
    labels: {
      service: 'zipkin'
    }
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        service: 'zipkin'
      }
    }
    template: {
      metadata: {
        labels: {
          service: 'zipkin'
        }
      }
      spec: {
        containers: [
          {
            name: 'zipkin'
            image: 'openzipkin/zipkin-slim'
            imagePullPolicy: 'IfNotPresent'
            ports: [
              {
                name: 'http'
                containerPort: 9411
                protocol: 'TCP'
              }
            ]
          }
        ]
      }
    }
  }
}

resource coreService_zipkin 'core/Service@v1' = {
  metadata: {
    name: 'zipkin'
    namespace: serviceAccountNameSpace
    labels: {
      service: 'zipkin'
    }
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        port: 9411
        targetPort: 9411
        protocol: 'TCP'
        name: 'zipkin'
      }
    ]
    selector: {
      service: 'zipkin'
    }
  }
}
