## Amazon EKS Auto Mode
<img src="../images/automode-05.png" />
<img src="../images/automode-06.png" />
<img src="../images/automode-07.png" />
<img src="../images/automode-08.png" />
<img src="../images/automode-09.png" />

## Auto Mode 기능들
<b>Kubernetes 클러스터 관리 간소화</b>: EKS Auto Mode는 운영 오버헤드를 최소화.

<b>애플리케이션 가용</b>: 
EKS Auto Mode는 Kubernetes 애플리케이션의 요구 사항에 따라 EKS 클러스터의 노드를 동적으로 추가하거나 제거.

<b>효율성</b>: NodePool 및 워크로드 요구 사항에 정의된 유연성을 준수하면서 비용을 최적화하도록 설계. 
또한 미사용 인스턴스를 종료하고 워크로드를 다른 노드로 통합하여 비용 효율성을 개선.

<b>보안</b>: 사용자가 변경 불가능한 AMI를 사용, 노드의 최대 수명은 21일(단축할 수 있음)이며, 그 후에는 새 노드로 자동 대체.

<b>자동 업그레이드</b>: EKS Auto Mode는 구성된 포드 중단 예산(PDB) 및 NodePool 중단 예산(NDB)을 준수하면서 최신 패치를 사용하여 Kubernetes 클러스터, 노드, 관련 구성 요소를 최신 상태로 유지.

<b>관리형 구성 요소</b>: 파드 IP 주소 할당, 파드 네트워크 정책, 로컬 DNS 서비스, GPU 플러그인, 상태 확인기, EBS CSI 스토리지에 대한 기본 지원.

<b>사용자 지정 가능한 NodePool 및 NodeClasse</b>: 워크로드에서 스토리지, 컴퓨팅 또는 네트워킹 구성을 변경해야 하는 경우 사용자 지정 NodePool 또는 NodeClasse를 추가.

### 주요 링크들
* [EKS Auto Mode를 사용하여 클러스터 인프라 자동화](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/automode.html)
* [Amazon EKS Auto Mode 시작하기](https://aws.amazon.com/ko/blogs/tech/getting-started-with-amazon-eks-auto-mode/)

## Access the cluster
* 두개의 클러스터가 사전에 프로비저닝 되어 있음
* 첫 번째 클러스터는 EKS Auto Mode의 기능 핸즈온 용
* 두 번째 클라스터는 마이그레이션 핸즈온 용


클러스터 확인
```shell
kubectl config get-contexts
```
마이그레이션 클러스터로 스위치
```shell
kubectl config use-context arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/migration-cluster
```
데모 클러스터로 스위치
```shell
kubectl config use-context arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/demo-cluster
```

### 실행중인 파드와 노드 확인
```shell
kubectl get pod --all-namespaces
kubectl get nodes
```