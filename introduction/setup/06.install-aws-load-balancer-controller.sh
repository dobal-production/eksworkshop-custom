#!/bin/bash
echo "https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html\n"
echo "##### Create IAM OIDC Provider\n"
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${EKS_CLUSTER_NAME} \
    --approve

echo "#####Create an IAM policy called\n"
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

echo "#####Create a IAM role and ServiceAccount\n"
eksctl create iamserviceaccount \
  --cluster ${EKS_CLUSTER_NAME} \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

echo "#####Install cert-manager\n"
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.12.3/cert-manager.yaml

echo "#####Install load balancer controller\n"
curl -Lo v2_5_4_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_full.yaml
sed -i.bak -e '596,604d' ./v2_5_4_full.yaml
sed -i.bak -e 's|your-cluster-name|${EKS_CLUSTER_NAME}|' ./v2_5_4_full.yaml
kubectl apply -f v2_5_4_full.yaml
curl -Lo v2_5_4_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.5.4/v2_5_4_ingclass.yaml
kubectl apply -f v2_5_4_ingclass.yaml

echo "#####verify aws-load-balancer-controller\n"
kubectl get deployment -n kube-system aws-load-balancer-controller
