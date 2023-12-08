#!/bin/bash

# Create a namespace wordpress
kubectl create namespace wordpress-cwi

# Add the bitnami Helm Charts Repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Deploy WordPress in its own namespace
helm -n wordpress-cwi install understood-zebu bitnami/wordpress

kubectl -n wordpress-cwi rollout status deployment understood-zebu-wordpress
