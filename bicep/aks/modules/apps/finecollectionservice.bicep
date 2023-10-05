@secure()
param kubeConfig string

@description('The name of the service for the fineCollection service. The name is use as Dapr App ID.')
param fineCollectionServiceName string

@description('The target and dapr port for the fineCollection service.')
param fineCollectionPortNumber int

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

// // Service Bus
// @description('The name of the service bus namespace.')
// param serviceBusName string

// @description('The name of the service bus topic.')
// param serviceBusTopicName string

// @description('The AKS service principal id.')
// param aksPrincipalId string

@description('Secret Provider Class Name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param secretProviderClassName string

// ------------------
// RESOURCES
// ------------------
// resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
//   name: serviceBusName
// }

// resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
//   name: serviceBusTopicName
//   parent: serviceBusNamespace
// }

module buildfineCollection 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: fineCollectionServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'FineCollectionService'
    imageName: '${aksNameSpace}/finecollectionservice' 
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
}

resource appsDeployment_finecollectionservice 'apps/Deployment@v1' = {
  metadata: {
    name: fineCollectionServiceName
    namespace: aksNameSpace
    labels: {
      app: fineCollectionServiceName
      'azure.workload.identity/use': 'true'
    }
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: fineCollectionServiceName
      }
    }
    strategy: {
      type: 'Recreate'
    }
    template: {
      metadata: {
        labels: {
          app: fineCollectionServiceName
        }
        annotations: {
          'dapr.io/enabled': 'true'
          'dapr.io/app-id': fineCollectionServiceName
          'dapr.io/app-port': '${fineCollectionPortNumber}'
          'dapr.io/app-protocol': 'http'
          'dapr.io/enableApiLogging': 'true'
          'dapr.io/config': 'appconfig'
        }
      }
      spec: {
        serviceAccountName: serviceAccountName
        containers: [
          {
            name: fineCollectionServiceName
            image: buildfineCollection.outputs.acrImage
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
                containerPort: fineCollectionPortNumber
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

// resource fineCollectionService_sb_role_assignment_system 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(resourceGroup().id, fineCollectionServiceName, '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0')
//   properties: {
//     principalId: aksPrincipalId
//     roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0') // Azure Service Bus Data Receiver.
//     principalType: 'ServicePrincipal'
//   }
//   scope: serviceBusTopic
// }
