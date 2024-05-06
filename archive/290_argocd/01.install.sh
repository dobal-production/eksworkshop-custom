#!/bin/bash
export ARGOCD_VER=2.10.9
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VER}/manifests/install.yaml

sudo curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v{ARGOCD_VER}/argocd-linux-amd64

sudo chmod +x /usr/local/bin/argocd
