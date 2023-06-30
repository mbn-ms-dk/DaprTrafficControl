targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The name of the Key Vault.')
param keyVaultName string

@description('Mail server secret username')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerUserSecretsName string


@description('Mail server secret password name')
#disable-next-line secure-secrets-in-params //Disabling validation of this linter rule as param does not contain a secret.
param mailServerPasswordSecretsName string


// ------------------
// RESOURCES
// ------------------

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

// External Azure storage key secret used by mailserver Service.
resource mailUserSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: mailServerUserSecretsName
  properties: {
    value: 'bob'
  }
}

@secure()
param psSecret string = '${newGuid()}${uniqueString(resourceGroup().id)}'

resource mailPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: mailServerPasswordSecretsName
  properties: {
    value: psSecret
  }
}
