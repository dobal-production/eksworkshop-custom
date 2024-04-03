#!/bin/bash

cd ~/environment/eks-workshop/base-application/
git clone https://codeberg.org/hjacobs/kube-ops-view.git
cd kube-ops-view
sed -i 's/ClusterIP/LoadBalancer/g' deploy/service.yaml
kubectl apply -k deploy

sleep 20s
kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'