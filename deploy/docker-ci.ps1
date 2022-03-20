$ACR_NAME="containerappsample.azurecr.io"
$ACR_USERNAME="containerappsample"
# $ACR_PASSWORD="spHsDiUcYH=aS99nCul1NAb5n8YhJnK5"
$ACR_PASSWORD="$(az acr credential show -n $ACR_NAME --query "passwords[0].value" -o tsv)"

cd ..\src

docker build --pull -f Sample.Gateway/Dockerfile .
docker build --pull -f Sample.Gateway\Dockerfile -t gateway-app:1.0.0 .
docker build --pull -f Sample.Aggregator\Dockerfile -t aggregator-app:1.0.1 .
docker build --pull -f Sample.ServiceOne\Dockerfile -t serviceone-app:1.0.0 .
docker build --pull -f Sample.ServiceTwo\Dockerfile -t servicetwo-app:1.0.0 .

docker login $ACR_NAME --username $ACR_USERNAME --password $ACR_PASSWORD

docker tag gateway-app:1.0.0 $ACR_NAME/gateway-app:1.0.0
docker tag aggregator-app:1.0.1 $ACR_NAME/aggregator-app:1.0.1
docker tag serviceone-app:1.0.0 $ACR_NAME/serviceone-app:1.0.0
docker tag servicetwo-app:1.0.0 $ACR_NAME/servicetwo-app:1.0.0

docker push $ACR_NAME/gateway-app:1.0.0
docker push $ACR_NAME/aggregator-app:1.0.1
docker push $ACR_NAME/serviceone-app:1.0.0
docker push $ACR_NAME/servicetwo-app:1.0.0