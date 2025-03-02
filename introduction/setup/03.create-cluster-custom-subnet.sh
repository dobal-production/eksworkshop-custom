#!/bin/bash

cat << EOF > cluster.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${EKS_CLUSTER_NAME}
  region: ${AWS_REGION}
  version: '1.30'
  tags:
    created-by: Dobal
    env: ${EKS_CLUSTER_NAME}

addons:
  - name: vpc-cni
    version: latest
    attachPolicyARNs:
      - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
  - name: coredns
    version: latest
  - name: kube-proxy
    version: latest

vpc:
  id: vpc-09f7a94549a89b6c9
  subnets:
    private:
      private-a:
        id: "YOUR PRIVATE SUBNET 1 ID"
      private-b:
        id: "YOUR PRIVATE SUBNET 2 ID"
      private-c:
        id: "YOUR PRIVATE SUBNET 3 ID"
    public:
      public-a:
        id: "YOUR PUBLIC SUBNET 1 ID"
      public-b:
        id: "YOUR PUBLIC SUBNET 2 ID"
      public-c:
        id: "YOUR PUBLIC SUBNET 3 ID"
  clusterEndpoints:
    privateAccess: true
    publicAccess: true

# https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md
managedNodeGroups:
  - name: default
    desiredCapacity: 3
    minSize: 3
    maxSize: 6
    volumeSize: 30
    instanceType: m5.large
    privateNetworking: true
    releaseVersion: 1.30.9-20250228
    subnets:
      - "YOUR PRIVATE SUBNET 1 ID"
      - "YOUR PRIVATE SUBNET 2 ID"
      - "YOUR PRIVATE SUBNET 3 ID"
    updateConfig:
      maxUnavailablePercentage: 50

iam:
  withOIDC: true
EOF

eksctl create cluster -f cluster.yaml