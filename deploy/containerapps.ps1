$RESOURCE_GROUP="containerapps-sample"
$LOCATION="westeurope"
$CONTAINERAPPS_ENVIRONMENT="development"
$LOG_ANALYTICS_WORKSPACE="workspace-logs"
$ACR="containerappsample.azurecr.io"
$ACR_Login="containerappsample"
$ACR_Password="$(az acr credential show -n $ACR --query "passwords[0].value" -o tsv)"


az login
az account set -s "MVP Subscription"
az upgrade
# az extension add --source https://workerappscliextension.blob.core.windows.net/azure-cli-extension/containerapp-0.2.0-py2.py3-none-any.whl
# az provider register --namespace Microsoft.Web

# # az group create --name $RESOURCE_GROUP --location "$LOCATION"

# Creo workspace
az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP --workspace-name $LOG_ANALYTICS_WORKSPACE
$LOG_ANALYTICS_WORKSPACE_CLIENT_ID=(az monitor log-analytics workspace show --query customerId -g $RESOURCE_GROUP -n $LOG_ANALYTICS_WORKSPACE --out tsv)
$LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET=(az monitor log-analytics workspace get-shared-keys --query primarySharedKey -g $RESOURCE_GROUP -n $LOG_ANALYTICS_WORKSPACE --out tsv)

# Creo Environment
az containerapp env create `
  --name $CONTAINERAPPS_ENVIRONMENT `
  --resource-group $RESOURCE_GROUP `
  --logs-workspace-id $LOG_ANALYTICS_WORKSPACE_CLIENT_ID `
  --logs-workspace-key $LOG_ANALYTICS_WORKSPACE_CLIENT_SECRET `
  --location "$LOCATION"

# Deploy app: gateway-app
az containerapp create `
  --name gateway-app `
  --resource-group $RESOURCE_GROUP `
  --environment $CONTAINERAPPS_ENVIRONMENT `
  --registry-login-server $ACR `
  --registry-username $ACR_Login `
  --registry-password $ACR_Password `
  --image $ACR/gateway-app:1.0.0 `
  --target-port 80 `
  --ingress 'external' `
  --min-replicas 1 `
  --max-replicas 1 `
  --verbose

az containerapp update -v 'ASPNETCORE_ENVIRONMENT=Development' --resource-group=$RESOURCE_GROUP --name gateway-app
az containerapp update -v 'ASPNETCORE_URLS=http://+:80' --resource-group=$RESOURCE_GROUP --name gateway-app
az containerapp update -v 'Logging__LogLevel__Default=Trace' --resource-group=$RESOURCE_GROUP --name gateway-app
az containerapp update -v 'Logging__LogLevel__Microsoft.AspNetCore=Trace' --resource-group=$RESOURCE_GROUP --name gateway-app


az containerapp create `
--name aggregator-app `
--resource-group $RESOURCE_GROUP `
--environment $CONTAINERAPPS_ENVIRONMENT `
--registry-login-server $ACR `
--registry-username $ACR_Login `
--registry-password $ACR_Password `
--image $ACR/aggregator-app:1.0.0 `
--min-replicas 1 `
--max-replicas 1 `
--target-port 80 `
--ingress 'internal' `
--verbose

az containerapp update -v 'ASPNETCORE_ENVIRONMENT=Development' --resource-group=$RESOURCE_GROUP --name aggregator-app
az containerapp update -v 'ASPNETCORE_URLS=http://+:80' --resource-group=$RESOURCE_GROUP --name aggregator-app
az containerapp update -v 'HttpConfigurations__ServiceOneUrl=https://serviceone-app.development.westeurope.azurecontainerapps.io' --resource-group=$RESOURCE_GROUP --name aggregator-app
az containerapp update -v 'HttpConfigurations__ServiceTwoUrl=https://servicetwo-app.development.westeurope.azurecontainerapps.io' --resource-group=$RESOURCE_GROUP --name aggregator-app

# az containerapp update `
# --name aggregator-app `
# --resource-group $RESOURCE_GROUP `
# --registry-login-server $ACR `
# --registry-username $ACR_Login `
# --registry-password $ACR_Password `
# --image $ACR/aggregator-app:1.0.1 `

az containerapp create `
--name serviceone-app `
--resource-group $RESOURCE_GROUP `
--environment $CONTAINERAPPS_ENVIRONMENT `
--registry-login-server $ACR `
--registry-username $ACR_Login `
--registry-password $ACR_Password `
--image $ACR/serviceone-app:1.0.0 `
--min-replicas 1 `
--max-replicas 1 `
--target-port 80 `
--ingress 'internal' `
--verbose

az containerapp update -v 'ASPNETCORE_ENVIRONMENT=Development' --resource-group=$RESOURCE_GROUP --name serviceone-app
az containerapp update -v 'ASPNETCORE_URLS=http://+:80' --resource-group=$RESOURCE_GROUP --name serviceone-app

az containerapp create `
--name servicetwo-app `
--resource-group $RESOURCE_GROUP `
--environment $CONTAINERAPPS_ENVIRONMENT `
--registry-login-server $ACR `
--registry-username $ACR_Login `
--registry-password $ACR_Password `
--image $ACR/servicetwo-app:1.0.0 `
--min-replicas 1 `
--max-replicas 1 `
--target-port 80 `
--ingress 'internal' `
--verbose

az containerapp update -v 'ASPNETCORE_ENVIRONMENT=Development' --resource-group=$RESOURCE_GROUP --name servicetwo-app
az containerapp update -v 'ASPNETCORE_URLS=http://+:80' --resource-group=$RESOURCE_GROUP --name servicetwo-app


$AGGREGATORURL = $(az containerapp show --resource-group $RESOURCE_GROUP --name aggregator-app --query configuration.ingress.fqdn)
$SERVICEONEURL = $(az containerapp show --resource-group $RESOURCE_GROUP --name serviceone-app --query configuration.ingress.fqdn)
$SERVICETWOURL = $(az containerapp show --resource-group $RESOURCE_GROUP --name servicetwo-app --query configuration.ingress.fqdn)

$AGGREGATORURL
$SERVICEONEURL
$SERVICETWOURL

#GATEWAYAPP
az containerapp update -v 'ReverseProxy__Clusters__aggregator__Destinations__default__Address=https://aggregator-app.internal.nicegrass-e324e6fd.westeurope.azurecontainerapps.io' --resource-group=$RESOURCE_GROUP --name gateway-app
az containerapp update -v 'ReverseProxy__Clusters__serviceone__Destinations__default__Address=https://serviceone-app.internal.nicegrass-e324e6fd.westeurope.azurecontainerapps.io' --resource-group=$RESOURCE_GROUP --name gateway-app
az containerapp update -v 'ReverseProxy__Clusters__servicetwo__Destinations__default__Address=https://servicetwo-app.internal.nicegrass-e324e6fd.westeurope.azurecontainerapps.io' --resource-group=$RESOURCE_GROUP --name gateway-app

#AGGREGATOR
az containerapp update -v 'HttpConfigurations__ServiceOneUrl=https://serviceone-app.internal.nicegrass-e324e6fd.westeurope.azurecontainerapps.io' --resource-group=$RESOURCE_GROUP --name aggregator-app
az containerapp update -v 'HttpConfigurations__ServiceTwoUrl=https://servicetwo-app.internal.nicegrass-e324e6fd.westeurope.azurecontainerapps.io' --resource-group=$RESOURCE_GROUP --name aggregator-app