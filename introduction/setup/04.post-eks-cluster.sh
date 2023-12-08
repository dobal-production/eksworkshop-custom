#!/bin/bash
cd ~/environment

# for blueprint it doesn't work
kubectl get nodes # if we see our 3 nodes, we know we have authenticated correctly
aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

kubectl get nodes # if we see our 3 nodes, we know we have authenticated correctly

STACK_NAME=$(eksctl get nodegroup --cluster ${EKS_CLUSTER_NAME} -o json | jq -r '.[].StackName')
ROLE_NAME=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME | jq -r '.StackResources[] | select(.ResourceType=="AWS::IAM::Role") | .PhysicalResourceId')
echo "export ROLE_NAME=${ROLE_NAME}" | tee -a ~/.bash_profile

# Import your EKS Console credentials to your new cluster
c9builder=$(aws cloud9 describe-environment-memberships --environment-id=$C9_PID | jq -r '.memberships[].userArn')
if echo ${c9builder} | grep -q user; then
	rolearn=${c9builder}
        echo Role ARN: ${rolearn}
elif echo ${c9builder} | grep -q assumed-role; then
        assumedrolename=$(echo ${c9builder} | awk -F/ '{print $(NF-1)}')
        rolearn=$(aws iam get-role --role-name ${assumedrolename} --query Role.Arn --output text) 
        echo Role ARN: ${rolearn}
fi

eksctl create iamidentitymapping --cluster ${EKS_CLUSTER_NAME} --arn ${rolearn} --group system:masters --username admin

kubectl describe configmap -n kube-system aws-auth

cd ~/environment/eksworkshop-custom/introduction/setup
