@description('Provide a name for the Container Apps Environment')
param environmentName string

@description('Provide a location for the Container Apps resources')
param location string = resourceGroup().location

// unique suffix
var suffix = take(uniqueString(resourceGroup().id, environmentName), 5)
var logAnalyticsWorkspaceName = 'logs-${environmentName}'
var appInsightsName = 'appins-${environmentName}'
var acrName = 'acr${suffix}'
var storageAccountName = 'stg${suffix}'
var storageContainerName = 'orders'
var keyvaultName = 'kv${suffix}${take(uniqueString(resourceGroup().id,suffix), 3)}'
var tenantId = subscription().tenantId

//Create ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

@description('ACR Name')
output acrname string = acr.name

//create blob storage
resource blobstore 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

//create log analytics 
resource logAnalyticsWorkspace'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

//create app insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}


//create env
resource environment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: environmentName
  location: location
  properties: {
    daprAIInstrumentationKey: appInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspace.id, '2020-03-01-preview').customerId
        sharedKey: listKeys(logAnalyticsWorkspace.id, '2020-03-01-preview').primarySharedKey
      }
    }
  }
  
  //attach dapr component
  resource daprComponent 'daprComponents@2022-01-01-preview' = {
    name: 'statestore'
    properties: {
      componentType: 'state.azure.blobstorage'
      version: 'v1'
      ignoreErrors: false
      initTimeout: '5s'
      secrets: [
        {
          name: 'storageaccountkey'
          value: listKeys(resourceId('Microsoft.Storage/storageAccounts/', storageAccountName), '2021-09-01').keys[0].value
        }
      ]
      metadata: [
        {
          name: 'accountName'
          value: storageAccountName
        }
        {
          name: 'containerName'
          value: storageContainerName
        }
        {
          name: 'accountKey'
          secretRef: 'storageaccountkey'
        }
      ]
      scopes: [
        'nodeapp'
      ]
    }
  }
}

//create keyvault
resource keyvault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyvaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
  tenantId: subscription().tenantId
  enableRbacAuthorization: true //Using Access Policies
  accessPolicies: [
    {
      objectId: 'd89101d9-cf97-4b6c-9656-c6da457d8add'
      tenantId: tenantId
      permissions: {
        secrets: [
          'all'
        ]
        certificates: [
          'all'
        ]
        keys: [
          'all'
        ]
      }
    }
  ]
  enabledForDeployment: false //No VM need to retieve certificates
  enabledForTemplateDeployment: true //ARM can retrieve values
  enablePurgeProtection: true
  enableSoftDelete: true
  softDeleteRetentionInDays: 7
  createMode: 'default' // Creating or updating the key vault (not recovering)
  }
}

// Container Apps Environment ID
resource kvEnvId 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kvEnvId'
  parent: keyvault
  properties: {
    value: environment.id
  }
}

resource kvEnvName 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kvEnvName'
  parent: keyvault
  properties: {
    value: environment.name
  }
}
// @description('Container Apps Environment ID')
output environmentId string = environment.id


// Log Analytics workspace ID
resource kvLaId 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kvLaId'
  parent: keyvault
  properties: {
    value: logAnalyticsWorkspace.properties.customerId
  }
}  

@description('Log Analytics workspace ID')
output workspaceId string = logAnalyticsWorkspace.properties.customerId

// Container Registry admin username
resource kvAcrUserName  'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kvAcrUserName'
  parent: keyvault
  properties: {
    value: acr.listCredentials().username
  }
}

// @description('Container Registry admin username')
output acrUserName string = acr.listCredentials().username

// Container Registry admin password
resource kvAcrPassword  'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kvAcrPassword'
  parent: keyvault
  properties: {
    value: acr.listCredentials().passwords[0].value
  }
}
@description('Container Registry admin password')
output acrPassword string = acr.listCredentials().passwords[0].value

resource kvAcrloginServer  'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'kvAcrloginServer'
  parent: keyvault
  properties: {
    value: acr.properties.loginServer
  }
}
@description('Container Registry login server')
output acrloginServer string = acr.properties.loginServer
output kvName string = keyvault.name
