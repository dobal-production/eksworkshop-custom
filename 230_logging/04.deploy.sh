#!/bin/bash

cd ~/environment/logging

# get the Amazon OpenSearch Endpoint
export ES_ENDPOINT=$(aws es describe-elasticsearch-domain --domain-name ${ES_DOMAIN_NAME} --output text --query "DomainStatus.Endpoint")

curl -Ss https://www.eksworkshop.com/intermediate/230_logging/deploy.files/fluentbit.yaml \
    | envsubst > ~/environment/logging/fluentbit.yaml

kubectl apply -f ~/environment/logging/fluentbit.yaml

sleep 10s
kubectl --namespace=logging get pods

cd ~/environment/eksworkshop-custom/230_logging

helm repo add bitnami https://charts.bitnami.com/bitnami

helm install mywebserver bitnami/nginx
