# DaprTrafficControl

This projrect is based on [https://github.com/EdwinVW/dapr-traffic-control]
This project is using [tye](https://github.com/dotnet/tye) to run locally and deploy to Azure.

## Prerequisites
To run locally [dapr](https://docs.dapr.io/getting-started) is required.

### install dapr locally
1. Install [dapr CLI](https://docs.dapr.io/getting-started/install-dapr-cli/) (both for running locally and on Azure Kubernetes)
2. [Initialize}(https://docs.dapr.io/getting-started/install-dapr-selfhost/)

### Install AKS and dapr
### [Aks installation](https://docs.dapr.io/operations/hosting/kubernetes/cluster/setup-aks/)

1. Login
```shell
az login
```
2. Set variables
```shell
rg="rg-dtc"
aks="dtcaks"
loc="northeurope"
acr="acrdtc1231"
```
3. Create resource group
```shell
az group create --name $rg --location $loc
```
4. Create ACR 
[https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli]
Create ACR
```shell
az acr create -n $acr -g $rg --sku basic
```
5. Create AKS cluster with ephemeral disk and mariner host and attach acr
[https://learn.microsoft.com/EN-us/azure/aks/cluster-configuration]
```shell
az aks create --name $aks --resource-group $rg -s Standard_DS3_v2 --node-osdisk-type Ephemeral --os-sku mariner --enable-addons http_application_routing --generate-ssh-keys --enable-managed-identity --attach-acr $acr
```
6. Get Aks credentials
```shell
az aks get-credentials -n $aks -g $rg
```s
### [Install dapr using AKS Extension](https://docs.dapr.io/developing-applications/integrations/azure/azure-kubernetes-service-extension/)
1. Install dapr extension
```shell
az feature register --namespace "Microsoft.ContainerService" --name "AKS-ExtensionManager"
az feature register --namespace "Microsoft.ContainerService" --name "AKS-Dapr"
```
2. Check status
```shell
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-ExtensionManager')].{Name:name,State:properties.state}"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-Dapr')].{Name:name,State:properties.state}"
```
3. Next, refresh the registration of the `Microsoft.KubernetesConfiguration` and `Microsoft.ContainerService` resource providers
```shell
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ContainerService
```
4. Enable the Azure CLI extension for cluster extensions
Install
```shell
az extension add --name k8s-extension
```
or update
```shell
az extension update --name k8s-extension
```
5. Create the extension and install Dapr on your AKS cluster
After your subscription is registered to use Kubernetes extensions, install dapr
```shell
az k8s-extension create --cluster-type managedClusters --cluster-name $aks --resource-group $rg --name myDaprExtension --extension-type Microsoft.Dapr --auto-upgrade-minor-version true
```
6. Verify installation
Confirm dapr control plane is installed
```shell
kubectl get pods -n dapr-system
```
## Run locally
From the root folder run
```shell
tye run --dashboard
```
Last argument will open the tye dashboard.

## Deploy to Azure
add text

### Deploy services needed
Build Mosquitto image and push to ACR
```shell
docker build -t dtc/mosquitto:1.0 ./mosquitto
```
Tag image
```shell
docker tag dtc/mosquitto:1.0 <acrname>.azurecr.io/mosquitto:v1
```

Login to ACR
```shell
az acr login --name <your-acr-name>
```
push image
```shell
docker push <acrname>.azurecr.io/mosquitto:v1
```

From the k8s folder run:
```shell
kubectl apply `
    -f namespace.yaml `
    -f secrets.yaml `
    -f zipkin.yaml `
    -f redis.yaml `
    -f rabbitmq.yaml `
    -f mosquitto.yaml `
    -f maildev.yaml 
```

Deploy using github actions
[https://learn.microsoft.com/en-us/azure/aks/kubernetes-action]
1. Create connection between Github and Azure
```shell
<<<<<<< HEAD
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


=======
tye deploy --interactive
```
>>>>>>> 7f9b5fc6f766ac73d2c0b963d36083cd1b3d2850
