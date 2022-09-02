#!/bin/bash

# get all nodes
kubectl get nodes

# 디스크 타입이 ssd인 노드만 가져오기
kubectl get nodes --selector disktype=ssd

# 첫 번째 노드에 disktype=ssd를 추가
export FIRST_NODE_NAME=$(kubectl get nodes -o json | jq -r '.items[0].metadata.name')
kubectl label nodes ${FIRST_NODE_NAME} disktype=ssd
kubectl get nodes --selector disktype=ssd

# Deploy a nginx pod only to the node with the new label
sleep 30s

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

kubectl get pods -o wide
kubectl get nodes --selector disktype=ssd
