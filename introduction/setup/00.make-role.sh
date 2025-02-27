#!/bin/bash

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export CLUSTER_NAME=eks-workshop
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))
export CLOUD9_ROLE=cloud9-role
export CLOUD9_ROLE_PROFILE=cloud9-role-profile

echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile
echo "export CLUSTER_NAME=${CLUSTER_NAME}" | tee -a ~/.bash_profile
echo "export AZS=(${AZS[@]})" | tee -a ~/.bash_profile

cat << EOF > cloud9-role.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Principal": {
                "Service": [
                    "ec2.amazonaws.com"
                ]
            }
        }
    ]
}
EOF

aws iam create-role \
  --role-name ${CLOUD9_ROLE} \
  --assume-role-policy-document file://cloud9-role.json \
  --no-cli-pager

aws iam attach-role-policy \
  --role-name ${CLOUD9_ROLE} \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
  --no-cli-pager

aws iam attach-role-policy \
  --role-name ${CLOUD9_ROLE} \
  --policy-arn arn:aws:iam::aws:policy/AWSCloud9SSMInstanceProfile \
  --no-cli-pager

aws iam create-instance-profile \
  --instance-profile-name ${CLOUD9_ROLE_PROFILE} \
  --no-cli-pager

aws iam add-role-to-instance-profile \
  --instance-profile-name ${CLOUD9_ROLE_PROFILE} \
  --role-name ${CLOUD9_ROLE} \
  --no-cli-pager
