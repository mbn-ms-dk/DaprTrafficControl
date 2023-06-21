param kubeConfig string

@description('The name of the service for the visualsimulation service. The name is use as Dapr App ID.')
param visualsimulationServiceName string

@description('The location where the resources will be created.')
param location string = resourceGroup().location

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('Application Insights secret name')
param applicationInsightsSecretName string

module buildvisualsimulation 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: visualsimulationServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'VisualSimulation'
    imageName: 'dtc/visualsimulation'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource appsDeployment_uisim 'apps/Deployment@v1' = {
  metadata: {
    labels: {
      app: visualsimulationServiceName
      version: 'v1'
    }
    name: visualsimulationServiceName
    namespace: 'dtc'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: visualsimulationServiceName
      }
    }
    strategy: {
      type: 'Recreate'
    }
    template: {
      metadata: {
        labels: {
          app: visualsimulationServiceName
        }
      }
      spec: {
        containers: [
          {
            name: visualsimulationServiceName
            image: buildvisualsimulation.outputs.acrImage
            imagePullPolicy: 'IfNotPresent'
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
            ports: [
              {
                containerPort: 5123
              }
            ]
          }
        ]
      }
    }
  }
}

resource coreService_uisim 'core/Service@v1' = {
  metadata: {
    labels: {
      app: 'uisim'
    }
    name: 'uisim'
    namespace: 'dtc'
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        name: 'web'
        port: 5123
        targetPort: 5123
      }
    ]
    selector: {
      app: 'uisim'
    }
  }
}
