#!/bin/bash

kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > master.yaml
kubectl delete secret database-credentials -n octank
kubectl delete sealedsecret database-credentials -n octank
kubectl delete secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key
kubectl delete -f controller.yaml 

kubectl apply -f master.yaml 
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key

kubectl apply -f controller.yaml
kubectl get pods -n kube-system | grep sealed-secrets-controller

kubectl apply -f sealed-secret.yaml 
kubectl logs sealed-secrets-controller-84fcdcd5fd-ds5t6 -n kube-system
