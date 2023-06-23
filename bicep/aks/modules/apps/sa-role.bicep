@secure()
param kubeConfig string

@description('Aks workload identity service account name')
param serviceAccountNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource rbacAuthorizationK8sIoClusterRole_appinsightsK8sPropertyReader 'rbac.authorization.k8s.io/ClusterRole@v1' = {
  metadata: {
    name: 'appinsights-k8s-property-reader'
  }
  rules: [
    {
      apiGroups: [
        ''
        'apps'
      ]
      resources: [
        'pods'
        'nodes'
        'replicasets'
        'deployments'
      ]
      verbs: [
        'get'
        'list'
      ]
    }
  ]
}

resource rbacAuthorizationK8sIoClusterRoleBinding_appinsightsK8sPropertyReaderBinding 'rbac.authorization.k8s.io/ClusterRoleBinding@v1' = {
  metadata: {
    name: 'appinsights-k8s-property-reader-binding'
  }
  subjects: [
    {
      kind: 'ServiceAccount'
      name: 'default'
      namespace: serviceAccountNameSpace
    }
  ]
  roleRef: {
    kind: 'ClusterRole'
    name: 'appinsights-k8s-property-reader'
    apiGroup: 'rbac.authorization.k8s.io'
  }
}
