#!/bin/bash
export ARGOCD_VER=2.10.9
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VER}/manifests/install.yaml
kubectl delete namespace argocd