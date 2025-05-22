## ALB용 IngressClass
* `Ingress`는 서로 다른 컨트롤러로 구현될 수 있음. 
* `IngressClass`에는 컨트롤러 이름과 추가 구성 포함.
* `IngressClassParams` 인증서, 서브넷, 그룹 등을 정의.

## IngressClassParams
| 필드 | 설명 | 예제 값 |
|------|------|---------|
| `scheme` | ALB가 내부인지 인터넷 연결인지를 정의 | `internet-facing` |
| `namespaceSelector` | 이 IngressClass를 사용할 수 있는 네임스페이스 제한 | `environment: prod` |
| `group.name` | 여러 수신을 그룹화하여 단일 ALB 공유 | `retail-apps` |
| `ipAddressType` | ALB의 IP 주소 유형 설정 | `dualstack` |
| `subnets.ids` | ALB 배포를 위한 서브넷 ID 목록 | `subnet-xxxx, subnet-yyyy` |
| `subnets.tags` | 필터에 태그를 지정하여 ALB의 서브넷 선택 | `Environment: prod` |
| `certificateARNs` | 사용할 SSL 인증서의 ARN | `arn:aws:acm:region:account:certificate/id` |
| `tags` | AWS 리소스에 대한 사용자 지정 태그 | `Environment: prod, Team: platform` |
| `loadBalancerAttributes` | 로드 밸런서별 속성 | `idle_timeout.timeout_seconds: 60` |

### IngressClass, IngressClassParams 생성

    ```shell
    cat << EOF >~/environment/ingress.yaml
    apiVersion: eks.amazonaws.com/v1
    kind: IngressClassParams
    metadata:
      name: eks-auto-alb
    spec:
      scheme: internet-facing
    ---
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      name: eks-auto-alb
      annotations:
        ingressclass.kubernetes.io/is-default-class: "true"
    spec:
      controller: eks.amazonaws.com/alb
      parameters:
        apiGroup: eks.amazonaws.com
        kind: IngressClassParams
        name: eks-auto-alb
    EOF
    
    kubectl apply -f ~/environment/ingress.yaml
    ```
    ```shell
    kubectl get ingressclass,ingressclassparams
    ```

### Retail Store UI 콤포넌트 재배포

```shell
helm upgrade -i retail-store-app-ui oci://public.ecr.aws/aws-containers/retail-store-sample-ui-chart \
  --version ${RETAIL_STORE_APP_HELM_CHART_VERSION} --hide-notes -f - << EOF
endpoints:
  catalog: http://retail-store-app-catalog.default:80
  carts: http://retail-store-app-carts.default:80
  checkout: http://retail-store-app-checkout.default:80
  orders: http://retail-store-app-orders.default:80
  assets: http://retail-store-app-assets.default:80

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

topologySpreadConstraints:

   - maxSkew: 1
     minDomains: 3
     topologyKey: topology.kubernetes.io/zone
     whenUnsatisfiable: DoNotSchedule
     labelSelector:
       matchLabels:
         app.kubernetes.io/name: ui

ingress:
  enabled: true
  className: eks-auto-alb
  annotations:
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    alb.ingress.kubernetes.io/success-codes: '200-399'
EOF
```

### ALB로 접속하기

```shell
export ALB_URL=$(kubectl get ingress retail-store-app-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Your application is available at: http://${ALB_URL}"
```

### NLB를 이용하여 Calalog Service를 노출하기
```shell
kubectl apply -f - << EOF
apiVersion: v1
kind: Service
metadata:
  name: catalog-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
  selector:
    app.kubernetes.io/name: catalog
EOF
```
```shell
export NLB_URL=$(kubectl get service catalog-nlb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "The catalog service is also available at: http://${NLB_URL}"
```

### 로드밸런서 테스트
* 터미널을 추가로 열고 로그 출력
 
    ```shell
    kubectl logs -f -l app.kubernetes.io/name=catalog,app.kubernetes.io/component=service --prefix=true
    ```

* 기존 터미널에서 로드밸런서 URL 호출

    ```shell
    # Get the ALB URL
    export ALB_URL=$(kubectl get ingress retail-store-app-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    echo "The application is available at: http://${ALB_URL}"
    
    # Generate traffic to see load balancing across pods
    CURL_CMD=$(which curl)
    for i in {1..15}; do
      echo "Sending request $i..."
      $CURL_CMD -s "http://${ALB_URL}/catalog?request=$i" > /dev/null
      sleep 2
    done
    ```

