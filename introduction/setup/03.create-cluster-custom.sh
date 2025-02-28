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

iam:
  vpcResourceControllerPolicy: true

addons:
  - name: vpc-cni
    resolveConflicts: overwrite
    version: latest
    useDefaultPodIdentityAssociations: true

  - name: kube-proxy
    resolveConflicts: overwrite
    version: latest
    useDefaultPodIdentityAssociations: true

  - name: aws-ebs-csi-driver
    resolveConflicts: overwrite
    version: latest
    useDefaultPodIdentityAssociations: true

  - name: coredns
    resolveConflicts: overwrite
    version: latest
    useDefaultPodIdentityAssociations: true

  - name: eks-pod-identity-agent
    version: latest

vpc:
  id: vpc-0271daff9ff22a666
  clusterEndpoints:
    privateAccess: true
    publicAccess: true
  subnets:
    private:
      us-east-1a:
        id: "subnet-02ddc199c8d4c9c83"
      us-east-1b:
        id: "subnet-0716549d2ac0e8488"
      us-east-1c:
        id: "subnet-09e80e3c3716988ca"
    public:
      us-east-1a:
        id: "subnet-0bb638b20380c752d"
      us-east-1b:
        id: "subnet-0b359e831d0df6213"
      us-east-1c:
        id: "subnet-081956d3bd77751c4"

# https://github.com/awslabs/amazon-eks-ami/blob/master/CHANGELOG.md
managedNodeGroups:
  - name: default
    desiredCapacity: 3
    minSize: 3
    maxSize: 6
    volumeSize: 30
    instanceType: m5.large
    privateNetworking: true
    releaseVersion: 1.30.9-20250224
    disableIMDSv1: true
    iam:
      withAddonPolicies:
        albIngress: true
        autoScaler: true
        cloudWatch: true
        ebs: true
        awsLoadBalancerController: true

EOF

eksctl create cluster -f cluster.yaml
cd ~/environment/eksworkshop-custom/introduction/setup