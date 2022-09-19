#!/bin/bash

kubectl create namespace mysql

cd ${HOME}/environment/ebs_statefulset

cat << EoF > ${HOME}/environment/ebs_statefulset/mysql-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
  namespace: mysql
  labels:
    app: mysql
data:
  master.cnf: |
    # Apply this config only on the leader.
    [mysqld]
    log-bin
  slave.cnf: |
    # Apply this config only on followers.
    [mysqld]
    super-read-only
EoF

kubectl create -f ${HOME}/environment/ebs_statefulset/mysql-configmap.yaml

