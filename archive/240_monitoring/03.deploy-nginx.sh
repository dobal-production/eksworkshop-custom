#!/bin/bash

cat <<EoF > low-priority-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx-deployment
  name: nginx-deployment
spec:
  replicas: 10
  selector:
    matchLabels:
      app: nginx-deployment
  template:
    metadata:
      labels:
        app: nginx-deployment
    spec:
      containers:            
       - image: nginx
         name: nginx-deployment
         resources:
           limits:
              memory: 128Mi  
EoF
kubectl apply -f low-priority-deployment.yml
