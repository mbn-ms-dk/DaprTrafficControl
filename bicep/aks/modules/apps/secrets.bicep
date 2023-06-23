@secure()
param kubeConfig string

@description('Aks workload identity service account name')
param serviceAccountNameSpace string

import 'kubernetes@1.0.0' with {
  namespace: 'default'
  kubeConfig: kubeConfig
}

resource coreSecret_trafficcontrolSecrets 'core/Secret@v1' = {
  metadata: {
    name: 'trafficcontrol-secrets'
    namespace: serviceAccountNameSpace
  }
  type: 'Opaque'
  data: {
    'smtp.user': 'X3VzZXJuYW1l'
    'smtp.password': 'X3Bhc3N3b3Jk'
  }
}

resource rbacAuthorizationK8sIoRole_secretReader 'rbac.authorization.k8s.io/Role@v1' = {
  metadata: {
    name: 'secret-reader'
    namespace: serviceAccountNameSpace
  }
  rules: [
    {
      apiGroups: [
        ''
      ]
      resources: [
        'secrets'
      ]
      verbs: [
        'get'
        'list'
      ]
    }
  ]
}

resource rbacAuthorizationK8sIoRoleBinding_daprSecretReader 'rbac.authorization.k8s.io/RoleBinding@v1' = {
  metadata: {
    name: 'dapr-secret-reader'
    namespace: serviceAccountNameSpace
  }
  subjects: [
    {
      kind: 'ServiceAccount'
      name: 'default'
    }
  ]
  roleRef: {
    kind: 'Role'
    name: 'secret-reader'
    apiGroup: 'rbac.authorization.k8s.io'
  }
}
