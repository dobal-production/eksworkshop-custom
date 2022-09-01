#!/bin/bash

kubectl delete namespace client stars management-ui
kubectl delete daemonset calico-node -n kube-system