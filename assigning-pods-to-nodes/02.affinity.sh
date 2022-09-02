#!/bin/bash

# 첫 번째 노드에 azname 추가
export FIRST_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[0].metadata.name')
kubectl label nodes ${FIRST_NODE_NAME} azname=az1

# affinity 1 : 꼬옥 azname이 az1 또는 az2인 노드들
# affinity 2 : 우선 another-node-label-key=another-node-label-value 노드들... 없으면... 암데나..
cat <<EoF > ~/environment/pod-with-node-affinity.yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: azname
            operator: In
            values:
            - az1
            - az2
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: another-node-label-key
            operator: In
            values:
            - another-node-label-value
  containers:
  - name: with-node-affinity
    image: us.gcr.io/k8s-artifacts-prod/pause:2.0
EoF

kubectl apply -f ~/environment/pod-with-node-affinity.yaml

sleep 10s
kubectl get pods -o wide

echo -n "Wait..........util Dobal says 'Enter any key'"
read text

# 확인했으면 일단 다시 지우고
kubectl delete -f ~/environment/pod-with-node-affinity.yaml
kubectl label nodes ${FIRST_NODE_NAME} azname-

# 두 번째 노드에 라벨을 붙여서 실행하면... pod는 두번째에 들어갈 것
export SECOND_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[1].metadata.name')
kubectl label nodes ${SECOND_NODE_NAME} azname=az1
kubectl apply -f ~/environment/pod-with-node-affinity.yaml

sleep 10s
kubectl get pods -o wide

echo -n "Wait ...... until Dobal says 'Enter any key'"
read text

kubectl delete -f ~/environment/pod-nginx.yaml
kubectl delete -f ~/environment/pod-with-node-affinity.yaml
kubectl label nodes ${SECOND_NODE_NAME} azname-
kubectl label nodes ${FIRST_NODE_NAME} disktype-
