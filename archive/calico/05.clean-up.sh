#!/bin/bash

kubectl delete namespace client stars management-ui
kubectl delete deployments.apps -n kube-system calico-typha 
kubectl delete deployments.apps -n kube-system calico-typha-horizontal-autoscaler 
kubectl delete daemonset calico-node -n kube-system