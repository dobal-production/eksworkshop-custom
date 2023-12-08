#!/bin/bash

# Deploy request pod with soft limit on memory 
kubectl run --requests=memory=1G,cpu=0.5 --image  hande007/stress-ng basic-request-pod --restart=Never --  --vm-keep  --vm-bytes 2g --timeout 600s --vm 1 --oomable --verbose 

# Deploy limit-cpu pod with hard limit on cpu at 500m but wants 1000m
kubectl run --limits=memory=1G,cpu=0.5 --image  hande007/stress-ng basic-limit-cpu-pod --restart=Never --  --vm-keep --vm-bytes 512m --timeout 600s --vm 1 --oomable --verbose 

# Deploy limit-memory pod with hard limit on memory at 1G but wants 2G
kubectl run --limits=memory=1G,cpu=1 --image  hande007/stress-ng basic-limit-memory-pod --restart=Never --  --vm-keep  --vm-bytes 2g --timeout 600s --vm 1 --oomable --verbose 

# Deploy restricted pod with limits and requests that wants cpu 2 and memory 1G
kubectl run --requests=memory=1G,cpu=1 --limits=memory=2G,cpu=1.8 --image  hande007/stress-ng basic-restricted-pod  --restart=Never --  --vm-keep  --vm-bytes 1g --timeout 600s --vm 2 --oomable --verbose 

sleep 10s

echo -n "##### Do not press any key, until Dobal says 'Enter any key'"
read text

echo "##### Clean-up"
kubectl delete pod basic-request-pod
kubectl delete pod basic-limit-memory-pod
kubectl delete pod basic-limit-cpu-pod
kubectl delete pod basic-restricted-pod

