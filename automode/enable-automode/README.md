# Enable EKS Auto Mode

## Update the cluster IAM Role
* EKS Auto Mode를 위해 필요한 정책들  
    * AmazonEKSComputePolicy
    * AmazonEKSBlockStoragePolicy
    * AmazonEKSLoadBalancingPolicy
    * AmazonEKSNetworkingPolicy
    * AmazonEKSClusterPolicy

* 기존 클러스터용 IAM Role에 아래의 정책을 추가해야 함.
```shell
AmazonEKSComputePolicy 
AmazonEKSBlockStoragePolicy 
AmazonEKSNetworkingPolicy 
AmazonEKSLoadBalancingPolicy 
```
* CLI 명령어를 이용하여 추가
```shell
for POLICY in \
  "arn:aws:iam::aws:policy/AmazonEKSComputePolicy" \
  "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy" \
  "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy" \
  "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy" \
  "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
do
  echo "Attaching policy ${POLICY} to IAM role ${DEMO_CLUSTER_ROLE_NAME}..."
  aws iam attach-role-policy --role-name ${DEMO_CLUSTER_ROLE_NAME} --policy-arn ${POLICY}
done
```
* 클러스터용 IAM Role의 신뢰정책 수정
```shell
aws iam update-assume-role-policy --role-name $DEMO_CLUSTER_ROLE_NAME --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }
  ]
}'
```

    ```json
    # before
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "eks.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    
    # after
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "eks.amazonaws.com"
                },
                "Action": [
                    "sts:AssumeRole",
                    "sts:TagSession"
                ]
            }
        ]
    }
    ```
* 참고 : https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/auto-cluster-iam-role.html
    
* IAM Role이 제대로 업데이트 되었는지 확인  

    ```shell
    aws iam get-role --role-name ${DEMO_CLUSTER_ROLE_NAME} | \
      jq -r '.Role.AssumeRolePolicyDocument.Statement[].Action[]'
    
    aws iam list-attached-role-policies --role-name ${DEMO_CLUSTER_ROLE_NAME} | \
      jq -r '.AttachedPolicies[].PolicyName'
    ```
    
    
    ```shell
    sts:AssumeRole
    sts:TagSession
    AmazonEKSClusterPolicy
    AmazonEKSNetworkingPolicy
    AmazonEKSComputePolicy
    AmazonEKSBlockStoragePolicy
    AmazonEKSLoadBalancingPolicy
    ```

## Enable EKS Auto Mode
* AWS CLI를 이용하는 방법
```shell 
aws eks update-cluster-config \
    --name ${DEMO_CLUSTER_NAME} \
    --compute-config enabled=true,nodeRoleArn=${DEMO_CLUSTER_NODE_ROLE_ARN},nodePools=system,general-purpose \
    --kubernetes-network-config '{"elasticLoadBalancing":{"enabled": true}}' \
    --storage-config '{"blockStorage":{"enabled": true}}'
```

* Console을 이용하는 방법
<img src="../../images/automode-01.png" /> 
<img src="../../images/automode-02.png" />

* 클러스터 업데이트 확인
* EKS Auto Mode 활성화로 생성된 CRD 확인

<img src="../../images/automode-03.png" />

```shell
kubectl get crd | grep eks.amazonaws.com
```

```
cninodes.eks.amazonaws.com                   2025-01-22T12:25:06Z
ingressclassparams.eks.amazonaws.com         2025-01-22T12:25:02Z
nodeclasses.eks.amazonaws.com                2025-01-22T12:25:02Z
nodediagnostics.eks.amazonaws.com            2025-01-22T12:25:02Z
targetgroupbindings.eks.amazonaws.com        2025-01-22T12:25:02Z
```