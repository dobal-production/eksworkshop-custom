## Gravition(ARM) Instances
* 최대 20% 저렴, 최대 40% 높은 가성비, 최대 60% 에너지 절감(5세대 대비)
* 재컴파일 또는 빌드가 필요할 수 있음

### Taints and Tolerations
* taint가 걸린 노드에는 pod들이 스케쥴링 되지 않음.
* taint가 걸리 노드에 pod를 스케쥴링하려면 toleration을 지정해야 함.
* Control Plane의 노드들은 `node-role.kubernetes.io/master=xxxxxx:NoSchedule` taint가 걸려있어 애플리케이션 pod가 스케쥴링 되지 않음.
* Taint
  * key, value, effect로 구성
  * NoSchedule : pod를 스케쥴링하지 않음
  * NoExecute : pod 실행 자체를 허용하지 앟음, toleration이 걸려있지 않으면 퇴출
  * PreferNoSchedule : 가능하면 스케쥴링 하지 않음

* GPU를 가진 노드 그룹을 생성한 뒤, gpu를 사용하는 pod만 스케쥴링하는 예제
```shell
aws eks create-nodegroup \
 --cli-input-json '
{
  "clusterName": "my-cluster",
  "nodegroupName": "node-taints-example",
  "subnets": [
     "subnet-1234567890abcdef0",
     "subnet-abcdef01234567890",
     "subnet-021345abcdef67890"
   ],
  "nodeRole": "arn:aws:iam::111122223333:role/AmazonEKSNodeRole",
  "taints": [
     {
         "key": "dedicated",
         "value": "gpuGroup",
         "effect": "NO_SCHEDULE"
     }
   ]
}'
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gpu-app
  template:
    metadata:
      labels:
        app: gpu-app
    spec:
      tolerations:
      - key: "dedicated"
        operator: "Equal"
        value: "gpuGroup"
        effect: "NoSchedule"
      containers:
      - name: gpu-container
        image: nvidia/cuda:11.0-base
        resources:
          limits:
            nvidia.com/gpu: 1
```

### Creation Graviton Nodes
* Graviton 노드 그룹 생성
```shell
aws eks create-nodegroup \
  --cluster-name $EKS_CLUSTER_NAME \
  --nodegroup-name graviton \
  --node-role $GRAVITON_NODE_ROLE \
  --subnets $PRIMARY_SUBNET_1 $PRIMARY_SUBNET_2 $PRIMARY_SUBNET_3 \
  --instance-types t4g.medium \
  --ami-type AL2_ARM_64 \
  --scaling-config minSize=1,maxSize=3,desiredSize=1 \
  --disk-size 20
```
```shell
kubectl get nodes \
    --label-columns eks.amazonaws.com/nodegroup,kubernetes.io/arch
```
```shell
kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton
```

### Configuring taints for Managed Node Groups
```shell
aws eks update-nodegroup-config \
    --cluster-name $EKS_CLUSTER_NAME --nodegroup-name graviton \
    --taints "addOrUpdateTaints=[{key=frontend, value=true, effect=NO_EXECUTE}]"
```
```shell
kubectl describe nodes \
    --selector eks.amazonaws.com/nodegroup=graviton | grep Taints
```

### Run pod on Gravition
* ui deployment에 `kubernetes.io/arch: arm64` 설정을 가진 `nodeSelector`를 추가
```yaml
             runAsUser: 1000
           volumeMounts:
             - mountPath: /tmp
               name: tmp-volume
+      nodeSelector:
+        kubernetes.io/arch: arm64
       securityContext:
         fsGroup: 1000
       serviceAccountName: ui
       volumes:
```
```shell
kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-wo-toleration/
```
* nodeSelector는 gravition node에 스케쥴링하라는 의미지만, toleration이 없기 때문에 pod는 pending 상태로 대기
* 새로운 pod가 pending 상태이기 때문에 기존 ui pod는 종료되지 않음
* toleration을 추가하여 pod를 gravition node에 스케쥴링
```yaml
             runAsUser: 1000
           volumeMounts:
             - mountPath: /tmp
               name: tmp-volume
+      nodeSelector:
+        kubernetes.io/arch: arm64
       securityContext:
         fsGroup: 1000
       serviceAccountName: ui
+      tolerations:
+        - effect: NoExecute
+          key: frontend
+          operator: Exists
       volumes:
         - emptyDir:
             medium: Memory
           name: tmp-volume
```
```shell
kubectl apply -k ~/environment/eks-workshop/modules/fundamentals/mng/graviton/nodeselector-w-toleration/
kubectl --namespace ui rollout status deployment/ui --timeout=120s
```
```shell
kubectl get pod --namespace ui -l app.kubernetes.io/name=ui
```