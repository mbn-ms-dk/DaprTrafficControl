targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------
@description('Creates a KeyVault')
param keyVaultCreate bool = false

@description('If soft delete protection is enabled')
param keyVaultSoftDelete bool = true

@description('If purge protection is enabled')
param keyVaultPurgeProtection bool = true

@description('Installs the AKS KV CSI provider')
param keyVaultAksCSI bool = false

@description('The tags to be assigned to the created resources.')
param tags object = {}

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The name of the exissting AKS cluster to integrate with the KeyVault')
param aksClusterName string = ''

resource aks 'Microsoft.ContainerService/managedClusters@2023-05-02-preview' existing = {
  name: aksClusterName
}

@description('Creates a KeyVault for application secrets (eg. CSI)')
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'kv-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: keyVaultSoftDelete
    enablePurgeProtection: keyVaultPurgeProtection ? true : null
  }
}

@description('The principal ID of the user or service principal that requires access to the Key Vault.')
param keyVaultOfficerRolePrincipalId string = ''
var keyVaultOfficerRolePrincipalIds = [
  keyVaultOfficerRolePrincipalId
]

@description('Parsing an array with union ensures that duplicates are removed, which is great when dealing with highly conditional elements')
var rbacSecretUserSps = [
  keyVaultAksCSI ? aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId : ''
]

var rbacadminUserSps = [
  '2f6b4e5f-aa31-4446-b0d4-045883ff2ce9'
]

@description('A seperate module is used for RBAC to avoid delaying the KeyVault creation and causing a circular reference.')
module kvRbac 'keyvaultrbac.bicep' = if (keyVaultCreate) {
  name: take('${deployment().name}-KeyVaultAppsRbac',64)
  params: {
    keyVaultName: keyVaultCreate ? kv.name : ''

    //service principals
    rbacSecretUserSps: rbacSecretUserSps
    rbacSecretOfficerSps: !empty(keyVaultOfficerRolePrincipalId) ? keyVaultOfficerRolePrincipalIds : []
    rbacCertOfficerSps: !empty(keyVaultOfficerRolePrincipalId) ? keyVaultOfficerRolePrincipalIds : []

    //users
    rbacSecretOfficerUsers: !empty(keyVaultOfficerRolePrincipalId) ? keyVaultOfficerRolePrincipalIds : []
    rbacCertOfficerUsers: !empty(keyVaultOfficerRolePrincipalId) && false ? keyVaultOfficerRolePrincipalIds : []
    rbacAdminUsers: rbacadminUserSps
  }
}

output keyVaultName string = keyVaultCreate ? kv.name : ''
output keyVaultId string = keyVaultCreate ? kv.id : ''

