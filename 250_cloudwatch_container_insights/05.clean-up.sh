#!/bin/bash

helm -n wordpress-cwi uninstall understood-zebu

kubectl delete namespace wordpress-cwi

curl -s https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/eksworkshop-eksctl/;s/{{region_name}}/${AWS_REGION}/" | kubectl delete -f -

# Delete the SNS Topic
aws sns delete-topic \
  --topic-arn arn:aws:sns:${AWS_REGION}:${ACCOUNT_ID}:wordpress-CPU-Alert

# Delete the subscription
aws sns unsubscribe \
  --subscription-arn $(aws sns list-subscriptions | jq -r '.Subscriptions[].SubscriptionArn')

aws iam detach-role-policy \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
  --role-name ${ROLE_NAME}
