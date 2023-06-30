targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The name of the Key Vault.')
param keyVaultName string

@description('The name of the application insights.')
param applicationInsightsName string

@description('Application insights secret name.')
param applicationInsightsSecretName string

// ------------------
// RESOURCES
// ------------------

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

//Reference to AppInsights resource
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

// External Azure storage key secret used by mailserver Service.
resource appInsightsSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: applicationInsightsSecretName
  properties: {
    value: applicationInsights.properties.ConnectionString
  }
}
