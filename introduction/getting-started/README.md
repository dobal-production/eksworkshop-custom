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
  version: "1.31"

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
  rolearn: arn:aws:iam::[ACCOUNT_ID]:role/eksctl-eks-demo-nodegroup-node-gro-NodeInstanceRole-9sO4K9pH9Ens
  username: system:node:{{EC2PrivateDNSName}}

BinaryData
====

Events:  <none>
```
```shell
rolearn=$(aws cloud9 describe-environment-memberships --environment-id=$C9_PID | jq -r '.memberships[].userArn')

echo ${rolearn}
```
위 실행 결과에서 assumed-role이라는 문자열이 있다면 아래 추가 실행
```shell
assumedrolename=$(echo ${rolearn} | awk -F/ '{print $(NF-1)}')
rolearn=$(aws iam get-role --role-name ${assumedrolename} --query Role.Arn --output text) 
```
Identity 매핑
```shell
eksctl create iamidentitymapping --cluster eks-demo --arn ${rolearn} --group system:masters --username admin
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
### Scaling (명령형)
```shell
kubectl scale -n catalog --replicas=3 deployment/catalog
```
```shell
kubectl get pod -n catalog
```

### Scaling (선언형)
* base-application/catalog/deployment.yaml의 replicas를 아래와 같이 수정 후 저장
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: catalog
    labels:
      app.kubernetes.io/created-by: eks-workshop
      app.kubernetes.io/type: app
  spec:
    replicas: 3
  ```
* 적용
  ```shell
  kubectl apply -k ~/environment/eks-workshop/base-application/catalog
  ```
  ```shell
  kubectl get pod -n catalog
  ```
* [Quiz] Replicas를 늘린 후, 동일한 명령어를 반복해서 실행하면 어떤 변화가 있을까요?

## Other components
```shell
kubectl apply -k ~/environment/eks-workshop/base-application

kubectl wait --for=condition=Ready --timeout=180s pods \
  -l app.kubernetes.io/created-by=eks-workshop -A
```
```shell
kubectl get namespaces -l app.kubernetes.io/created-by=eks-workshop
```
