#!/bin/bash

eksctl utils associate-iam-oidc-provider \
    --cluster eksworkshop-eksctl \
    --approve

echo "##### Creating an IAM role and policy for your service account"
mkdir ~/environment/logging/

export ES_DOMAIN_NAME="eksworkshop-logging"

cat <<EoF > ~/environment/logging/fluent-bit-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "es:ESHttp*"
            ],
            "Resource": "arn:aws:es:${AWS_REGION}:${ACCOUNT_ID}:domain/${ES_DOMAIN_NAME}",
            "Effect": "Allow"
        }
    ]
}
EoF

aws iam create-policy   \
  --policy-name fluent-bit-policy \
  --policy-document file://~/environment/logging/fluent-bit-policy.json

kubectl create namespace logging

eksctl create iamserviceaccount \
    --name fluent-bit \
    --namespace logging \
    --cluster eksworkshop-eksctl \
    --attach-policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/fluent-bit-policy" \
    --approve \
    --override-existing-serviceaccounts

kubectl -n logging describe sa fluent-bit

cd ~/environment/eksworkshop-custom/230_logging
