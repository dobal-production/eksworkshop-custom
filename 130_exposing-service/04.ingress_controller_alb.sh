#!/bin/bash

if [ ! -x ${LBC_VERSION} ]
  then
    tput setaf 2; echo '${LBC_VERSION} has been set.'
  else
    tput setaf 1;echo '${LBC_VERSION} has NOT been set.'
fi

echo "##### Create IAM OIDC Provider\n"
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster eksworkshop-eksctl \
    --approve

echo "#####Create an IAM policy called\n"
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/${LBC_VERSION}/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

echo "#####Create a IAM role and ServiceAccount\n"
eksctl create iamserviceaccount \
  --cluster eksworkshop-eksctl \
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

helm upgrade -i aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=eksworkshop-eksctl \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller 

kubectl -n kube-system rollout status deployment aws-load-balancer-controller

echo "#####Sleep 30s\n"
echo "#####Deploy Sample Application(2048 Game)\n"
export EKS_CLUSTER_VERSION=$(aws eks describe-cluster --name eksworkshop-eksctl --query cluster.version --output text)

if [ "`echo "${EKS_CLUSTER_VERSION} < 1.19" | bc`" -eq 1 ]; then     
    curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/examples/2048/2048_full.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | kubectl apply -f -
fi

if [ "`echo "${EKS_CLUSTER_VERSION} >= 1.19" | bc`" -eq 1 ]; then     
    curl -s https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/examples/2048/2048_full_latest.yaml \
    | sed 's=alb.ingress.kubernetes.io/target-type: ip=alb.ingress.kubernetes.io/target-type: instance=g' \
    | kubectl apply -f -
fi

sleep 10s

kubectl get ingress/ingress-2048 -n game-2048

sleep 120s
echo "#####Display ingress information\n"
export GAME_INGRESS_NAME=$(kubectl -n game-2048 get targetgroupbindings -o jsonpath='{.items[].metadata.name}')
kubectl -n game-2048 get targetgroupbindings ${GAME_INGRESS_NAME} -o yaml

export GAME_2048=$(kubectl get ingress/ingress-2048 -n game-2048 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo http://${GAME_2048}


