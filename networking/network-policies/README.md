## Network Policies

### Lab Setup
* 샘플 프로젝트 내의 모든 콤포넌트들은 서로 통신이 가능

### Implementing Egress Controls
* namespace가 지정되지 않으면 클러스터내 모든 네임스페이스에서 일반 정책으로 적용할 수 있음

```shell
# application pod는 app.kubernetes.io/component: service 레이블이 있음
# database pod는 없음
kubectl describe pod -n catalog
kubectl describe pod -n orders
```

### Debugging
* Amazon VPC CNI는 네트워크 정책 적용시 문제를 디버깅할 수 있는 로그를 제공
* CloudWatch와 같은 서비스에서 로그를 모니터 쌉가능

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  namespace: orders
  name: allow-orders-ingress-webservice
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: orders
      app.kubernetes.io/component: service
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app.kubernetes.io/name: ui
```
* podSelector만 정의할 경우, namespace는 NetwprkPolicy의 namespace(여기서는 orders)가 적용됨
* 따라서 ui에서 orders 에는 여전히 접속할 수 없음
* namespace를 추가해야 접속 가능

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  namespace: orders
  name: allow-orders-ingress-webservice
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: orders
      app.kubernetes.io/component: service
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ui
          podSelector:
            matchLabels:
              app.kubernetes.io/name: ui
```




kubectl exec deployment/catalog -n catalog -- curl -v orders.orders/orders --connect-timeout 5



argocd app create commerce --repo $GITOPS_REPO_URL_ARGOCD \
--path commerce --dest-server https://kubernetes.default.svc