* 다음과 같이 로그가 나오는지 확인
    ```
    [pod/retail-store-app-catalog-7568d4cffb-bk4g4/catalog] [GIN] 2025/05/22 - 14:19:55 | 200 |    2.766329ms | 192.168.135.168 | GET      "/catalogue/size?tags="
    [pod/retail-store-app-catalog-7568d4cffb-bk4g4/catalog] [GIN] 2025/05/22 - 14:19:57 | 200 |     977.261µs | 192.168.135.168 | GET      "/catalogue/tags"
    [pod/retail-store-app-catalog-7568d4cffb-l9tzh/catalog] [GIN] 2025/05/22 - 14:19:57 | 200 |    1.291117ms | 192.168.135.168 | GET      "/catalogue?tags=&order=&page=1&size=3"
    [pod/retail-store-app-catalog-7568d4cffb-gtkf4/catalog] [GIN] 2025/05/22 - 14:19:57 | 200 |    2.408308ms | 192.168.135.168 | GET      "/catalogue/size?tags="
    [pod/retail-store-app-catalog-7568d4cffb-bk4g4/catalog] [GIN] 2025/05/22 - 14:19:59 | 200 |    1.004472ms | 192.168.135.168 | GET      "/catalogue/tags"
    [pod/retail-store-app-catalog-7568d4cffb-l9tzh/catalog] [GIN] 2025/05/22 - 14:19:59 | 200 |    1.591724ms | 192.168.135.168 | GET      "/catalogue?tags=&order=&page=1&size=3"
    [pod/retail-store-app-catalog-7568d4cffb-gtkf4/catalog] [GIN] 2025/05/22 - 14:19:59 | 200 |    2.203745ms | 192.168.135.168 | GET      "/catalogue/size?tags="
    ```
### 하나의 ALB에 여러 서비스 연결하기
* EKS Auto Mode는 `IngressClassParams`에서 인그레스 그룹 설정 가능
* 실습에서는 UI와 Catalog 서비스의 인그레스를 하나로 그룹핑하여 ALB를 공유
* `IngressClass`, `IngressClassParams` 생성

    ```shell
    cat << EOF >~/environment/ingress-class-group.yaml
    apiVersion: eks.amazonaws.com/v1
    kind: IngressClassParams
    metadata:
      name: eks-auto-alb-group-retail
    spec:
      scheme: internet-facing
      group:
        name: retail
    ---
    apiVersion: networking.k8s.io/v1
    kind: IngressClass
    metadata:
      name: eks-auto-alb-group-retail
      annotations:
        ingressclass.kubernetes.io/is-default-class: "true"
    spec:
      controller: eks.amazonaws.com/alb
      parameters:
        apiGroup: eks.amazonaws.com
        kind: IngressClassParams
        name: eks-auto-alb-group-retail
    EOF
    
    kubectl apply -f ~/environment/ingress-class-group.yaml
    ```

* UI와 Catalog의 Ingress 생성

    ```shell
    kubectl apply -f - << EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: retail-store-shared-group-ui
      annotations:
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/liveness
    spec:
      ingressClassName: eks-auto-alb-group-retail
      rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: retail-store-app-ui
                    port:
                      number: 80
    EOF
    
    kubectl apply -f - << EOF
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: retail-store-shared-group-catalog
      annotations:
        alb.ingress.kubernetes.io/target-type: ip
        alb.ingress.kubernetes.io/healthcheck-path: /health
    spec:
      ingressClassName: eks-auto-alb-group-retail
      rules:
      - http:
          paths:
          - path: /catalogue
            pathType: Prefix
            backend:
              service:
                name: retail-store-app-catalog
                port:
                  number: 80
    EOF
    ```

* `Ingress` 확인

    ```shell
    kubectl get ingress
    ```

* ALB로 접속하기

    ```shell
    # Get the shared ALB URL
    export SHARED_ALB_URL=$(kubectl get ingress retail-store-shared-group-ui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    echo "The shared ALB is available at: http://$SHARED_ALB_URL"
    ```
    
    ```shell
    # Test each shared service endpoint
    echo "Testing / endpoint accessing the ui component..."
    curl -s "http://$SHARED_ALB_URL/"
    ```
    
    ```shell
    echo "Testing /catalog endpoint accessing the catalog component..."
    curl -s "http://$SHARED_ALB_URL/catalogue" | jq
    ```