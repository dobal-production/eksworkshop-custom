## Kubernetes Event-Driven Autoscaler(KEDA)
* 외부의 이벤트나 메트릭의 이벤트 기반 스케일링

### Installing KEDA
```shell
helm repo add kedacore https://kedacore.github.io/charts
helm upgrade --install keda kedacore/keda \
  --version "${KEDA_CHART_VERSION}" \
  --namespace keda \
  --create-namespace \
  --set "podIdentity.aws.irsa.enabled=true" \
  --set "podIdentity.aws.irsa.roleArn=${KEDA_ROLE_ARN}" \
  --wait
```
```shell
kubectl get deployment -n keda
```
* `Agent(keda-operator)` 워크로드의 스케일링을 조절
* `Metrics(keda-operator-metrtic-server)` 외부 메트릭에 액세스
* `Adminssion Webhooks(keda-admission-webhooks)` 리소스 구성의 유효성을 검사하여 잘못된 구성을 방지

### Configure KEDA
```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: ui-hpa
  namespace: ui
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ui
  pollingInterval: 30
  cooldownPeriod: 300
  minReplicaCount: 1
  maxReplicaCount: 10
  triggers:
    - type: aws-cloudwatch
      metadata:
        namespace: AWS/ApplicationELB
        expression: SELECT COUNT(RequestCountPerTarget) FROM SCHEMA("AWS/ApplicationELB", LoadBalancer, TargetGroup) WHERE TargetGroup = '${TARGETGROUP_ID}' AND LoadBalancer = '${ALB_ID}'
        metricStat: Sum
        metricStatPeriod: "60"
        metricUnit: Count
        targetMetricValue: "100"
        minMetricValue: "0"
        awsRegion: "${AWS_REGION}"
        identityOwner: operator
```
```shell
export ALB_ARN=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn)
export ALB_ID=$(aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ui-ui`) == `true`]' | jq -r .[0].LoadBalancerArn | awk -F "loadbalancer/" '{print $2}')
export TARGETGROUP_ID=$(aws elbv2 describe-target-groups --load-balancer-arn $ALB_ARN | jq -r '.TargetGroups[0].TargetGroupArn' | awk -F ":" '{print $6}')
```
```shell
kubectl kustomize ~/environment/eks-workshop/modules/autoscaling/workloads/keda/scaledobject \
  | envsubst | kubectl apply -f-
```