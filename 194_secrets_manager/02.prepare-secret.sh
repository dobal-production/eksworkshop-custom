#!/bin/bash

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set
export EKS_CLUSTERNAME="eksworkshop-eksctl"

echo "##### Create a test secret with the AWS Secrets Manager."
aws --region "$AWS_REGION" secretsmanager \
  create-secret --name DBSecret_eksworkshop \
  --secret-string '{"username":"foo", "password":"super-sekret"}'

echo "#####  Get secret’s ARN."
SECRET_ARN=$(aws --region "$AWS_REGION" secretsmanager \
    describe-secret --secret-id  DBSecret_eksworkshop \
    --query 'ARN' | sed -e 's/"//g' )

echo $SECRET_ARN

echo "#####  Create an IAM with permissions to access the secret."
IAM_POLICY_NAME_SECRET="DBSecret_eksworkshop_secrets_policy_$RANDOM"
IAM_POLICY_ARN_SECRET=$(aws --region "$AWS_REGION" iam \
	create-policy --query Policy.Arn \
    --output text --policy-name $IAM_POLICY_NAME_SECRET \
    --policy-document '{
    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": ["'"$SECRET_ARN"'" ]
    } ]
}')

echo $IAM_POLICY_ARN_SECRET | tee -a 00_iam_policy_arn_dbsecret

# Create a Service Account with IAM role
eksctl utils associate-iam-oidc-provider \
    --region="$AWS_REGION" --cluster="$EKS_CLUSTERNAME" \
    --approve

eksctl create iamserviceaccount \
    --region="$AWS_REGION" --name "nginx-deployment-sa"  \
    --cluster "$EKS_CLUSTERNAME" \
    --attach-policy-arn "$IAM_POLICY_ARN_SECRET" --approve \
    --override-existing-serviceaccounts

