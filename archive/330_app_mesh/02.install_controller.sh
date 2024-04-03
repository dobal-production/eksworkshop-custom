#!/bin/bash

helm repo add eks https://aws.github.io/eks-charts
helm repo list | grep eks-charts

kubectl create ns appmesh-system

# Create your OIDC identity provider for the cluster
eksctl utils associate-iam-oidc-provider \
  --cluster eksworkshop-eksctl \
  --approve

# Download the IAM policy document for the controller
curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json

# Create an IAM policy for the controller from the policy document
aws iam create-policy \
    --policy-name AWSAppMeshK8sControllerIAMPolicy \
    --policy-document file://controller-iam-policy.json

# Create an IAM role and service account for the controller
eksctl create iamserviceaccount \
  --cluster eksworkshop-eksctl \
  --namespace appmesh-system \
  --name appmesh-controller \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AWSAppMeshK8sControllerIAMPolicy  \
  --override-existing-serviceaccounts \
  --approve

# Now install App Mesh Controller into the appmesh-system namespace using the project’s Helm chart.
helm upgrade -i appmesh-controller eks/appmesh-controller \
  --namespace appmesh-system \
  --set region=${AWS_REGION} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=appmesh-controller

sleep 10s
kubectl -n appmesh-system get all
kubectl get crds | grep appmesh
