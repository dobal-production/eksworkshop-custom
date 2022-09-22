#!/bin/bash

cat << EoF > ${HOME}/environment/ebs_statefulset/mysql-storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: mysql-gp2
provisioner: ebs.csi.aws.com # Amazon EBS CSI driver
parameters:
  type: gp2
  encrypted: 'true' # EBS volumes will always be encrypted by default
volumeBindingMode: WaitForFirstConsumer # EBS volumes are AZ specific
reclaimPolicy: Delete
mountOptions:
- debug
EoF

kubectl create -f ${HOME}/environment/ebs_statefulset/mysql-storageclass.yaml
sleep 10s

kubectl describe storageclass mysql-gp2

