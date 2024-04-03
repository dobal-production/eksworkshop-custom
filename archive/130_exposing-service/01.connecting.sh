#!/bin/bash

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

echo "##### Create the namespace"
kubectl create ns my-nginx

echo "##### Create the nginx deployment with 2 replicas"
kubectl -n my-nginx apply -f ~/environment/run-my-nginx.yaml
kubectl -n my-nginx get pods -o wide

sleep 10s
kubectl -n my-nginx get pods -o yaml | grep 'podIP:'

echo "##### Creating a Service"
kubectl -n my-nginx expose deployment/my-nginx
kubectl -n my-nginx get svc my-nginx
sleep 10s

kubectl -n my-nginx describe svc my-nginx

sleep 10s
ehco "##### Create a variable set with the my-nginx service IP"
export MyClusterIP=$(kubectl -n my-nginx get svc my-nginx -ojsonpath='{.spec.clusterIP}')

echo "##### Create a new deployment and allocate a TTY for the container in the pod"
kubectl -n my-nginx run -i --tty load-generator --env="MyClusterIP=${MyClusterIP}" --image=busybox /bin/sh
wget -q -O - ${MyClusterIP} | grep '<title>'

