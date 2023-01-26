#!/bin/bash

# bitnami/nginx chart 살펴보기
helm show chart bitnami/nginx
    
# bitnami/nginx 설치
helm install mywebserver bitnami/nginx

# 배포상태 확인
sleep 20s
kubectl get deploy,po,svc

# Service URL
kubectl get service mywebserver-nginx -o wide
