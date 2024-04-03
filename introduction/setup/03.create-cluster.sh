#!/bin/bash

cat << EOF > cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

availabilityZones:
- ${AWS_REGION}a
- ${AWS_REGION}b
- ${AWS_REGION}c

metadata:
  name: ${EKS_CLUSTER_NAME}
  region: ${AWS_REGION}
  version: '1.23'
  tags:
    karpenter.sh/discovery: ${EKS_CLUSTER_NAME}
    created-by: eks-workshop-v2
    env: ${EKS_CLUSTER_NAME}

iam:
  withOIDC: true

vpc:
  cidr: 10.42.0.0/16
  clusterEndpoints:
    privateAccess: true
    publicAccess: true

addons:
- name: vpc-cni
  version: 1.14.1
  configurationValues:  "{\"env\":{\"ENABLE_PREFIX_DELEGATION\":\"true\", \"ENABLE_POD_ENI\":\"true\", \"POD_SECURITY_GROUP_ENFORCING_MODE\":\"standard\"},\"enableNetworkPolicy\": \"true\"}"
  resolveConflicts: overwrite

# https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md
managedNodeGroups:
- name: default
  desiredCapacity: 3
  minSize: 3
  maxSize: 6
  instanceType: m5.large
  privateNetworking: true
  releaseVersion: 1.23.17-20231201
  updateConfig:
    maxUnavailablePercentage: 50
  labels:
    workshop-default: 'yes'
EOF

eksctl create cluster -f cluster.yaml
cd ~/environment/eksworkshop-custom/introduction/setup
