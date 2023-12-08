#!/bin/bash

# -k 옵션은 디렉토리를 의미, (-f 는 파일을 의미)
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.3"
sleep 1m
kubectl get pods -n kube-system

mkdir ~/environment/efs
cd ~/environment/efs
wget https://eksworkshop.com/beginner/190_efs/efs.files/efs-pvc.yaml

sed -i "s/EFS_VOLUME_ID/$FILE_SYSTEM_ID/g" efs-pvc.yaml
kubectl apply -f efs-pvc.yaml

sleep 20s
kubectl get pvc -n storage
kubectl get pv

cd ~/environment/eksworkshop-custom/190_efs
