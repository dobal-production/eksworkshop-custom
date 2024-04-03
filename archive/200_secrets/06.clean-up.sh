#!/bin/bash

cd ~/environment/secrets
kubectl delete Secret --all -n octank
kubectl delete SealedSecret --all -n octank
kubectl delete pod --all -n octank
kubectl delete -f controller.yaml
kubectl delete namespace octank
