targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
param kubeConfig string

@description('The name of the service for the visualsimulation service. The name is use as Dapr App ID.')
param visualsimulationServiceName string

@description('The target and dapr port for the visualsimulation service.')
param visualsimulationPortNumber int

@description('The location where the resources will be created.')
param location string = resourceGroup().location

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('Application Insights secret name')
param applicationInsightsSecretName string

@description('Aks workload identity service account name')
param serviceAccountNameSpace string

module buildvisualsimulation 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: visualsimulationServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'VisualSimulation'
    imageName: '${serviceAccountNameSpace}/visualsimulation'
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
    namespace: serviceAccountNameSpace
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
          annotations: {
            'dapr.io/enabled': 'false'
            'dapr.io/app-id': visualsimulationServiceName
            'dapr.io/app-port': '${visualsimulationPortNumber}'
            'dapr.io/app-protocol': 'http'
            'dapr.io/enableApiLogging': 'true'
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
                containerPort: visualsimulationPortNumber
              }
            ]
            volumeMounts: [
              {
              name: 'secrets-store01-inline'
              mountPath: 'mnt/secrets-store'
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
              secretProviderClass: 'azure-sync'
            }
          }
        } 
      ]        
      }
    }
  }
}

resource coreService_uisim 'core/Service@v1' = {
  metadata: {
    labels: {
      app: visualsimulationServiceName
    }
    name: visualsimulationServiceName
    namespace: serviceAccountNameSpace
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        name: 'web'
        port: visualsimulationPortNumber
        targetPort: visualsimulationPortNumber
      }
    ]
    selector: {
      app: visualsimulationServiceName
    }
  }
}
