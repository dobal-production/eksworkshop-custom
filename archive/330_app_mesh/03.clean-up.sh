#!/bin/bash

kubectl delete namespace prod
kubectl delete meshes dj-app
helm -n appmesh-system delete appmesh-controller
for i in $(kubectl get crd | grep appmesh | cut -d" " -f1) ; do
kubectl delete crd $i
done
kubectl delete namespace appmesh-system
eksctl delete iamserviceaccount --cluster eksworkshop-eksctl   --namespace appmesh-system --name appmesh-controller
