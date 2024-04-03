#!/bin/bash

wget https://eksworkshop.com/beginner/200_secrets/secrets.files/pod-volume.yaml
kubectl apply -f pod-volume.yaml
kubectl get pod -n octank

kubectl logs pod-volume -n octank

# The output should look as follows:
# cat /etc/data/DATABASE_USER
# admin
# cat /etc/data/DATABASE_PASSWORD
# Tru5tN0!