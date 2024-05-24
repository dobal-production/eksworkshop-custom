#!/bin/bash

cat << EOF > argocd-server-patch.yaml
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external 
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
spec:
  type: LoadBalancer
EOF

kubectl patch svc argocd-server -n argocd --patch-file argocd-server-patch.yaml
sleep 60s

echo -n "After clb available....., press any key"
read text


ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
echo "ArgoCD URL: http://$ARGOCD_SERVER"

ARGOCD_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PWD"

argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure