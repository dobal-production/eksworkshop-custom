#!/bin/bash

test -n "$ROLE_NAME" && echo ROLE_NAME is "$ROLE_NAME" || echo ROLE_NAME is not set

echo "##### add the necessary policy to the IAM role for worker nodes"
echo "________________"
aws iam attach-role-policy \
  --role-name $ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

aws iam list-attached-role-policies --role-name $ROLE_NAME | grep CloudWatchAgentServerPolicy || echo 'Policy not found'
