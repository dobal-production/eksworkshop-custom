#!/bin/bash

echo "##### Display my-nginx service"
kubectl -n my-nginx get svc my-nginx

echo "##### Update my-nginx service from ClusterIP to LoadBalancer"
kubectl -n my-nginx patch svc my-nginx -p '{"spec": {"type": "LoadBalancer"}}'
sleep 10

echo "##### Display my-nginx service again"
kubectl -n my-nginx get svc my-nginx

echo "##### Now, making load balancer, please wait 1m"
sleep 1m

echo "##### Now, let’s try if it’s accessible."

export loadbalancer=$(kubectl -n my-nginx get svc my-nginx -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')

curl -k -s http://${loadbalancer} | grep title

kubectl -n my-nginx describe service my-nginx | grep Ingress



