@secure()
param kubeConfig string

@description('The location where the resources will be created.')
param location string = resourceGroup().location

// Container Registry & Image
@description('The name of the container registry.')
param containerRegistryName string

@description('The AKS service principal id.')
param aksPrincipalId string

@description('Application Insights secret name')
param applicationInsightsSecretName string

// Service Bus
@description('The name of the service bus namespace.')
param serviceBusName string

@description('The name of the service bus topic.')
param serviceBusTopicName string

// Cosmos DB
@description('The name of the provisioned Cosmos DB resource.')
param cosmosDbName string 

@description('The name of the provisioned Cosmos DB\'s database.')
param cosmosDbDatabaseName string

@description('The name of Cosmos DB\'s collection.')
param cosmosDbCollectionName string

@description('The name of the service for the trafficcontrol service. The name is use as Dapr App ID.')
param trafficcontrolServiceName string = 'dtc-trafficcontrol'

@description('The dapr port for the trafficcontrol service.')
param trafficcontrolPortNumber int = 5047

@description('Use actors in traffic control service')
param useActors bool

@description('Aks workload identity service account name')
param serviceAccountName string


@description('Aks namespace')
param aksNameSpace string

@description('Data actions permitted by the Role Definition')
param dataActions array = [
  'Microsoft.DocumentDB/databaseAccounts/readMetadata'
  'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
]

var roleDefinitionId = guid('sql-role-definition-', trafficcontrolServiceName)
var roleDefinitionName = 'My Read Write Role ${uniqueString(resourceGroup().id)}'
var roleAssignmentId = guid(roleDefinitionId, trafficcontrolServiceName)

import 'kubernetes@1.0.0' with {
  namespace: aksNameSpace
  kubeConfig: kubeConfig
}

// ------------------
// RESOURCES
// ------------------
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
  name: serviceBusTopicName
  parent: serviceBusNamespace
}

resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmosDbName
}

resource cosmosDbDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' existing = {
  name: cosmosDbDatabaseName
  parent: cosmosDbAccount
}

resource cosmosDbDatabaseCollection 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' existing = {
  name: cosmosDbCollectionName
  parent: cosmosDbDatabase
}

module buildtrafficcontrol 'br/public:deployment-scripts/build-acr:2.0.1' = {
  name: trafficcontrolServiceName
  params: {
    AcrName: containerRegistryName
    location: location
    gitRepositoryUrl:  'https://github.com/mbn-ms-dk/DaprTrafficControl.git'
    dockerfileDirectory: 'TrafficControlService'
    imageName: 'dtc/trafficcontrol'
    imageTag: 'latest'
    cleanupPreference: 'Always'
  }
}

resource appsDeployment_trafficcontrolservice 'apps/Deployment@v1' = {
  metadata: {
    name: trafficcontrolServiceName
    namespace: aksNameSpace
    labels: {
      app: trafficcontrolServiceName
    }
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: trafficcontrolServiceName
      }
    }
    strategy: {
      type: 'Recreate'
    }
    template: {
      metadata: {
        labels: {
          app: trafficcontrolServiceName
          'azure.workload.identity/use': 'true'
        }
        annotations: {
          'dapr.io/enabled': 'true'
          'dapr.io/app-id': trafficcontrolServiceName
          'dapr.io/app-port': '${trafficcontrolPortNumber}'
          'dapr.io/protocol': 'http'
          'dapr.io/enableApiLogging': 'true'
        }
      }
      spec: {
        serviceAccountName: serviceAccountName
        containers: [
          {
            name: trafficcontrolServiceName
            image: buildtrafficcontrol.outputs.acrImage
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
              {
                name: 'USE_ACTORS'
                value: '${useActors}'
              }
            ]
            ports: [
              {
                containerPort: trafficcontrolPortNumber
              }
            ]
          }
        ]
        restartPolicy: 'Always'
      }
    }
  }
}

// Assign cosmosdb account read/write access to aca system assigned identity
resource trafficcontrolService_cosmosdb_role_assignment_system 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-08-15' = {
  name: guid(subscription().id, trafficcontrolServiceName, '00000000-0000-0000-0000-000000000002')
  parent: cosmosDbAccount
  properties: {
    principalId: aksPrincipalId
    roleDefinitionId:  resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosDbAccount.name, '00000000-0000-0000-0000-000000000002')//DocumentDB Data Contributor
    scope: '${cosmosDbAccount.id}/dbs/${cosmosDbDatabase.name}/colls/${cosmosDbDatabaseCollection.name}'
  }
}

resource sqlRoleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2023-04-15' = {
  parent: cosmosDbAccount
  name: roleDefinitionId
  properties: {
    roleName: roleDefinitionName
    type: 'CustomRole'
    assignableScopes: [
      cosmosDbAccount.id
    ]
    permissions: [
      {
        dataActions: dataActions
      }
    ]
  }
}

resource sqlRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  parent: cosmosDbAccount
  name: roleAssignmentId
  properties: {
    roleDefinitionId: sqlRoleDefinition.id
    principalId: aksPrincipalId
    scope: cosmosDbAccount.id
  }
}

resource trafficcontrolService_sb_role_assignment_system 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, trafficcontrolServiceName, '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')
  properties: {
    principalId: aksPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')//Azure Service Bus Data Sender
    principalType: 'ServicePrincipal'
  }
  scope: serviceBusTopic
}
