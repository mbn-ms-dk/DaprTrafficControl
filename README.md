# DaprTrafficControl

This project is based on [https://github.com/EdwinVW/dapr-traffic-control]

and

[https://learn.microsoft.com/en-us/dotnet/architecture/dapr-for-net-developers/]

# Overall architecture

```mermaid
graph LR
    subgraph subTcs[Traffic Control Service]
       ds1[Dapr Sidecar] -. input binding /entrycam .-> tcs[TrafficControlService]
       ds1 -. input binding /exitcam .-> tcs
       tcs -. pub/sub,state management .-> ds1
    end
     subgraph subFcs[Fine Collection Service]
       ds2[Dapr Sidecar] -. input binding /entrycam .-> fcs[FineCollectionService]
       ds2 -. pub/sub /collectfine .-> fcs
       fcs -. service invokation,output binding,secrets management .-> ds2
    end
    subgraph subVhs[Vehicle Registration Service]
       ds3[Dapr Sidecar] -. input binding /entrycam .-> vhs[VehicleRegistrationService]
       ds3 -. service invokation /vehicleinfo/license-number .-> vhs
    end
    subgraph subHlp[Infrastrcture]
        MQTT[MQTT]
        REDIS[Redis]
        MQ[RAbbitMQ]
        SMTP[SMTP]
     end
    CS[CameraSimulation] -. input binding .-> MQTT
    MQTT -. input binding .-> ds1
    ds1 -. state management .-> REDIS
    ds1 -. pub/sub .-> MQ
    MQ -. pub/sub .-> ds2
    ds2 -. output binding .-> SMTP
    ds2 -. service invokation .-> ds3
    
   linkStyle default stroke-width:2px 
   style CS fill:blue,stroke:#333,stroke-width:2px;
   style tcs fill:blue,stroke:#333,stroke-width:2px;
   style fcs fill:blue,stroke:#333,stroke-width:2px;
   style vhs fill:blue,stroke:#333,stroke-width:2px;
   style ds1 fill:darkBlue,stroke:#333,stroke-width:2px;
   style ds2 fill:darkBlue,stroke:#333,stroke-width:2px;
   style ds3 fill:darkBlue,stroke:#333,stroke-width:2px;
   style subTcs fill:lightGrey,opacity:0.5;
   style subVhs fill:lightGrey,opacity:0.5;
   style MQTT fill:green,stroke:#333,stroke-width:2px;
   style REDIS fill:green,stroke:#333,stroke-width:2px;
   style SMTP fill:green,stroke:#333,stroke-width:2px;
   style MQ fill:green,stroke:#333,stroke-width:2px;
   style subFcs fill:lightGrey,opacity:0.5;
   style subHlp fill:lightGrey,opacity:0.5;
```
## Sequence

```mermaid
sequenceDiagram 
    autonumber
    participant CS as CameraSimulation
    participant tcsEntry as TrafficControlService (Entry camera)
    participant tcsExit as TrafficControlService (Exit camera)
    participant fcs as FineCollectionService
    participant vhs as VehicleRegistrationService
    participant smtp as SMTP
    CS->>tcsEntry: POST vehicleRegistered
    tcsEntry->>tcsEntry: Store VehicleState
    CS->>tcsExit: POST vehicleRegistered
    tcsExit->>tcsExit: GET VehicleState
    tcsExit->>tcsExit: Calculate average speed
    tcsExit->>fcs: POST speedingViolation (avg speed over limit)
    fcs->>fcs: Calculate fine
    fcs->>vhs: GET vehicleInfo/licenseNumber
    vhs-->>fcs: 
    fcs->>smtp: Send fine
```

This project is using [tye](https://github.com/dotnet/tye) to run locally and deploy to Azure.

## Prerequisites
To run locally [dapr](https://docs.dapr.io/getting-started) is required.

### install dapr locally
1. Install [dapr CLI](https://docs.dapr.io/getting-started/install-dapr-cli/) (both for running locally and on Azure Kubernetes)
2. [Initialize](https://docs.dapr.io/getting-started/install-dapr-selfhost/)

### Run locally
From the root folder run
```shell
tye run --dashboard
```
Last argument will open the tye dashboard.

If there are errors in regards to https when running locally, run the following command:
```shell
dotnet dev-certs https --trust
```

## Install AKS and dapr and deploy to AKS using bicep
note: setx BICEP_CLI_EXPERIMENTAL_FEATURES Extensibility to enable bicep deploy
1. login
```powershell 
az login
```

2. Set environment variables
```powershell 
$rg="rg-dtc"
$loc="northeurope"
```

3. Create resource group
```powershell 
az group create --name $rg --location $loc
```

4. Deploy 
```powershell
az deployment group create --resource-group $rg --template-file "./bicep/aks/main.bicep" --parameters "./bicep/aks/main.parameters.json"
```

5. Cleanup
```powershell
az group delete -g $rg --yes --no-wait
```
kubectl apply -f .\Projects\DaprTrafficControl\bicep\aks\modules\kvsync.yaml  

### Deploy to AKS using github actions
This project is using Github Actions to deploy
[https://learn.microsoft.com/en-us/azure/aks/kubernetes-action]

1. Create connection between Github and Azure
```shell
az ad sp create-for-rbac \
    --name "ghActiondtc" \
    --scope /subscriptions/edccd614-120e-4738-9be5-e63d2c6b7b10/resourceGroups/$rg \
    --role Contributor \
    --sdk-auth
```
Save the output as follows:

| Secret name | Secret value |
| :---------- | :----------- |
| AZURE_CREDENTIALS | The entire JSON output from the az ad sp create-for-rbac command |
| service_principal | The value of *clientId* |
| service_principal_password | The value of *clientSecret* |
| subscription | The value of *<*subscriptionId* |
| tenant | The value of *tenantId* |
| registry | The name of your registry |
| repository | Name of your repository |
| resource_group | The name of your resource group |
| cluster_name | The name of your cluster |


### Install grafana optional 
Navigate to K8s/observability/grafana folder. (TODO: Use managed grafana)

```shell
kubectl apply -f grafana_namespace.yaml

# install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install dapr-prom prometheus-community/prometheus -n dapr-monitoring --set alertmanager.persistentVolume.enable=false --set pushgateway.persistentVolume.enabled=false --set server.persistentVolume.enabled=false

# install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana -n dapr-monitoring --set persistence.enabled=true

# display Grafana admin password
& ./get-grafana-password.ps1
```
#### AKS helpers
### aks get oidc issuer url 
```powershell
az aks show -n $aks -g $rg --query "oidcIssuerProfile.issuerUrl" -otsv
```

### aks get kubeconfig
```powershell
az aks get-credentials -n $aks -g $rg --admin
```
### aks set default namespace for kubectl
```powershell
kubectl config set-context --current --namespace=<your-namespace>
```

###You can see that now a new Dapr configuration which enables tracing has been added. Run the command:
```powershell	
dapr configurations --kubernetes
```

### after deploying, update kvsync.yaml with workload identity id, keyvault name and tenant id and apply using kubectl
```shell
kubectl apply -f .\bicep\aks\modules\kvsync.yaml  
```

## Use Azure Container apps
[https://docs.microsoft.com/en-us/azure/container-apps/quickstart-dotnet-azure-container-apps]
### The bicep strucure
```mermaid
graph LR
    A[main.bicep] 
    X[main.parameters.json] --> A
    A --> B[modules]
    B --> C[container-apps-environment.bicep]
    B --> D[service-bus.bicep]
    B --> E[cosmos-db.bicep]
    B --> F[dapr-components.bicep]
    B --> G[container-registry.bicep]
    B --> H[key-vault.bicep]
    B --> I[container-apps.bicep]
    I --> J[container-apps]
    I --> K[secrets]
    K --> L[app-insights-secrets.bicep]
    J --> M[mail.bicep]
    J --> N[mosquitto.bicep]
    J --> O[trafficsimulation-service.bicep]
    J --> P[visualsim-service.bicep]
    J --> Q[trafficcontrol-service.bicep]
    J --> R[finecollection-service.bicep]
    J --> S[vehicleregistration-service.bicep]
    F --> K
    K --> T[mail-server-secrets.bicep]
```

1. login
```powershell 
az login
```

2. Add containerapp extension
```powershell
az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
```

3. Set environment variables
```powershell 
$rg="rg-dtc"
$loc="northeurope"
```

4. Create resource group
```powershell 
az group create --name $rg --location $loc
```

5. Deploy 
```powershell
az deployment group create --resource-group $rg --template-file "./bicep/aca/main.bicep" --parameters "./bicep/aca/main.parameters.json"
```

6. Cleanup
```powershell
az group delete -g $rg --yes --no-wait
```

