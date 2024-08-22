## Cluster Autoscaler (CA)
* Amazon EKS Overview pptx : "EKS 에서 자원 확장"
* 클러스터의 사이즈를 자동으로 조정
  * 리소스가 부족하여 pod가 클러스터에 실행될 수 없을 때
  * 장시간 사용율이 낮은 노드가 있을 경우, 해당 노드의 파드들을 다른 노드로 배치
* CA는 AWS Auto Scaling Group과 연동
    ```
    aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eks-workshop']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
    ```

### Installation
* 클러스터에서 ASG API를 호출할 수 있는 IAM role일 필요 (이미 생성한 상태)
  ```shell
  echo $CLUSTER_AUTOSCALER_ROLE
  ```

* cluster-autoscaler를 위한 IAM Role
  ```
  AUTO_CLUSTER_ROLE_NAME=$(echo $CLUSTER_AUTOSCALER_ROLE | cut -d'/' -f2-)
  
  echo "Attached Policies:"
  aws iam list-attached-role-policies --role-name $AUTO_CLUSTER_ROLE_NAME
  
  echo "Inline Policies:"
  aws iam list-role-policies --role-name $AUTO_CLUSTER_ROLE_NAME
  
  # 연결된 정책의 상세 내용 조회
  for ARN in $(aws iam list-attached-role-policies --role-name $AUTO_CLUSTER_ROLE_NAME --query 'AttachedPolicies[*].PolicyArn' --output text); do
      echo "Policy ARN: $ARN"
      VERSION_ID=$(aws iam get-policy --policy-arn $ARN --query 'Policy.DefaultVersionId' --output text)
      aws iam get-policy-version --policy-arn $ARN --version-id $VERSION_ID
  done
  
  ```
* hlem 차트를 이용한 cluster-autoscaler 설치
  ```shell
  helm repo add autoscaler https://kubernetes.github.io/autoscaler
  helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
    --version "${CLUSTER_AUTOSCALER_CHART_VERSION}" \
    --namespace "kube-system" \
    --set "autoDiscovery.clusterName=${EKS_CLUSTER_NAME}" \
    --set "awsRegion=${AWS_REGION}" \
    --set "image.tag=v${CLUSTER_AUTOSCALER_IMAGE_TAG}" \
    --set "rbac.serviceAccount.name=cluster-autoscaler-sa" \
    --set "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"="$CLUSTER_AUTOSCALER_ROLE" \
    --wait
  
    kubectl get deployment -n kube-system cluster-autoscaler-aws-cluster-autoscaler

  ```

### Scale with CA
* 모든 deployment의 리플리카셋을 4로 증가
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: all
  spec:
    replicas: 4
  
  ```
  ```shell
  kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/cluster-autoscaler

  kubectl get pods -A -o wide --watch
  ```
* 로그 또는 Kube Ops View에서 확인
  ```shell
  
  kubectl -n kube-system logs \
    -f deployment/cluster-autoscaler-aws-cluster-autoscaler
  
  ```

### Cluster Over-Provisioning
* AWS EC2 Auto Scaling Group(ASG)와 연동되기 때문에 노드가 증가하는데 시간이 다소 걸릴 수 있음
* 우선 순위가 낮은 빈 파드를 이용하여 오버프로비저닝
* 빈 파드는 우선순위가 낮으며 중요한 애플리케이션 파드가 배포될 때 제거
* 빈 파드는 CPU 및 메모리 리소스뿐만 아니라 AWS VPC 컨테이너 네트워크 인터페이스(CNI)에서 할당된 IP 주소도 할당

#### PriorityClass
* [PriorityClass](https://kubernetes.io/ko/docs/concepts/scheduling-eviction/pod-priority-preemption/)는 파드의 우선순위를 할당하는 리소스
* `value` : 1 부터 10억 사이의 값
* 값이 클 수록 우선순위가 높음
* 파드 스펙에 `priorityClassName` 기재
* 클러스터의 리소스가 부족할 경우, 우선순위가 낮은 쩌리 파드들이 축출(eviction)됨
* `priorityClassName`이 없는 파드의 경우 0

#### How it works
* 우선순위 값이 -1인 빈 "Pause" 컨테이너 파드를 생성 (cpu, memory가 기재되어야 함)
* priority class를 지정하지 않을 경우, 0
* 신규 워크로드를 추가할 경우, 0인 파드들이 생성이 되면서 기존의 -1인 빈 파드들이 축출됨
* 노드의 생성을 기다리지 않고도 빠르게 전개 가능
* 축출된 더미 파드는 `Pending`상태가 되고, ASG가 연쇄적으로 동작하여 노드도 늘어남

#### Setting up Over-Provisioning
* 기본값 `0`을 가지는 PriorityClass와 `-1`을 가지는 PriorityClass 생성
  ```yaml
  apiVersion: scheduling.k8s.io/v1
  kind: PriorityClass
  metadata:
    name: default
  value: 0
  globalDefault: true
  description: "Default Priority class."
  ---
  apiVersion: scheduling.k8s.io/v1
  kind: PriorityClass
  metadata:
    name: pause-pods
  value: -1
  globalDefault: false
  description: "Priority class used by pause-pods for overprovisioning."
  ```
* PriorityClass 값이 `-1`인 `pause-pods` 배포
* `pause-pods`는 node로 사용중인 m5.large 타입의 메모리를 대부분을 차지하는 6.5Gi로 요청
* `pause-pods`를 2개 배포하여 항상 2개의 node를 여유분으로 운영
  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: pause-pods
    namespace: other
  spec:
    replicas: 2
    selector:
      matchLabels:
        run: pause-pods
    template:
      metadata:
        labels:
          run: pause-pods
      spec:
        priorityClassName: pause-pods
        containers:
          - name: reserve-resources
            image: registry.k8s.io/pause
            resources:
              requests:
                memory: "6.5Gi"
  ```
  ```shell
  kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/setup
  kubectl rollout status -n other deployment/pause-pods --timeout 300s

  kubectl get pods -n other
  kubectl get nodes -l workshop-default=yes
  ```

#### Scaling further
* 전체 deployment의 replicaset을 5로 증가
* 스케쥴될 pod들은 `PriorityClass`값이 `0`이므로 `pause pod`보다 우선권을 가짐
* pod들이 `pause-pods`들을 밀어내고 자리 잡게 됨. 
* `pause-pods` 두 개는 `pending` 상태가 되고, 이 pod들을 위해 연쇄적으로 CA가 발동
* 현재 node의 수가 ASG의 maxsize와 같으면 CA는 동작하지 않음 

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: all
  spec:
    replicas: 5
  ```
  ```shell
  kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/compute/overprovisioning/scale
  kubectl wait --for=condition=Ready --timeout=180s pods -l app.kubernetes.io/created-by=eks-workshop -A
  kubectl get pod -n other -l run=pause-pods
  ```
