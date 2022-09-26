#!/bin/bash

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sleep 60s

echo -n "After clb available....., press any key"
read text

export ARGOCD_SERVER=`kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname'`
export ARGO_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

echo $ARGOCD_SERVER
echo "admin"
echo $ARGO_PWD

argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure

