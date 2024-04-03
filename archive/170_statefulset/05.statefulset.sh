#!/bin/bash

cd ${HOME}/environment/ebs_statefulset
wget https://eksworkshop.com/beginner/170_statefulset/statefulset.files/mysql-statefulset.yaml

kubectl apply -f ${HOME}/environment/ebs_statefulset/mysql-statefulset.yaml

kubectl -n mysql rollout status statefulset mysql

kubectl -n mysql get pvc -l app=mysql
