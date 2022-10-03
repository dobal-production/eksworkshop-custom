#!/bin/bash
cd ~/environment

# after attach role, UPDATE IAM SETTINGS FOR YOUR WORKSPACE
aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))

# Custom vpc일 경우 아래 주석 제거
#export SUBNET_IDS=($(aws ec2 describe-subnets --query 'sort_by(Subnets, &AvailabilityZoneId)[].SubnetId' --filters "Name=tag:Name,Values=*EKS Worker Node Subnet*" --output text --region $AWS_REGION))
#export SUBNET_CIDRS=($(aws ec2 describe-subnets --query 'sort_by(Subnets, &AvailabilityZoneId)[].CidrBlock' --filters "Name=tag:Name,Values=*EKS Worker Node Subnet*" --output text --region $AWS_REGION))
#export VPC_ID=($(aws ec2 describe-vpcs --query 'Vpcs[].VpcId' --filters "Name=tag:Name,Values=*eksworkshop*" --output text --region $AWS_REGION))
#export VPC_CIDR=($(aws ec2 describe-vpcs --query 'Vpcs[].CidrBlock' --filters "Name=tag:Name,Values=*eksworkshop*" --output text --region $AWS_REGION))

test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo AWS_REGION is not set

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export AZS=(${AZS[@]})" | tee -a ~/.bash_profile
# Custom vpc일 경우 아래 주석 제거
#echo "export SUBNET_IDS=(${SUBNET_IDS[@]})" | tee -a ~/.bash_profile
#echo "export SUBNET_CIDRS=(${SUBNET_CIDRS[@]})" | tee -a ~/.bash_profile
#echo "export VPC_ID=${VPC_ID}" | tee -a ~/.bash_profile 
#echo "export VPC_CIDR=${VPC_CIDR}" | tee -a ~/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

aws sts get-caller-identity --query Arn | grep eksworkshop-admin -q && echo "IAM role valid" || echo "IAM role NOT valid"

# aws sts get-caller-identity --query Arn | grep DobalCloud9BaseRole -q && echo "IAM role valid" || echo "IAM role NOT valid"

# CLONE THE SERVICE REPOS
cd ~/environment
git clone https://github.com/aws-containers/ecsdemo-frontend.git
git clone https://github.com/aws-containers/ecsdemo-nodejs.git
git clone https://github.com/aws-containers/ecsdemo-crystal.git

# CREATE AN AWS KMS CUSTOM MANAGED KEY (CMK)
# custom일 경우 경우 아래의 주석 제거
# aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)
# export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)
export MASTER_ARN=$(aws eks describe-cluster --name eksworkshop-eksctl --query cluster.encryptionConfig[0].provider.keyArn --output text)
echo "export MASTER_ARN=${MASTER_ARN}" | tee -a ~/.bash_profile

.  ~/.bash_profile
cat ~/.bash_profile

cd ~/environment/eksworkshop/000.preparations