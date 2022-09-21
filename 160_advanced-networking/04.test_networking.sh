#!/bin/bash
kubectl create deployment nginx --image=nginx
kubectl scale --replicas=3 deployments/nginx
kubectl expose deployment/nginx --type=NodePort --port 80

sleep 10s
kubectl get pods -o wide


