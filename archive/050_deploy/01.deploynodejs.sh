#!/bin/bash

cd ~/environment/ecsdemo-nodejs
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

sleep 10s

kubectl get deployment ecsdemo-nodejs

cd ~/environment/eksworkshop-custom/050_deploy
