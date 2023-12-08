#!/bin/bash

mkdir ~/environment/resource-management

kubectl create namespace low-usage
kubectl create namespace high-usage
kubectl create namespace unrestricted-usage

echo "##### Create Limit Ranges"
cat <<EoF > ~/environment/resource-management/low-usage-limit-range.yml
apiVersion: v1
kind: LimitRange
metadata:
  name: low-usage-range
spec:
  limits:
  - max:
      cpu: 1
      memory: 300M 
    min:
      cpu: 0.5
      memory: 100M
    type: Container
EoF

kubectl apply -f ~/environment/resource-management/low-usage-limit-range.yml --namespace low-usage


cat <<EoF > ~/environment/resource-management/high-usage-limit-range.yml
apiVersion: v1
kind: LimitRange
metadata:
  name: high-usage-range
spec:
  limits:
  - max:
      cpu: 2
      memory: 2G 
    min:
      cpu: 1
      memory: 1G
    type: Container
EoF

kubectl apply -f ~/environment/resource-management/high-usage-limit-range.yml --namespace high-usage

echo "##### Deploy pods"
# Error due to higher memory request than defined in low-usage namespace: Invalid value: "1G": must be less than or equal to memory limit
kubectl run --namespace low-usage --requests=memory=1G,cpu=0.5 --image  hande007/stress-ng basic-request-pod --restart=Never --  --vm-keep   --vm-bytes 2g --timeout 600s --vm 1 --oomable --verbose 

# Error due to lower cpu request than defined in high-usage namespace: wanted 0.5 below min of 1
kubectl run --namespace high-usage --requests=memory=1G,cpu=0.5 --image  hande007/stress-ng basic-request-pod --restart=Never --  --vm-keep   --vm-bytes 2g --timeout 600s --vm 1 --oomable --verbose 

sleep 10s

echo -n "Check error messages"
read text

kubectl run --namespace low-usage --image  hande007/stress-ng low-usage-pod --restart=Never --  --vm-keep   --vm-bytes 200m --timeout 600s --vm 2 --oomable --verbose 
kubectl run --namespace high-usage  --image  hande007/stress-ng high-usage-pod --restart=Never --  --vm-keep   --vm-bytes 200m --timeout 600s --vm 2 --oomable --verbose 
kubectl run --namespace unrestricted-usage --image  hande007/stress-ng unrestricted-usage-pod --restart=Never --  --vm-keep   --vm-bytes 200m --timeout 600s --vm 2 --oomable --verbose 

sleep 20s
eval 'kubectl  -n='{low-usage,high-usage,unrestricted-usage}' get pod -o=custom-columns='Name:spec.containers[*].name','Namespace:metadata.namespace','Limits:spec.containers[*].resources.limits';'

echo -n "Check error messages"
read text

kubectl delete namespace low-usage
kubectl delete namespace high-usage
kubectl delete namespace unrestricted-usage

cd ~/environment/eksworkshop-custom