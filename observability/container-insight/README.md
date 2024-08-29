## Container Insights on EKS
* Container Insight는 Amazon ECS (Fargate 포함), Amazon EKS, K8s on EC2
* CPU, memory, disk, network 지표 대상
* 문제를 격리하고 신속하게 해결할 수 있도록 컨테이너 재시작 실패와 같은 진단 정보를 제공
* CloudWatch 알람 설정 가능
* 지표를 수집하기 위해 AWS Distro for OpenTelemetry collector (ADOT) 설치

### Cluster metrics
```shell
kubectl apply -k ~/environment/eks-workshop/modules/observability/container-insights/adot && sleep 5
kubectl rollout status -n other daemonset/adot-container-ci-collector --timeout=120s
```
```shell
kubectl get pod -n other -l app.kubernetes.io/name=adot-container-ci-collector
```