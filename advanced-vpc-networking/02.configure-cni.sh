#1/bin/bash

# check cni version
kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2

# Configure custom networking
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
kubectl describe daemonset aws-node -n kube-system | grep -A5 Environment

INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --output text` )
for i in "${INSTANCE_IDS[@]}"
do
	echo "Terminating EC2 instance $i ..."
	aws ec2 terminate-instances --instance-ids $i
done

# 노드가 다시 생성되더라도 일부 pod가 비정상이다. 
# 이것을 해 주어야 pod가 제대로 올라온다.
# Install ENIConfig CRD
wget https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.11/config/master/aws-k8s-cni.yaml
kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.11/config/master/aws-k8s-cni.yamlops-view는 