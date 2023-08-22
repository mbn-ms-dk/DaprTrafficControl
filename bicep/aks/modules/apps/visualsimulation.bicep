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

@description('Aks namespace')
param aksNameSpace string

@description('Aks workload identity service account name')
param serviceAccountName string

@description('Secret Provider Class Name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param secretProviderClassName string

module buildvisualsimulation 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: visualsimulationServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'VisualSimulation'
    imageName: '${aksNameSpace}/visualsimulation'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
} 

resource appsDeployment_uisim 'apps/Deployment@v1' = {
  metadata: {
    name: visualsimulationServiceName
    namespace: aksNameSpace
    labels: {
      app: visualsimulationServiceName
      'azure.workload.identity/use': 'true'
    }
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
            'dapr.io/enabled': 'true'
            'dapr.io/app-id': visualsimulationServiceName
            'dapr.io/app-port': '${visualsimulationPortNumber}'
            'dapr.io/app-protocol': 'http'
            'dapr.io/enableApiLogging': 'true'
            'dapr.io/config': 'appconfig'
          }
      }
      spec: {
        serviceAccountName: serviceAccountName
        containers: [
          {
            name: visualsimulationServiceName
            image: buildvisualsimulation.outputs.acrImage
            imagePullPolicy: 'Always'
            env: [
              {
                name: 'ApplicationInsights__InstrumentationKey'
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
              secretProviderClass: secretProviderClassName
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
    namespace: aksNameSpace
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        name: 'web'
        port: visualsimulationPortNumber
        #disable-next-line BCP036
        targetPort: visualsimulationPortNumber
      }
    ]
    selector: {
      app: visualsimulationServiceName
    }
  }
}
