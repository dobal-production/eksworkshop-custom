#!/bin/bash

cd ~/environment
git clone https://codeberg.org/hjacobs/kube-ops-view.git
cd kube-ops-view

cat << EOF > deploy/service.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    application: kube-ops-view
    component: frontend
  name: kube-ops-view
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
spec:
  selector:
    application: kube-ops-view
    component: frontend
  type: LoadBalancer
  loadBalancerClass: service.k8s.aws/nlb
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
EOF

# built-in kustomization command with -k
kubectl apply -k deploy

sleep 20s
kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'
