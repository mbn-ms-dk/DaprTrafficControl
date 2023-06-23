@secure()
param kubeConfig string

@description('Application Insights secret name')
param applicationInsightsSecretName string

@description('The name of the application insights.')
param applicationInsightsName string

@description('Aks workload identity service account name')
param serviceAccountNameSpace string

//Reference to AppInsights resource
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreSecret_appEnvSecret 'core/Secret@v1' = {
  metadata: {
    name: applicationInsightsSecretName
    namespace: serviceAccountNameSpace
  }
  type: 'Opaque'
  data: {
    'appinsights-connection-string':  base64(applicationInsights.properties.InstrumentationKey)
  }
}
