#!/bin/bash

echo "##### get all nodes"
kubectl get nodes

echo "##### 디스크 타입이 ssd인 노드만 가져오기"
kubectl get nodes --selector disktype=ssd

echo "##### 첫 번째 노드에 label disktype=ssd를 추가"
export FIRST_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[0].metadata.name')
kubectl label nodes ${FIRST_NODE_NAME} disktype=ssd
kubectl get nodes --selector disktype=ssd
sleep 10s

echo "##### Deploy a nginx pod only to the node with the new label"
cat <<EoF > ~/environment/pod-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    env: test
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
  nodeSelector:
    disktype: ssd
EoF

kubectl apply -f ~/environment/pod-nginx.yaml

sleep 10s
echo "##### Display node with disktype=ssd and pod in that"
kubectl get pods -o wide
kubectl get nodes --selector disktype=ssd
