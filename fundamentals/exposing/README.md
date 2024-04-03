## Exposing applications
### 클러스터 내 파드들의 통신
* 동일 호스트에 있는 컨테이너들은 서로 통신 가능
* 다른 노드와의 통신을 위해서는 호스트 IP의 특정 포트를 통해서(proxy) 통신
* 컨테이너가 사용하는 포트를 신중하게 조정하거나 동적으로 할당해야 함
* 클러스터 내의 파드들은 NAT 없이 서로 통신 가능

### Service
* 파드가 업데이트 되거나 새로 생성될 경우 ip도 새로 할당 받음
* 파드들을 논리적으로 묶어서 `Service`로 만들 수 있음
* 파드들을 위한 엔드포인트 생성
  * 외부 로드 밸런서에서 제공되는 IP
  * 클러스터 내부에서만 사용하는 가상 IP(ClusterIP)를 할당
* `Kubernetes`는 `Service`를 찾기 위해 환경변수와 DNS 두 가지 방식을 제공
* 환경변수(Environment Variables)
  * 파드가 실행될 때, `kubelet`은 각 활성 서비스들을 파드의 환경변수로 추가
  * `Service`보다 `Replica`가 먼저 생성될 경우, 파드의 환경변수에는 추가되지 않음
  * 파드를 재패보하면 환경변수에 `Service`가 추가됨
  * catalog 파드의 환경변수 조회
    ```sh
    export catalogpod=$(kubectl get pod -n catalog -l app.kubernetes.io/component=service -o jsonpath='{.items[0].metadata.name}')
    kubectl -n catalog exec ${catalogpod} -- printenv | grep SERVICE
    ```
* DNS
  * `Kubernetes`는 CoreDNS가 서비스로 실행
    ```sh
    kubectl -n catalog run curl --image=radial/busyboxplus:curl -i --tty
    ```
  * 컨테이너 터미널에서 nslookup 실행
    ```
    nslookup catalog
    ```
  * 파드 삭제
    ```
    kubeclt delete po -n catalog curl
    ```

### ClusterIP
* 파드에 접근하기 위해 클러스터 내부에서만 사용되는 ip
* 클러스터 외부로 pod를 노출하지 않음
* 여러 포트를 설정할 수 있음. (예, 8080 → 80, 8443 → 443)
* Immutable한 Static IP를 지정할 수 있음
* Single Point of Failure가 될 수 있음
  ```
  spec:
  type: ClusterIP
  clusterIP : 10.3.1.1
  ports:
  - name: "http-port"
    protocol: "TCP"
    port:8080
    targetPort:80
  ```
### NordPort
* pod에 접근할 수 있는 포트를 클러스터의 모든 노드에 동일하게 개방
* 클러스터 외부에 노출 됨
* 포트 범위 : 30000 ~ 32767
* 접근할 수 있는 포트는 랜덤으로 정해지지만, 특정 포트로 접근하도록 설정할 수도 있음
* 컨테이너 내부 dns에서는 ClusterIP가 사용. default 자동할당, 지정 가능 (서비스 디스커버리)
  ```
  spec:
  type: NodePort
  ports:
  - name: "http-port"
    protocol: "TCP"
    port: 8080      #clusterIP에서 수신할 포트
    targetPort: 80  #목적 컨테이너 포트
    nodePort: 30080 #모든 노드에서 수신할 포트, 지정하지 않으며 자동
  ```

## 실습 개요
* 현재 배포된 애플리케이션은 EKS Cluster 내부에서만 접속이 가능하며, 클러스터 외부에서는 접속할 수 없음  
* 클러스터 외부에서도 접속하기 위해 서비스를 노출해주어야 함  
* EKS에서 서비스를 외부로 노출하는 방식은 두 가지  
    * Ingress를 생성하여 노출할 경우 Application Load Balancer가 생성  
    * Service 타입을 LoadBalancer로 변경할 경우 Network Load Balancer 생성
* Ingress-ALB 방식은 하나의 ALB에 여러 서비스들을 묶어서 배포할 수 있음.
* Service type을 LoadBalancer로 설정하는 방식은 서비스마다 NLB가 생성됨.

### 전제 조건    
* Public Subnet tag에 ```kubernetes.io/role/elb:1``` 필수
* Private Subnet tag에 ```kubernetes.io/role/internal-elb:1``` 필수
* 두 방식 모두 AWS Load Balancer Controller의 설치가 전제되어야 함. 본 교육에서 생성한 클러스터에는 설치된 상태.

## Load Balancers
### Creating the load balancer
```
apiVersion: v1
kind: Service
metadata:
  name: ui-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
  namespace: ui
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
      name: http
  selector:
    app.kubernetes.io/name: ui
    app.kubernetes.io/instance: ui
    app.kubernetes.io/component: service
```

* Service Type을 LoadBalancer로 변경하면 Target이 "instance mode"인 NLB가 생성.
* 트래픽은 타겟에 설정된 포트를 이용하여 인스턴스(워커노드)로 연결되고 ```kube-proxy```는 이 트래픽을 개별 파드로 포워딩
* NL의 타켓은 모든 워커노드 (3개)로 표시되나, 실제 파드는 1개만 배포된 상태
* ```kube-proxy```는 자체 iptable을 참조하여 파드가 있는 노드로 트래픽을 포워딩

```
kubectl get svc -n ui ui-nlb | tail -n 1 | awk '{ print "UI URL = http://"$4 }'
```

### IP mode
![Exposing service](https://www.eksworkshop.com/assets/images/ip-mode-5a2f1be81ebf0ed8c08f825bfb1394c6.png)
* NLB의 Target을 "IP mode"로도 변경 가능하면 트래픽이 개별 파드로 직접 흐르고, 워커노드에서 발생하는 부차적인 네트워크 홉도 제거할 수 있음.

* IP mode의 장점
    * 인바운드 연결을 위한 보다 효율적인 네트워크 경로를 생성하여 EC2 워커 노드에서 kube-proxy를 우회.
    * ```externalTrafficPolicy```와 다양한 구성 옵션의 장단점 같은 측면을 고려할 필요가 없음
    * Amazon EC2와 AWS Fargate 상에서 동작하는 파드에 모두 사용 가능 

## Ingress
* 쿠버네티스 인그레스는 클러스터에서 실행 중인 쿠버네티스 서비스에 대한 외부 또는 내부 HTTP(S) 액세스를 관리할 수 있는 API 리소스
* ALB는 호스트 또는 경로 기반 라우팅, TLS(전송 계층 보안) termination, 웹소켓, HTTP/2, AWS WAF(웹 애플리케이션 방화벽) 통합, 통합 액세스 로그, 상태 확인 등 다양한 기능을 지원

### Creating the ingress  
* Ingress로 생성된 ALB URL 얻기 
    ```sh
    kubectl get ingress -n ui | tail -n 1 | awk '{print "ALB = http://"$4 }'
    ```

### Multiple Ingress pattern
* 여러 Ingress를 하나의 그룹으로 만들어주는 IngressGroup  
* 컨트롤러는 IngressGrup에 있는 모든 Ingress의 규칙들을 합쳐서 하나의 ALB에 통합
* 앞서 만들었던 Ingress를 수정하기 때문에 기존 ALB는 삭제되고, 새로운 ALB가 생성 

```sh
ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-retailappgroup`) == `true`].LoadBalancerArn' | jq -r '.[0]')  
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn')  
aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN

```

