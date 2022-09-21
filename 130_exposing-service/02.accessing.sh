#!/bin/bash

echo "##### Let’s view the pods again"
kubectl -n my-nginx get pods -l run=my-nginx -o wide

echo "##### Now let’s inspect the environment of one of your running nginx Pods:"
export mypod=$(kubectl -n my-nginx get pods -l run=my-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl -n my-nginx exec ${mypod} -- printenv | grep SERVICE

echo "##### Restart"
kubectl -n my-nginx rollout restart deployment my-nginx
sleep 10s
kubectl -n my-nginx get pods -l run=my-nginx -o wide

sleep 10s
export mypod=$(kubectl -n my-nginx get pods -l run=my-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl -n my-nginx exec ${mypod} -- printenv | grep SERVICE

echo "##### display kube dns"
kubectl get service -n kube-system -l k8s-app=kube-dns

kubectl -n my-nginx run curl --image=radial/busyboxplus:curl -i --tty
nslookup my-nginx

