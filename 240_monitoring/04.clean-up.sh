#!/bin/bash

kubectl delete deployment nginx-deployment

helm uninstall prometheus --namespace prometheus
kubectl delete ns prometheus

helm uninstall grafana --namespace grafana
kubectl delete ns grafana

rm -rf ${HOME}/environment/grafana

cd ~/environment/eksworkshop-custom

