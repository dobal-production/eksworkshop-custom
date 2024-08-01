## Cluster 생성
```shell
cd ~/environment

cat << EOF > eks-demo-cluster.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: eks-demo # 생성할 EKS 클러스터명
  region: ${AWS_REGION} # 클러스터를 생성할 리전
  version: "1.27"

vpc:
  cidr: "10.0.0.0/16" # 클러스터에서 사용할 VPC의 CIDR
  nat:
    gateway: HighlyAvailable

managedNodeGroups:
  - name: node-group # 클러스터의 노드 그룹명
    instanceType: m5.large # 클러스터 워커 노드의 인스턴스 타입
    desiredCapacity: 3 # 클러스터 워커 노드의 갯수
    volumeSize: 20  # 클러스터 워커 노드의 EBS 용량 (단위: GiB)
    privateNetworking: true
    iam:
      withAddonPolicies:
        imageBuilder: true # Amazon ECR에 대한 권한 추가
        albIngress: true  # albIngress에 대한 권한 추가
        cloudWatch: true # cloudWatch에 대한 권한 추가
        autoScaler: true # auto scaling에 대한 권한 추가
        ebs: true # EBS CSI Driver에 대한 권한 추가

cloudWatch:
  clusterLogging:
    enableTypes: ["*"]

iam:
  withOIDC: true
EOF
```
```shell
eksctl create cluster -f eks-demo-cluster.yaml
```
```shell
kubectl get nodes
```
### Console Credentials
```shell
kubectl describe configmap -n kube-system aws-auth
```
```yaml
Name:         aws-auth
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Data
====
mapRoles:
----
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::909187496839:role/eksctl-eks-demo-nodegroup-node-gro-NodeInstanceRole-9sO4K9pH9Ens
  username: system:node:{{EC2PrivateDNSName}}

BinaryData
====

Events:  <none>
```
```shell
kubectl edit configmap -n kube-system aws-auth
```
```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::909187496839:role/eksctl-eks-demo-nodegroup-node-gro-NodeInstanceRole-9sO4K9pH9Ens
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::909187496839:role/WSParticipantRole
      username: admin
kind: ConfigMap
metadata:
  creationTimestamp: "2024-07-29T13:40:59Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "1596"
  uid: 67c1751d-fa32-4090-8f19-b3632cc32ed1
```
```shell
kubectl describe configmap -n kube-system aws-auth 
```
## Switch cluster context
```
kubectl config get-contexts
kubectl config rename-context [context_name] [new_context_name]
kubectl config use-context [context_name]
kubectl config delete-context [context_name]
```

### config Error
* /home/ec2-user/.kube/config 파일에 yaml로 저장
* 파일에 오류가 있을 경우 다시 삭제하고 생성해주면 됨.

    ```shell
    rm -rf /home/ec2-user/.kube/config
    aws eks update-kubeconfig --name eks-workshop --region $AWS_REGION
    ```
## Deploying our first component
* [Quiz] Replicas를 늘린 후, 동일한 명령어를 반복해서 실행하면 어떤 변화가 있을까요?