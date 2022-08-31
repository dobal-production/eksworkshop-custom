#!/bin/bash
cd ~/environment

kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.6/config/v1.6/calico.yaml

kubectl get daemonset calico-node --namespace=kube-system
