#!/bin/bash

kubectl delete -f ~/environment/redis-with-node-affinity.yaml
kubectl delete -f ~/environment/web-with-node-affinity.yaml
kubectl label nodes --all azname-
kubectl label nodes --all disktype-
