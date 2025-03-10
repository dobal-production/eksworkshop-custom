#!/bin/bash
echo "https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html\n"
echo "##### Create IAM OIDC Provider\n"
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${EKS_CLUSTER_NAME} \
    --approve

# https://docs.aws.amazon.com/eks/latest/userguide/lbc-manifest.html    
export LB_VERSION="v2.11.0"
export LB_NAME="v2_11_0"
export CERT_VER="v1.13.5"

echo "#####Create an IAM policy called\n"
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${LB_VERSION}/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

sleep 15

echo "#####Create a IAM role and ServiceAccount\n"
eksctl create iamserviceaccount \
  --cluster ${EKS_CLUSTER_NAME} \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

sleep 15

echo "#####Install cert-manager\n"
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/${CERT_VER}/cert-manager.yaml

sleep 15

echo "#####Install load balancer controller\n"
curl -Lo ${LB_NAME}_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/${LB_VERSION}/${LB_NAME}_full.yaml
sed -i.bak -e '690,698d' ./${LB_NAME}_full.yaml
sed -i.bak -e "s|your-cluster-name|${EKS_CLUSTER_NAME}|" ./${LB_NAME}_full.yaml
kubectl apply -f ${LB_NAME}_full.yaml

sleep 15

curl -Lo ${LB_NAME}_ingclass.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/${LB_VERSION}/${LB_NAME}_ingclass.yaml
kubectl apply -f ${LB_NAME}_ingclass.yaml

echo "#####verify aws-load-balancer-controller\n"
kubectl get deployment -n kube-system aws-load-balancer-controller
