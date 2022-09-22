#!/bin/bash

echo "##### Secrets Store CSI Driver:"
helm repo add secrets-store-csi-driver \
  https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts

helm install -n kube-system csi-secrets-store \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  secrets-store-csi-driver/secrets-store-csi-driver

echo "#####  ASCP"
kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

echo "#####  Verifiy the installation"
sleep 10s
kubectl get daemonsets -n kube-system -l app=csi-secrets-store-provider-aws
kubectl get daemonsets -n kube-system -l app.kubernetes.io/instance=csi-secrets-store
