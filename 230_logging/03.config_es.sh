#!/bin/bash

# We need to retrieve the Fluent Bit Role ARN
export FLUENTBIT_ROLE=$(eksctl get iamserviceaccount --cluster eksworkshop-eksctl --namespace logging -o json | jq '.[].status.roleARN' -r)

# Get the Amazon OpenSearch Endpoint
export ES_ENDPOINT=$(aws opensearch describe-domain --domain-name ${ES_DOMAIN_NAME} --output text --query "DomainStatus.Endpoint")

# Update the Elasticsearch internal database
curl -sS -u "${ES_DOMAIN_USER}:${ES_DOMAIN_PASSWORD}" \
    -X PATCH \
    https://${ES_ENDPOINT}/_opendistro/_security/api/rolesmapping/all_access?pretty \
    -H 'Content-Type: application/json' \
    -d'
[
  {
    "op": "add", "path": "/backend_roles", "value": ["'${FLUENTBIT_ROLE}'"]
  }
]
'
