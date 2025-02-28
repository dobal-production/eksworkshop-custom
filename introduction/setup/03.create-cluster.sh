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
  version: '1.31'
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
  version: 1.19.2
  attachPolicyARNs:
    - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
  resolveConflicts: overwrite

# https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md
managedNodeGroups:
- name: default
  desiredCapacity: 3
  minSize: 3
  maxSize: 6
  instanceType: m5.large
  privateNetworking: true
  releaseVersion: 1.31.5-20250224
  updateConfig:
    maxUnavailablePercentage: 50
  labels:
    workshop-default: 'yes'
EOF

eksctl create cluster -f cluster.yaml
cd ~/environment/eksworkshop-custom/introduction/setup
