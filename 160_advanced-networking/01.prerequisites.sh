#!/bin/bash
# uninstall opsview
helm uninstall kube-ops-view
sleep 10s

# Add secondary CIDRs to VPC
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-eksworkshop* --query 'Vpcs[].VpcId' --output text)

echo "associate secondary cidr to vpc"
aws ec2 associate-vpc-cidr-block --vpc-id $VPC_ID --cidr-block 100.64.0.0/16

sleep 10s
aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --query 'Reservations[*].Instances[*].[PrivateDnsName,Tags[?Key==`eks:nodegroup-name`].Value|[0],Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress]' --output table   

export POD_AZS=($(aws ec2 describe-instances --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone]' --output text | sort | uniq))
echo ${POD_AZS[@]}

CGNAT_SNET1=$(aws ec2 create-subnet --cidr-block 100.64.0.0/19 --vpc-id $VPC_ID --availability-zone ${POD_AZS[0]} --query 'Subnet.SubnetId' --output text)
CGNAT_SNET2=$(aws ec2 create-subnet --cidr-block 100.64.32.0/19 --vpc-id $VPC_ID --availability-zone ${POD_AZS[1]} --query 'Subnet.SubnetId' --output text)
CGNAT_SNET3=$(aws ec2 create-subnet --cidr-block 100.64.64.0/19 --vpc-id $VPC_ID --availability-zone ${POD_AZS[2]} --query 'Subnet.SubnetId' --output text)

unset POD_AZS

sleep 10s
SNET1=$(aws ec2 describe-subnets --filters Name=cidr-block,Values=192.168.0.0/19 --query 'Subnets[].SubnetId' --output text)
RTASSOC_ID=$(aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$SNET1 --query 'RouteTables[].RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CGNAT_SNET1
aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CGNAT_SNET2
aws ec2 associate-route-table --route-table-id $RTASSOC_ID --subnet-id $CGNAT_SNET3
