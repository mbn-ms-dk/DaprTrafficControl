targetScope = 'resourceGroup'

// ------------------
//    PARAMETERS
// ------------------

@description('The location where the resources will be created.')
param location string = resourceGroup().location

@description('The tags to be assigned to the created resources.')
param tags object = {}

@description('Kubernetes Version')
param kubernetesVersion string = '1.25.6'

@description('Enable Azure AD integration on AKS')
param enable_aad bool = false

@description('The ID of the Azure AD tenant')
param aad_tenant_id string = ''

@description('Enable RBAC using AAD')
param enableAzureRBAC bool = false

@description('Enables the Blob CSI driver')
param blobCSIDriver bool = false

@description('Enables the File CSI driver')
param fileCSIDriver bool = true

@description('Enables the Disk CSI driver')
param diskCSIDriver bool = true

@description('Installs the AKS KV CSI provider')
param keyVaultAksCSI bool = false

@description('Create, and use a new Log Analytics workspace for AKS logs')
param omsagent bool = false

@description('Rotation poll interval for the AKS KV CSI provider')
param keyVaultAksCSIPollInterval string = '2m'

@description('Add the Dapr extension')
param daprAddon bool = false
@description('Enable high availability (HA) mode for the Dapr control plane')
param daprAddonHA bool = false

@description('Then log analytics workspace ID')
param workspaceName string = ''

@allowed([
  'none'
  'patch'
  'stable'
  'rapid'
  'node-image'
])
@description('AKS upgrade channel')
param upgradeChannel string = 'stable'

@allowed([
  'Ephemeral'
  'Managed'
])
@description('OS disk type')
param osDiskType string = 'Managed'

@description('VM SKU')
param agentVMSize string = 'Standard_DS3_v2'

@description('Disk size in GB')
param osDiskSizeGB int = 0

@description('The number of agents for the user node pool')
param agentCount int = 3

@description('The maximum number of nodes for the user node pool')
param agentCountMax int = 0
var autoScale = agentCountMax > agentCount

@minLength(3)
@maxLength(12)
@description('Name for user node pool')
param nodePoolName string = 'npuser01'

@minValue(10)
@maxValue(250)
@description('The maximum number of pods per node.')
param maxPods int = 30

@allowed([
  'azure'
  'kubenet'
])
@description('The network plugin type')
param networkPlugin string = 'azure'

@allowed([
  ''
  'Overlay'
])
@description('The network plugin type')
param networkPluginMode string = 'Overlay'

@description('The zones to use for a node pool')
param availabilityZones array = []

@description('Disable local K8S accounts for AAD enabled clusters')
param AksDisableLocalAccounts bool = false

@allowed(['Linux','Windows'])
@description('The User Node pool OS')
param osType string = 'Linux'

@allowed(['Ubuntu','AzureLinux', 'Windows2019','Windows2022'])
@description('The User Node pool OS SKU')
param osSKU string = 'AzureLinux'

@minLength(9)
@maxLength(18)
@description('The address range to use for pods')
param podCidr string = '10.240.100.0/22'

@minLength(9)
@maxLength(18)
@description('The address range to use for services')
param serviceCidr string = '172.10.0.0/16'

@minLength(7)
@maxLength(15)
@description('The IP address to reserve for DNS')
param dnsServiceIP string = '172.10.0.10'

@minLength(9)
@maxLength(18)
@description('The address range to use for the docker bridge')
param dockerBridgeCidr string = '172.17.0.1/16'

@description('The principal ID to assign the AKS admin role.')
param adminPrincipalId string = '2f6b4e5f-aa31-4446-b0d4-045883ff2ce9'

@description('Enable Microsoft Defender for Containers (preview)')
param defenderForContainers bool = false

@description('Only use the system node pool')
param JustUseSystemPool bool = false

@description('Enables the ContainerLogsV2 table to be of type Basic')
param containerLogsV2BasicLogs bool = false

@description('Aks workload identity service account name')
param serviceAccountName string


@description('Aks workload identity service account name')
param serviceAccountNameSpace string


param AutoscaleProfile object = {
  'balance-similar-node-groups': 'true'
  expander: 'random'
  'max-empty-bulk-delete': '10'
  'max-graceful-termination-sec': '600'
  'max-node-provision-time': '15m'
  'max-total-unready-percentage': '45'
  'new-pod-scale-up-delay': '0s'
  'ok-total-unready-count': '3'
  'scale-down-delay-after-add': '10m'
  'scale-down-delay-after-delete': '20s'
  'scale-down-delay-after-failure': '3m'
  'scale-down-unneeded-time': '10m'
  'scale-down-unready-time': '20m'
  'scale-down-utilization-threshold': '0.5'
  'scan-interval': '10s'
  'skip-nodes-with-local-storage': 'true'
  'skip-nodes-with-system-pods': 'true'
}

@description('Outbound traffic type for the egress traffic of your cluster')
param aksOutboundTrafficType string = 'loadBalancer'

@description('Configures the cluster as an OIDC issuer for use with Workload Identity')
param oidcIssuer bool = false

@description('Installs Azure Workload Identity into the cluster')
param workloadIdentity bool = false

@description('The System Pool Preset sizing')
param SystemPoolType string = 'CostOptimised'

@description('A custom system pool spec')
param SystemPoolCustomPreset object = {}

@allowed(['Audit', 'Deny', 'Disabled'])
@description('Enable the Azure Policy addon')
param azurepolicy string = 'Audit'

resource aks_law 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing =  { 
  name: workspaceName
}

var systemPoolBase = {
  name:  JustUseSystemPool ? nodePoolName : 'npsystem'
  vmSize: agentVMSize
  count: agentCount
  mode: 'System'
  osType: 'Linux'
  osSKU: 'AzureLinux'
  maxPods: 30
  type: 'VirtualMachineScaleSets'
  upgradeSettings: {
    maxSurge: '33%'
  }
  nodeTaints: [
    JustUseSystemPool ? '' : 'CriticalAddonsOnly=true:NoSchedule'
  ]
}

@description('System Pool presets are derived from the recommended system pool specs')
var systemPoolPresets = {
  CostOptimised : {
    vmSize: 'Standard_B4ms'
    count: 1
    minCount: 1
    maxCount: 3
    enableAutoScaling: true
    availabilityZones: []
  }
  Standard : {
    vmSize: 'Standard_DS2_v2'
    count: 3
    minCount: 3
    maxCount: 5
    enableAutoScaling: true
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
  HighSpec : {
    vmSize: 'Standard_D4s_v3'
    count: 3
    minCount: 3
    maxCount: 5
    enableAutoScaling: true
    availabilityZones: [
      '1'
      '2'
      '3'
    ]
  }
}

var agentPoolProfiles = JustUseSystemPool ? array(systemPoolBase) : concat(array(union(systemPoolBase, SystemPoolType=='Custom' && SystemPoolCustomPreset != {} ? SystemPoolCustomPreset : systemPoolPresets[SystemPoolType])))

var aks_addons = union({
  azurepolicy: {
    config: {
      version: !empty(azurepolicy) ? 'v2' : json('null')
    }
    enabled: !empty(azurepolicy)
  }
  azureKeyvaultSecretsProvider: {
    config: {
      enableSecretRotation: 'true'
      rotationPollInterval: keyVaultAksCSIPollInterval
    }
    enabled: keyVaultAksCSI
  }
}, createLaw && omsagent ? {
  omsagent: {
    enabled: createLaw &&omsagent
    config: {
      logAnalyticsWorkspaceResourceID: createLaw && omsagent ?  aks_law.id : json('null')
    }
  }}:{})

  @description('Needing to seperately declare and union this because of https://github.com/Azure/AKS/issues/2774')
var azureDefenderSecurityProfile = {
  securityProfile : {
    defender: {
      logAnalyticsWorkspaceResourceId: createLaw ? aks_law.id : null
      securityMonitoring: {
        enabled: defenderForContainers
      }
    }
  }
}

var aksProperties = union({
  kubernetesVersion: kubernetesVersion
  dnsPrefix: dnsPrefix
  enableRBAC: true
  aadProfile: enable_aad ? {
    managed: true
    enableAzureRBAC: enableAzureRBAC
    tenantID: aad_tenant_id
  } : null
  agentPoolProfiles: agentPoolProfiles
  networkProfile: {
    loadBalancerSku: 'standard'
    networkPlugin: networkPlugin
    #disable-next-line BCP036 //Disabling validation of this parameter to cope with empty string to indicate no Network Policy required.
    networkPluginMode: networkPlugin=='azure' ? networkPluginMode : ''
    podCidr: networkPlugin=='kubenet' ? podCidr : json('null')
    serviceCidr: serviceCidr
    dnsServiceIP: dnsServiceIP
    dockerBridgeCidr: dockerBridgeCidr
    outboundType: aksOutboundTrafficType
  }
  disableLocalAccounts: AksDisableLocalAccounts && enable_aad
  autoUpgradeProfile: {upgradeChannel: upgradeChannel}
  addonProfiles: aks_addons
  autoScalerProfile: autoScale ? AutoscaleProfile : {}
  oidcIssuerProfile: {
    enabled: oidcIssuer
  }
  securityProfile: {
    workloadIdentity: {
      enabled: workloadIdentity
    }
  }
  storageProfile: {
    blobCSIDriver: {
      enabled: blobCSIDriver
    }
    diskCSIDriver: {
      enabled: diskCSIDriver
    }
    fileCSIDriver: {
      enabled: fileCSIDriver
    }
  }
  nodeResourceGroupProfile: {
    restrictionLevel: 'Unrestricted'
  }
},
defenderForContainers && createLaw  ? azureDefenderSecurityProfile : {}
)

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'aksWlIdentity-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags

  resource fedCreds 'federatedIdentityCredentials' = {
    name: 'fedCreds-${uniqueString(resourceGroup().id)}'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: oidcIssuer ? aks.properties.oidcIssuerProfile.issuerURL : ''
      subject: 'system:serviceaccount:${serviceAccountNameSpace}:${serviceAccountName}'
    }
  }
}

output appIdentityClientId string = appIdentity.properties.clientId
output appIdentityPrincipalId string = appIdentity.properties.principalId
output appIdentityId string = appIdentity.id

var dnsPrefix = '${serviceAccountNameSpace}-dns'
resource aks 'Microsoft.ContainerService/managedClusters@2023-04-02-preview' = {
  name: 'aks${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appIdentity.id}': {}
  }
  }
  properties: aksProperties
}

module userNodePool 'aksagentpool.bicep' = if (!JustUseSystemPool){
  name: 'userNodePool'
  params: {
    AksName: aks.name
    PoolName: nodePoolName
    agentCount: agentCount
    agentCountMax: agentCountMax
    agentVMSize: agentVMSize
    maxPods: maxPods
    osDiskType: osDiskType
    osType: osType
    osSKU: osSKU
    osDiskSizeGB: osDiskSizeGB
    availabilityZones: availabilityZones
  }
}

// for AAD Integrated Cluster using 'enableAzureRBAC', add Cluster admin to the current user!
var buildInAKSRBACClusterAdmin = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b')
resource aks_admin_role_assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAzureRBAC && !empty(adminPrincipalId)) {
  scope: aks // Use when specifying a scope that is different than the deployment scope
  name: guid(aks.id, 'aksadmin', buildInAKSRBACClusterAdmin)
  properties: {
    roleDefinitionId: buildInAKSRBACClusterAdmin
    principalType: !empty(adminPrincipalId) ? 'User' : 'ServicePrincipal'
    principalId: adminPrincipalId
  }
}

resource daprExtension 'Microsoft.KubernetesConfiguration/extensions@2022-11-01' = if(daprAddon) {
  name: 'dapr'
  scope: aks
  properties: {
      extensionType: 'Microsoft.Dapr'
      autoUpgradeMinorVersion: true
      releaseTrain: 'Stable'
      configurationSettings: {
          'global.ha.enabled': '${daprAddonHA}'
      }
      scope: {
        cluster: {
          releaseNamespace: 'dapr-system'
        }
      }
      configurationProtectedSettings: {}
  }
}

