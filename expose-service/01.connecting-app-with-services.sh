#!/bin/bash

#If you created a default deny policy in the previous section, delete it by running:
if [ -f ~/environment/calico_resources/default-deny.yaml ]; then
  kubectl delete -f ~/environment/calico_resources/default-deny.yaml
fi

cat <<EoF > ~/environment/run-my-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
  namespace: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EoF

# create the namespace
kubectl create ns my-nginx
# create the nginx deployment with 2 replicas
kubectl -n my-nginx apply -f ~/environment/run-my-nginx.yaml

kubectl -n my-nginx get pods -o wide

# kubectl -n my-nginx get pods -o yaml | grep 'podIP:'

