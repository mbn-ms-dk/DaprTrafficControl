@secure()
param kubeConfig string

@description('Aks namespace to deploy the zipkin service')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
}

resource appsDeployment_zipkin 'apps/Deployment@v1' = {
  metadata: {
    name: '${aksNameSpace}-zipkin'
    namespace: aksNameSpace
    labels: {
      service: '${aksNameSpace}-zipkin'
    }
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        service: '${aksNameSpace}-zipkin'
      }
    }
    template: {
      metadata: {
        labels: {
          service: '${aksNameSpace}-zipkin'
        }
      }
      spec: {
        containers: [
          {
            name: '${aksNameSpace}-zipkin'
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
    name: '${aksNameSpace}-zipkin'
    namespace: aksNameSpace
    labels: {
      service: '${aksNameSpace}-zipkin'
    }
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        port: 9411
        #disable-next-line BCP036
        targetPort: 9411
        protocol: 'TCP'
        name: '${aksNameSpace}-zipkin'
      }
    ]
    selector: {
      service: '${aksNameSpace}-zipkin'
    }
  }
}