var createLaw = (omsagent || defenderForContainers)
resource containerLogsV2_Basiclogs 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = if(containerLogsV2BasicLogs){
  name: 'ContainerLogV2'
  parent: aks_law
  properties: {
    plan: 'Basic'
  }
  dependsOn: [
    aks
  ]
}

//--------------
//This role assignment enables AKS->LA Fast Alerting experience
var MonitoringMetricsPublisherRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '3913510d-42f4-4e42-8a64-420c390055eb')
resource FastAlertingRole_Aks_Law 'Microsoft.Authorization/roleAssignments@2022-04-01' =  {
  scope: aks
  name: guid(aks.id, 'omsagent', MonitoringMetricsPublisherRole)
  properties: {
    roleDefinitionId: MonitoringMetricsPublisherRole
    principalId: aks.properties.addonProfiles.omsagent.identity.objectId
    principalType: 'ServicePrincipal'
  }
}


var azurePolicyInitiative = 'Baseline'
var policySetBaseline = '/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d'
var policySetRestrictive = '/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00'

resource aks_policies 'Microsoft.Authorization/policyAssignments@2022-06-01' = if (!empty(azurepolicy)) {
  name: 'azpol-${azurePolicyInitiative}'
  location: location
  properties: {
    policyDefinitionId: azurePolicyInitiative == 'Baseline' ? policySetBaseline : policySetRestrictive
    parameters: {
      excludedNamespaces: {
        value: [
            'kube-system'
            'gatekeeper-system'
            'azure-arc'
            'cluster-baseline-setting'
        ]
      }
      effect: {
        value: azurepolicy
      }
    }
    metadata: {
      assignedBy: 'Dapr Traffic Control'
    }
    displayName: 'Kubernetes cluster pod security ${azurePolicyInitiative} standards for Linux-based workloads'
    description: 'As per: https://github.com/Azure/azure-policy/blob/master/built-in-policies/policySetDefinitions/Kubernetes/'
  }
}

// @description('Enable Metric Alerts')
// param createAksMetricAlerts bool = true

// @allowed([
//   'Short'
//   'Long'
// ])
// @description('Which Metric polling frequency model to use')
// param AksMetricAlertMetricFrequencyModel string = 'Long'

// var AlertFrequencyLookup = {
//   Short: {
//     evalFrequency: 'PT1M'
//     windowSize: 'PT5M'
//   }
//   Long: {
//     evalFrequency: 'PT15M'
//     windowSize: 'PT1H'
//   }
// }
// var AlertFrequency = AlertFrequencyLookup[AksMetricAlertMetricFrequencyModel]

// module aksmetricalerts 'aksmetricalerts.bicep' =  if(createLaw) {
//   name: take('${deployment().name}-aksmetricalerts',64)
//   scope: resourceGroup()
//   params: {
//     clusterName: aks.name
//     logAnalyticsWorkspaceName: aks_law.name
//     metricAlertsEnabled: createAksMetricAlerts
//     evalFrequency: AlertFrequency.evalFrequency
//     windowSize: AlertFrequency.windowSize
//     alertSeverity: 'Informational'
//     logAnalyticsWorkspaceLocation: location
//   }
// }




output daprReleaseNamespace string = daprAddon ? daprExtension.properties.scope.cluster.releaseNamespace : ''
output aksNodeResourceGroup string = aks.properties.nodeResourceGroup
output aksResourceId string = aks.id
output aksClusterName string = aks.name
output aksOidcIssuerUrl string = oidcIssuer ? aks.properties.oidcIssuerProfile.issuerURL : ''
output userNodePoolName string = nodePoolName
output systemNodePoolName string = JustUseSystemPool ? nodePoolName : 'npsystem'
output kvIdentityClientId string = aks.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.clientId
