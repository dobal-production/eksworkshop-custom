!#/bin/bash

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard

sleep 10s
kubectl patch svc kubernetes-dashboard -n default -p '{"spec":{"type":"LoadBalancer"}}'

sleep 10s
kubectl get svc kubernetes-dashboard -n default | tail -n 1 | awk '{ print "kube-dashboard URL = https://"$4 }'

sleep 10s
aws eks get-token --cluster-name eksworkshop-eksctl | jq -r '.status.token'

