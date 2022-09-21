#!/bin/bash

# Install kubecost
kubectl create namespace kubecost
helm repo add kubecost https://kubecost.github.io/cost-analyzer/
helm install kubecost kubecost/cost-analyzer --namespace kubecost --set kubecostToken="ZG9rZXVub2hAZ21haWwuY29txm343yadf98"

# Install NGINX Ingress
helm repo add stable https://charts.helm.sh/stable
helm install example-ingress stable/nginx-ingress -n kubecost
sleep 20s
export ELB=$(kubectl get svc -n kubecost example-ingress-nginx-ingress-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/auth-realm: Authentication Required - ok
    nginx.ingress.kubernetes.io/auth-secret: kubecost-auth
    nginx.ingress.kubernetes.io/auth-type: basic
  labels:
    app: cost-analyzer
    app.kubernetes.io/instance: kubecost
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: cost-analyzer
    helm.sh/chart: cost-analyzer-1.60.1
  name: kubecost-cost-analyzer
  namespace: kubecost
spec:
  rules:
  - host: $ELB
    http:
      paths:
      - backend:
          serviceName: kubecost-cost-analyzer
          servicePort: 9090
        path: /
" | kubectl apply -f -

htpasswd -c auth kubecost-admin

kubectl create secret generic \
    kubecost-auth \
    --from-file auth \
    -n kubecost

kubectl get ingresses. kubecost-cost-analyzer -o yaml -n kubecost

echo https://$ELB

