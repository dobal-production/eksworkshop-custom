#!/bin/bash

cd ~/environment
git clone https://codeberg.org/hjacobs/kube-ops-view.git
cd kube-ops-view

# built-in kustomization command with -k
kubectl apply -k deploy

export KOV_POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=kube-ops-view,app.kubernetes.io/instance=kube-ops-view" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $KOV_POD_NAME 8080:8080

# preview > preview running application