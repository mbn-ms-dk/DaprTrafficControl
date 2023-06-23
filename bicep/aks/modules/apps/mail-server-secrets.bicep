targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The name of the Key Vault.')
param keyVaultName string

// @description('The name of the email user')
// param emailUserSecretName string = '_username'

// @secure()
// @description('The password of the email user')
// param emailPasswordSecretName string 

// ------------------
// RESOURCES
// ------------------

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// External Azure storage key secret used by mailserver Service.
resource mailUserSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'smtp-user'
  properties: {
    value: '_username'
  }
}

@secure()
param psSecret string = '${newGuid()}${uniqueString(resourceGroup().id)}'

resource mailPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'smtp-password'
  properties: {
    value: psSecret
  }
}
