#!/bin/bash

cd ~/environment/ecsdemo-crystal
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

sleep 10s

kubectl get deployment ecsdemo-crystal

cd ~/environment/eksworkshop-custom/050_deploy