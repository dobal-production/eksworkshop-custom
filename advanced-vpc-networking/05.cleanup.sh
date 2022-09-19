kubectl delete deployments --all
kubectl delete service  nginx

cd $HOME/environment
kubectl delete -f eniconfig

rm -rf pod-netconfig.template eniconfig

# Terminate node
INSTANCE_IDS=(`aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --filters "Name=tag-key,Values=eks:cluster-name" "Name=tag-value,Values=eksworkshop*" --output text` )
for i in "${INSTANCE_IDS[@]}"
do
	echo "Terminating EC2 instance $i ..."
	aws ec2 terminate-instances --instance-ids $i
done
sleep 5m

# remove secondary cidr
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=eksctl-eksworkshop* | jq -r '.Vpcs[].VpcId')
ASSOCIATION_ID=$(aws ec2 describe-vpcs --vpc-id $VPC_ID | jq -r '.Vpcs[].CidrBlockAssociationSet[] | select(.CidrBlock == "100.64.0.0/16") | .AssociationId')
aws ec2 delete-subnet --subnet-id $CGNAT_SNET1
aws ec2 delete-subnet --subnet-id $CGNAT_SNET2
aws ec2 delete-subnet --subnet-id $CGNAT_SNET3
aws ec2 disassociate-vpc-cidr-block --association-id $ASSOCIATION_ID
