## Horizontal Pod Autoscaler

### Metric Server
* k8s가 자체적으로 pod들의 cpu/memory 등을 지표를 수집하지 않음
* metric server를 먼저 배포해야 함 -> [Metric Server](https://github.com/kubernetes-sigs/metrics-server)
* pod들에 정의된 `requests` 대비 얼마나 리소스를 사용하고 있는지가 기준
* 실습 환경에서는 미리 설치해 둠

    ```shell
    kubectl -n kube-system get pod -l app.kubernetes.io/name=metrics-server
    kubectl top node
    kubectl top pod -l app.kubernetes.io/created-by=eks-workshop -A
    ```
### Configure HorizontalPodAutoscaler(HPA)
* `HorizontalPodAutoscaler`에 스케일링을 위한 조건 정의
    ```yaml
    apiVersion: autoscaling/v1
    kind: HorizontalPodAutoscaler
    metadata:
      name: ui
      namespace: ui
    spec:
      minReplicas: 1
      maxReplicas: 4
      scaleTargetRef:
        apiVersion: apps/v1
        kind: Deployment
        name: ui
      targetCPUUtilizationPercentage: 80
    ```
    ```shell
    kubectl apply -k ~/environment/eks-workshop/modules/autoscaling/workloads/hpa
    ```
### Generate load
* 동시에 10개의 워커 실행
* 매 초마다 5번의 조회 실행
* 최대 60분 동안 실행
    ```shell
    kubectl run load-generator \
      --image=williamyeh/hey:latest \
      --restart=Never -- -c 10 -q 5 -z 60m http://ui.ui.svc/home
    ```
    ```shell
    kubectl get hpa ui -n ui --watch
    ```