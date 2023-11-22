cat << EOF > eksworkshop.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${AWS_REGION}
  version: "1.23"

availabilityZones: ["${AZS[0]}", "${AZS[1]}", "${AZS[2]}"]

vpc:
  cidr: "10.0.0.0/16" # 클러스터에서 사용할 VPC의 CIDR
  nat:
    gateway: HighlyAvailable

managedNodeGroups:
- name: nodegroup
  desiredCapacity: 3
  instanceType: m5.large
  volumeSize: 20  # 클러스터 워커 노드의 EBS 용량 (단위: GiB)
  privateNetworking: true
  iam:
    withAddonPolicies:
      imageBuilder: true # Amazon ECR에 대한 권한 추가
      albIngress: true  # albIngress에 대한 권한 추가
      cloudWatch: true # cloudWatch에 대한 권한 추가
      autoScaler: true # auto scaling에 대한 권한 추가
      ebs: true # EBS CSI Driver에 대한 권한 추가
  ssh:
    enableSsm: true

# To enable all of the control plane logs, uncomment below:
cloudWatch:
  clusterLogging:
    enableTypes: ["*"]
iam:
  withOIDC: true

secretsEncryption:
  keyARN: ${MASTER_ARN}
EOF

eksctl create cluster -f eksworkshop.yaml

cd ~/environment/eksworkshop-custom/020_prerequisites
