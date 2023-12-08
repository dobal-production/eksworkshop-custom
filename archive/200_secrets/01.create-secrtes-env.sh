#!/bin/bash

#Run the following set of commands to generate a Secret using Kubectl and Kustomize.
mkdir -p ~/environment/secrets
cd ~/environment/secrets
wget https://eksworkshop.com/beginner/200_secrets/secrets.files/kustomization.yaml
kubectl kustomize . > secret.yaml

kubectl create namespace octank
kubectl apply -f secret.yaml

wget https://eksworkshop.com/beginner/200_secrets/secrets.files/pod-variable.yaml
kubectl apply -f pod-variable.yaml
kubectl get pod -n octank

kubectl logs pod-variable -n octank

# The output should look as follows:
# DATABASE_USER = admin
# DATABASE_PASSWROD = Tru5tN0!
