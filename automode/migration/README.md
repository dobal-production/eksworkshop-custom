## 클러스터 구성
* 이미 일반 Amazon EKS 클러스터가 준비되어 있음

```shell
kubectl config get-contexts
```
* 관리 클러스터 전환

    ```shell
    kubectl config use-context arn:aws:eks:${AWS_REGION}:${AWS_ACCOUNT_ID}:cluster/${MIGRATION_CLUSTER_NAME}
    ```

* 노드 확인

    ```shell
    kubectl get nodes -o json | jq -r '.items[].metadata.labels | ."kubernetes.io/hostname" + " | " + ."topology.kubernetes.io/zone" + " | " + (."eks.amazonaws.com/capacityType" // if ."eks.amazonaws.com/compute-type" == "fargate" then "FARGATE" else "KARPENTER" end) + " | " + (."eks.amazonaws.com/nodegroup" // if ."karpenter.sh/nodepool" then "nodepool: " + ."karpenter.sh/nodepool" else "profile: apps" end)' | column -t | sort -k 5
    ```