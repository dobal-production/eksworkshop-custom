#!/bin/bash

kubectl create namespace bookinfo
kubectl label namespace bookinfo istio-injection=enabled
kubectl get ns bookinfo --show-labels

kubectl -n bookinfo apply \
  -f ${HOME}/environment/istio-${ISTIO_VERSION}/samples/bookinfo/platform/kube/bookinfo.yaml



