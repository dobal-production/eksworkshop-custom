#!/bin/bash

cat <<EOF >pod-netconfig.template
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
 name: \${AZ}
spec:
 subnet: \${SUBNET_ID}
 securityGroups: [ \${NETCONFIG_SECURITY_GROUPS} ]
EOF

aws ec2 describe-subnets  --filters "Name=cidr-block,Values=100.64.*" --query 'Subnets[*].[CidrBlock,SubnetId,AvailabilityZone]' --output table

kubectl get nodes  # Make sure new nodes are listed with 'Ready' status

INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --output text`)

export NETCONFIG_SECURITY_GROUPS=$(for i in "${INSTANCE_IDS[@]}"; do  aws ec2 describe-instances --instance-ids $i | jq -r '.Reservations[].Instances[].SecurityGroups[].GroupId'; done  | sort | uniq | awk -vORS=, '{print $1 }' | sed 's/,$//')

echo $NETCONFIG_SECURITY_GROUPS

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

cd $HOME/environment
kubectl apply -f eniconfig

sleep 10s
kubectl get eniconfig

aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --query 'Reservations[*].Instances[*].[PrivateDnsName,Tags[?Key==`eks:nodegroup-name`].Value|[0],Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress]' --output table  

# modify <nodename> belows and remove #
#kubectl annotate node <nodename>.ap-northeast-2.compute.internal k8s.amazonaws.com/eniConfig=ap-northeast-2a
#kubectl annotate node <nodename>.ap-northeast-2.compute.internal  k8s.amazonaws.com/eniConfig=ap-northeast-2b
#kubectl annotate node <nodename>.ap-northeast-2.compute.internal  k8s.amazonaws.com/eniConfig=ap-northeast-2c
#kubectl set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone
