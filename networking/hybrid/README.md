# Amazon EKS Hybrid Node

<img src="../../images/hybrid-01.png"/>
<img src="../../images/hybrid-04.jpg"/>

## Lab Overview
<img src="../../images/hybrid-02.png"/>

## Connect Hybrid Node
* 온프레미스 노드에 AWS SSM hybrid activation 또는 AWS IAM Role Anywhere를 활성화 해야 함.
* 실습에서는 SSM hybrid activation 사용
* 최소 100 Mbps, 최대 200ms 네트워크 레이턴시
* hybrid 노드 설치와 업그레이드를 위해 접근을 허용해야 하는 도메인  

  |    Component    | URL                      | Protocal | Port |
  |-----------------|--------------------------|----------|------|
  | EKS node artifacts (S3)        | https://hybrid-assets.eks.amazonaws.com    | HTTPS | 443 |
  | EKS service endpoints          | https://eks.region.amazonaws.com           | HTTPS | 443 |
  | ECR service endpoints          | https://api.ecr.region.amazonaws.com       | HTTPS | 443 |
  | EKS ECR endpoints              | [Amazon container image registries for Amazon EKS add-ons](https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html) for regional endpoints.        | HTTPS | 443 |
  | SSM binary endpoint            | https://amazon-ssm-region.s3.region.amazonaws.com        | HTTPS | 443 |
  | SSM service endpoints          | https://ssm.region.amazonaws.com           | HTTPS | 443 |
  | EKS service endpoints          | https://eks.region.amazonaws.com           | HTTPS | 443 |
  | IAM Anywhere binary endpoint   | https://rolesanywhere.amazonaws.com        | HTTPS | 443 |
  | IAM Anywhere service endpoint  | https://rolesanywhere.region.amazonaws.com | HTTPS | 443 |
* hybrid 노드 운영을 위한 네트워크 Inbound/Outbound 액세스  
  <img src="../../images/hybrid-05.png" />


### Hybrid 노드에서 사용할 IAM role에 필요한 권한들
* **하이브리드 노드 CLI(nodeadm) 권한:**
  * eks:DescribeCluster 액션 필요
  * 클러스터 정보 수집에 사용
  * 이 권한이 없는 경우, nodeadm init 실행 시 수동으로 다음 정보를 제공해야 함:
    * Kubernetes API 엔드포인트
    * 클러스터 CA 번들
    * 서비스 IPv4 CIDR
* **kubelet 권한:**
  * Amazon ECR 접근을 위한 AmazonEC2ContainerRegistryPullOnly 권한 필요
  * 컨테이너 이미지 가져오기 용도
* **Systems Manager 사용 시 추가 권한:**
  * AmazonSSMManagedInstanceCore 정책에 정의된 하이브리드 활성화 권한
  * ssm:DeregisterManagedInstance 액션 권한
  * ssm:DescribeInstanceInformation 액션 권한
  * nodeadm uninstall 시 인스턴스 등록 해제에 필요

### Amazon EKS Hybrid Nodes CLI(`nodeadm`) 설치
* **`nodeadm` 다운로드**
  > x86_64
  ```shell
  curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm'
  ```
  > ARM
  ```shell
  curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/arm64/nodeadm'
  ```
* **`nodeadm`에 실행권한 필요**
  * `chmod +x nodeadm`
  * `nodeadm`은 root 권한으로 실행해야 함
* **Amazon EKS 클러스터 조인을 위한 아티팩트 및 종속성 설치**
  ```shell
  nodeadm install 1.32 --credential-provider ssm
  ```
* **Amazon EKS 클러스터 조인**
  ```shell
  nodeadm init -c file://nodeConfig.yaml
  ```

### Lab : Connect Hybrid Node
```shell
export ACTIVATION_JSON=$(aws ssm create-activation \
--default-instance-name hybrid-ssm-node \
--iam-role $HYBRID_ROLE_NAME \
--registration-limit 1 \
--region $AWS_REGION)
export ACTIVATION_ID=$(echo $ACTIVATION_JSON | jq -r ".ActivationId")
export ACTIVATION_CODE=$(echo $ACTIVATION_JSON | jq -r ".ActivationCode")

```
```yaml
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: $EKS_CLUSTER_NAME
    region: $AWS_REGION
  hybrid:
    ssm:
      activationCode: $ACTIVATION_CODE
      activationId: $ACTIVATION_ID
```

**환경변수를 nodeconfig.yaml 파일에 입력**
```shell
cat ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/nodeconfig.yaml \
| envsubst > nodeconfig.yaml
```

**hybrid 대상 인스턴스에 nodeconfig 파일 업로드**
```shell
mkdir -p ~/.ssh/
ssh-keyscan -H $HYBRID_NODE_IP &> ~/.ssh/known_hosts
scp -i private-key.pem nodeconfig.yaml ubuntu@$HYBRID_NODE_IP:/home/ubuntu/nodeconfig.yaml
```

**`nodeadm`을 이용하여 Hybrid Nodes 관련 파일들 설치 (몇 분이 소요됨)**
```shell
ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm install $EKS_CLUSTER_VERSION --credential-provider ssm"
```

**앞서 업로드한 nodeconfig 파일로 초기화**
```shell
ssh -i private-key.pem ubuntu@$HYBRID_NODE_IP \
"sudo nodeadm init -c file://nodeconfig.yaml"
```

**Node 연결 확인, 그러나 노드는 `NotReady` 상태**
```shell
kubectl get nodes
```
```shell
NAME                                          STATUS     ROLES    AGE   VERSION
ip-10-42-126-192.us-west-2.compute.internal   Ready      <none>   91m   v1.31.3-eks-59bf375
ip-10-42-136-243.us-west-2.compute.internal   Ready      <none>   91m   v1.31.3-eks-59bf375
ip-10-42-177-246.us-west-2.compute.internal   Ready      <none>   91m   v1.31.3-eks-59bf375
mi-0e9b2a38f2998f783                          NotReady   <none>   19s   v1.31.7-eks-473151a
```

### cilium란?
* Cilium은 Kubernetes 클러스터를 위한 오픈소스 소프트웨어로, Linux 커널의 eBPF(extended Berkeley Packet Filter) 기술을 기반으로 하는 고성능 네트워킹, 보안 및 관찰 가능성 솔루션입니다.

### cilium을 사용하는 이유
1. **고급 네트워킹 기능**   
    * 고성능 Pod 간 통신: eBPF 기술을 활용하여 커널 수준에서 최적화된 네트워킹 제공
    * kube-proxy 대체: 기존 kube-proxy보다 효율적인 서비스 로드 밸런싱 제공
    * 멀티 클러스터 지원: 여러 클러스터 간의 원활한 네트워킹 가능
2. **강력한 보안 기능**
    * L3-L7 네트워크 정책: IP/포트 기반(L3/L4)뿐만 아니라 API 호출과 같은 애플리케이션 레이어(L7) 수준의 정책 지원
    * 신원 기반 보안: 서비스 간 통신을 IP 주소가 아닌 서비스 신원을 기반으로 제어
    * 투명한 암호화: Pod 간 통신의 자동 암호화를 통한 보안성 강화
3. **관찰 가능성(Observability)**
    * 네트워크 트래픽 가시화: 서비스 간 통신 흐름을 실시간으로 모니터링하고 시각화
    * 문제 해결 용이성: 네트워크 연결 문제를 빠르게 식별하고 해결
    * 성능 모니터링: 네트워크 성능 지표 제공
4. **클라우드 네이티브 환경 최적화**
    * EKS와 같은 관리형 쿠버네티스 서비스와의 통합: 클라우드 제공업체의 VPC와 원활하게 통합
    * 확장성: 대규모 클러스터에서도 효율적인 성능 제공
    * 자동화: 동적 환경에서 자동 구성 지원
5. **eBPF 기술의 이점**
    * 커널 수준 실행: 추가 컨테이너나 사이드카 없이 커널 수준에서 동작하여 오버헤드 최소화
    * 유연성: 커널 업그레이드 없이 네트워킹 스택 기능 확장 가능
    * 성능: 전통적인 네트워킹 솔루션보다 높은 처리량과 낮은 지연 시간

**cilium 애드온설치**
```shell
helm repo add cilium https://helm.cilium.io/
```
```shell
helm install cilium cilium/cilium \
--version 1.17.1 \
--namespace cilium \
--create-namespace \
--values ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/cilium-values.yaml
```

**cilium-values.yaml**
```yaml
# Cilum 파드가 배포될 노드를 지정
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/compute-type
          operator: In
          values:
          - hybrid
# IP 주소관리(IPAM) 설정
ipam:
  mode: cluster-pool #Cilium이 클러스터 전체 IP 풀을 사용하여 IP 주소를 할당
  operator:
    clusterPoolIPv4MaskSize: 25 # 각 노드에 할당되는 서브넷 마스크 크기
    clusterPoolIPv4PodCIDRList: # 파드에 할당되는 IP 주소의 범위를 10.53.0.0/16으로 지정
    - 10.53.0.0/16
operator:
  replicas: 1 # We only have 1 node in this lab, 2 is the default
  affinity:
    nodeAffinity: # 오퍼레이터도 hybrid 타입 노드에만 스케줄링
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: eks.amazonaws.com/compute-type
            operator: In
            values:
              - hybrid
  unmanagedPodWatcher: # 관리되지 않는 파드가 발견될 때 해당 파드를 재시작하지 않도록 설정
    restart: false
envoy:
  enabled: false

```

**cilium 설치 후, hybrid node는 `Ready` 상태가 됨**
```shell
kubectl get nodes

NAME                                          STATUS   ROLES    AGE     VERSION
ip-10-42-126-192.us-west-2.compute.internal   Ready    <none>   9h      v1.31.3-eks-59bf375
ip-10-42-136-243.us-west-2.compute.internal   Ready    <none>   9h      v1.31.3-eks-59bf375
ip-10-42-177-246.us-west-2.compute.internal   Ready    <none>   9h      v1.31.3-eks-59bf375
mi-0e9b2a38f2998f783                          Ready    <none>   7h53m   v1.31.7-eks-473151a
```

## Routing Traffic to Hybrid Nodes
**Sample workload 배포**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: nginx-remote
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 1
              preference:
                matchExpressions:
                  - key: eks.amazonaws.com/compute-type
                    operator: In
                    values:
                      - hybrid
      containers:
        - name: nginx
          image: public.ecr.aws/nginx/nginx:1.26
          volumeMounts:
            - name: workdir
              mountPath: /usr/share/nginx/html
          resources:
            requests:
              cpu: 200m
            limits:
              cpu: 200m
          ports:
            - containerPort: 80
      initContainers:
        - name: install
          image: busybox:1.28
          command: [ "sh", "-c"]
          args:
            - 'echo "Connected to $(POD_IP) on $(NODE_NAME)" > /work-dir/index.html'
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          volumeMounts:
            - name: workdir
              mountPath: "/work-dir"
      volumes:
        - name: workdir
          emptyDir: {}
  ```
  
  >**Hybrid 노드에 배포되도록 지정**  
  > `eks.amazonaws.com/compute-type=hybrid` 레이블/값 지정
```yaml
nodeAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
          - key: eks.amazonaws.com/compute-type
            operator: In
            values:
              - hybrid
```
```yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
  namespace: nginx-remote
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80
```
```shell
kubectl apply -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize
```
> **파드 확인**
```shell
kubectl get pods -n nginx-remote -o=custom-columns='NAME:.metadata.name,NODE:.spec.nodeName'
```
```shell
NAME                     NODE
nginx-787d665f9b-fr2g6   mi-0e9b2a38f2998f783
nginx-787d665f9b-r9fx7   mi-0e9b2a38f2998f783
nginx-787d665f9b-x882v   mi-0e9b2a38f2998f783
```

**배포된 ALB 확인**
```shell
export ADDRESS=$(kubectl get ingress -n nginx-remote nginx -o jsonpath="{.status.loadBalancer.ingress[*].hostname}{'\n'}") && echo $ADDRESS
curl -s $ADDRESS
```

**리소스 정리**
```shell
kubectl delete -k ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kustomize --ignore-not-found=true
```

## Cloud Bursting
* `preferredDuringSchedulingIgnoredDuringExecution` 설정은 새로운 파드가 스캐쥴링 될 때는 hybrid 노드를 선호하도록 설정하지만, hybrid 노드에 더 이상 파드가 들어갈 공간이 없을 경우, 다른 노드를 사용할 수 있도록 허용
* 그런데, `IgnoredDuringExecution` 부분으로 인해 기존 실행중인 파드는 이 영향을 받지 않음
  * 파드가 scale-in 될 경우, 쿠버네티스는 가장 오래된 파드 먼저 삭제하려고 시도함.
  * hybrid 노드에 먼저 배포되므로, scale-in시 hybrid 노드에 있는 파드가 우선적으로 삭제될 것 --> 우리가 원치 않는 상황

### Kyverno
<img src="../../images/hybrid-03.png" />

* 쿠버네티스와 클라우드 네이티브 환경을 위한 정책관리 도구
* yaml기반 선언적 정책 (Policy as Code, PaC)
* 쿠버네티스 네이티브 리소스로 관리
* kubectl, git, kustomize 등 기존 도구 활용 가능
* JMESPath와 CEL(Common Expressions Language) 지원
* **핵심기능**
  * 쿠버네티스 리소스 검증, 변경, 생성, 정리
  * OCI(Open Container Initiative) 컨테이너 이미지 서명 및 아티팩트 검증
* **도구 및 확장**
  * CLI : 오프라인 정책 테스트 및 적용(IaC, CI/CD 파이프라인)
  * Policy Reporter : 웹기반 GUI로 보고서 관리
  * JSON 지원 : K8S 외 환경에서도 정책 적용 가능

**`Kyverno` 설치**
```shell
helm repo add kyverno https://kyverno.github.io/kyverno/
helm install kyverno kyverno/kyverno --version 3.3.7 -n kyverno --create-namespace -f ~/environment/eks-workshop/modules/networking/eks-hybrid-nodes/kyverno/values.yaml
```

**클러스터 정책추가**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: set-pod-deletion-cost
  annotations:
    policies.kyverno.io/title: Set Pod Deletion Cost
    policies.kyverno.io/category: Pod Management
    policies.kyverno.io/severity: medium
    policies.kyverno.io/description: >-
      Sets pod-deletion-cost label on nginx pods scheduled to hybrid compute nodes.
spec:
  rules:
    - name: set-deletion-cost-for-nginx-on-hybrid
      match:
        any:
          - resources:
              kinds:
                - Pod/binding
      context:
        - name: node
          variable:
            jmesPath: request.object.target.name
            default: ""
        - name: computeType
          apiCall:
            urlPath: "/api/v1/nodes/{{node}}"
            jmesPath: metadata.labels."eks.amazonaws.com/compute-type" || 'empty'
      preconditions:
        all:
          - key: "{{ computeType }}"
            operator: Equals
            value: hybrid
      mutate:
        targets:
          - apiVersion: v1
            kind: Pod
            name: "{{ request.object.metadata.name }}"
            namespace: "{{ request.object.metadata.namespace }}"
        patchStrategicMerge:
          metadata:
            annotations:
              controller.kubernetes.io/pod-deletion-cost: "1"
```

**A. pod 바인딩 이벤트에만 적용**
```yaml
match:
  any:
    - resources:
        kinds:
          - Pod/binding
```

**B. 노드 이름과 `compute-type` 라벨 값을 변수 처리**
> `node`, `computType` 변수에 값 할당  
> `computType`은 api 호출을 통해 노드의 `compute-type`을 가져온다.
```yaml
context:
  - name: node
    variable:
      jmesPath: request.object.target.name
      default: ""
  - name: computeType
    apiCall:
      urlPath: "/api/v1/nodes/{{node}}"
      jmesPath: metadata.labels."eks.amazonaws.com/compute-type" || 'empty'

```

**C.조건**
> `compute-type=hybrid`인 경우에만 적용
```yaml
preconditions:
  all:
    - key: "{{ computeType }}"
      operator: Equals
      value: hybrid
```
**D. 변경규칙**
> 대상 파드에 `pod-deletion-code=1` 어노테이션 추가 
> 파드의 삭제 우선순위를 조정하여 높은 값을 가진 파드가 나중에 삭제되도록 설정
```yaml
mutate:
  targets:
    - apiVersion: v1
      kind: Pod
      name: "{{ request.object.metadata.name }}"
      namespace: "{{ request.object.metadata.namespace }}"
  patchStrategicMerge:
    metadata:
      annotations:
        controller.kubernetes.io/pod-deletion-cost: "1"

```

### `pod-deletion-cost`
* 값의 범위 : 정수 값, 음수/양수 설정 가능, 
* 설정되지 않으면 `0`
* 높은 값을 가진 파드가 더 나중에 삭제됨
* 같은 값을 가진 파드들 사이에서는 임의로 선택됨
* `ReplicaSet` 컨트롤러가 파드를 삭제할 때 이 값을 참고
