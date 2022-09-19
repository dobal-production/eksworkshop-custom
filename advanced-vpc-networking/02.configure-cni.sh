#!/bin/bash

# check cni version
kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2

# Configure custom networking
echo "before configure"
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
echo "after configure"
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment

# Terminate all nodes
INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --output text` )
for i in "${INSTANCE_IDS[@]}"
do
	echo "Terminating EC2 instance $i ..."
	aws ec2 terminate-instances --instance-ids $i
done

# ops-view 다시 설치
helm install kube-ops-view \
stable/kube-ops-view \
--set service.type=LoadBalancer \
--set rbac.create=True

sleep 10s

kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'