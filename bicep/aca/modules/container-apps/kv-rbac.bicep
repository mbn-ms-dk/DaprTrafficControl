targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@description('The name of the Key Vault.')
param keyVaultName string

@description('The principal ID of the Service.')
param servicePrincipalId string
// ------------------
// VARIABLES
// ------------------

var keyVaultSecretUserRoleGuid = '4633458b-17de-408a-b874-0445c86b69e6'

// ------------------
// RESOURCES
// ------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource keyVaultSecretUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
    name: guid(subscription().id, keyVault.id, servicePrincipalId, keyVaultSecretUserRoleGuid) 
    scope: keyVault
    properties: {
      principalId: servicePrincipalId
      roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretUserRoleGuid)
      principalType: 'ServicePrincipal'
    }
  }
