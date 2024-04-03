#!/bin/bash

export CLOUD9_ROLE=eks-admin
cat << EOF > eks-admin.json
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
  --assume-role-policy-document file://eks-admin.json \
  --no-cli-pager

aws iam attach-role-policy \
  --role-name ${CLOUD9_ROLE} \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
  --no-cli-pager

aws iam create-instance-profile \
  --instance-profile-name ${CLOUD9_ROLE} \
  --no-cli-pager

aws iam add-role-to-instance-profile \
  --instance-profile-name ${CLOUD9_ROLE} \
  --role-name ${CLOUD9_ROLE} \
  --no-cli-pager
