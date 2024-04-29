#!/bin/bash

echo "##### Create IAM OIDC Provider\n"
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --approve

echo "#####Create an IAM policy called\n"
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

echo "#####Create a IAM role and ServiceAccount\n"
eksctl create iamserviceaccount \
  --cluster ${CLUSTER_NAME} \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

echo "#####Install the TargetGroupBinding CRDs\n"
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
kubectl get crd

echo "#####Deploy the Helm chart\n"
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

helm upgrade -i aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=${CLUSTER_NAME} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

kubectl -n kube-system rollout status deployment aws-load-balancer-controller
