#!/bin/bash

kubectl delete -f nginx-deployment-k8s-secrets.yaml
rm nginx-deployment-k8s-secrets.yaml

kubectl delete -f nginx-deployment-spc-k8s-secrets.yaml
rm nginx-deployment-spc-k8s-secrets.yaml

kubectl delete -f nginx-deployment.yaml
rm nginx-deployment.yaml

kubectl delete -f nginx-deployment-spc.yaml
rm nginx-deployment-spc.yaml

eksctl delete iamserviceaccount \
    --region="$AWS_REGION" --name "nginx-deployment-sa"  \
    --cluster "$EKS_CLUSTERNAME" 

sleep 5

aws --region "$AWS_REGION" iam \
	delete-policy --policy-arn $(cat 00_iam_policy_arn_dbsecret)
unset IAM_POLICY_ARN_SECRET
unset IAM_POLICY_NAME_SECRET
rm 00_iam_policy_arn_dbsecret

aws --region "$AWS_REGION" secretsmanager \
  delete-secret --secret-id DBSecret_eksworkshop --force-delete-without-recovery

kubectl delete -f \
 https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

helm uninstall -n kube-system csi-secrets-store
helm repo remove secrets-store-csi-driver
