@secure()
param kubeConfig string

@description('The name of the service for the mosquitto service. The name is use as Dapr App ID.')
param mosquittoServiceName string

@description('The location where the resources will be created.')
param location string = resourceGroup().location

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('Aks namespace')
param aksNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

module buildMosquitto 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: mosquittoServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    buildWorkingDirectory: 'mosquitto'
    imageName: 'dtc/mosquitto'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

resource appsDeployment_mosquitto 'apps/Deployment@v1' = {
  metadata: {
    labels: {
      app: mosquittoServiceName
      version: 'v1'
    }
    name: mosquittoServiceName
    namespace: aksNameSpace
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: mosquittoServiceName
      }
    }
    strategy: {
      type: 'Recreate'
    }
    template: {
      metadata: {
        labels: {
          app: mosquittoServiceName
        }
      }
      spec: {
        containers: [
          {
            name: mosquittoServiceName
            image: buildMosquitto.outputs.acrImage
            imagePullPolicy: 'IfNotPresent'
            ports: [
              {
                name: 'mqtt'
                containerPort: 1883
                protocol: 'TCP'
              }
              {
                name: 'ws'
                containerPort: 9001
              }
            ]
          }
        ]
        restartPolicy: 'Always'
      }
    }
  }
}

resource coreService_mosquitto 'core/Service@v1' = {
  metadata: {
    labels: {
      app: mosquittoServiceName
    }
    name: mosquittoServiceName
    namespace:aksNameSpace
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        name: 'mqtt'
        port: 1883
        targetPort: 1883
      }
      {
        name: 'ws'
        port: 9001
        targetPort: 9001
      }
    ]
    selector: {
      app: mosquittoServiceName
    }
  }
}
