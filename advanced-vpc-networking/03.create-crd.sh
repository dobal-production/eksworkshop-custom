#!/bin/bash

# 노드가 다시 생성되더라도 일부 pod가 비정상이다. 
# 이것을 해 주어야 pod가 제대로 올라온다.
# Install ENIConfig CRD
# wget https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.11/config/master/aws-k8s-cni.yaml
# kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.11/config/master/aws-k8s-cni.yamㅣ

cd ~/environment

cat <<EOF >pod-netconfig.template
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: \${AZ}
spec:
 subnet: \${SUBNET_ID}
 securityGroups: [ \${NETCONFIG_SECURITY_GROUPS} ]
EOF

# display new subnets
aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*" --query 'Subnets[*].[CidrBlock,SubnetId,AvailabilityZone]' --output table

# Make sure new nodes are listed with 'Ready' status
kubectl get nodes  

# check sg for worker node
INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --output text`)
export NETCONFIG_SECURITY_GROUPS=$(for i in "${INSTANCE_IDS[@]}"; do  aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[].GroupId'; done  | sort | uniq | awk -vORS=, '{print $1 }' | sed 's/,$//')
echo $NETCONFIG_SECURITY_GROUPS

# update latest yq
yq --help >/dev/null  && echo "yq command working" || "yq command not working"

# create eniconfig custom resource per AZ
cd $HOME/environment
mkdir -p eniconfig
while IFS= read -r line
do
 arr=($line)
 OUTPUT=`AZ=${arr[0]} SUBNET_ID=${arr[1]} envsubst < pod-netconfig.template | yq eval -P`
 FILENAME=${arr[0]}.yaml
 echo "Creating ENIConfig file:  eniconfig/$FILENAME"
 cat <<EOF >eniconfig/$FILENAME
$OUTPUT
EOF
done< <(aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*" --query 'Subnets[*].[AvailabilityZone,SubnetId]' --output text)

# Apply crd for each AZ
cd $HOME/environment
kubectl apply -f eniconfig

sleep 10s
kubectl get eniconfig

aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --query 'Reservations[*].Instances[*].[PrivateDnsName,Tags[?Key==`eks:nodegroup-name`].Value|[0],Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress]' --output table  

# modify <nodename> belows and remove #
#kubectl annotate node <nodename>.ap-northeast-2.compute.internal k8s.amazonaws.com/eniConfig=ap-northeast-2a
#kubectl annotate node <nodename>.ap-northeast-2.compute.internal  k8s.amazonaws.com/eniConfig=ap-northeast-2b
#kubectl annotate node <nodename>.ap-northeast-2.compute.internal  k8s.amazonaws.com/eniConfig=ap-northeast-2c

kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone
