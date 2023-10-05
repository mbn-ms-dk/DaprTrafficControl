targetScope = 'resourceGroup'

@description('The name of the service for the fineCollection service. The name is use as Dapr App ID.')
param fineCollectionServiceName string

// Service Bus
@description('The name of the service bus namespace.')
param serviceBusName string

@description('The name of the service bus topic.')
param serviceBusTopicName string

@description('The AKS service principal id.')
param aksPrincipalId string


resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: serviceBusName
}

resource serviceBusTopic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' existing = {
  name: serviceBusTopicName
  parent: serviceBusNamespace
}

resource fineCollectionService_sb_role_assignment_system 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, fineCollectionServiceName, '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0')
  properties: {
    principalId: aksPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0') // Azure Service Bus Data Receiver.
    principalType: 'ServicePrincipal'
  }
  scope: serviceBusTopic
}
