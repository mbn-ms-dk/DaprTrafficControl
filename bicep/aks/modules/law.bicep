targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The tags to be assigned to the created resources.')
param tags object = {}

@description('The Log Analytics retention period')
param retentionInDays int = 30

@description('The Log Analytics daily data cap (GB) (0=no limit)')
param logDataCap int = 0

resource aks_law 'Microsoft.OperationalInsights/workspaces@2022-10-01' =  {
  name: 'log-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties : union({
      retentionInDays: retentionInDays
      sku: {
        name: 'PerGB2018'
      }
    },
    logDataCap>0 ? { workspaceCapping: {
      dailyQuotaGb: logDataCap
    }} : {}
  )
}

output LogAnalyticsName string = aks_law.name
output LogAnalyticsGuid string = aks_law.properties.customerId
output LogAnalyticsId string = aks_law.id
