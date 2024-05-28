#!/bin/bash

# after install aws load balancer controller
# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html

# shellcheck disable=SC2164
cd ~/environment/eks-workshop/base-application/
git clone https://codeberg.org/hjacobs/kube-ops-view.git
cd kube-ops-view

cat << EOF > deploy/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
    name: "kube-ops-view-ingress"
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/group.name: kube-ops-view
      alb.ingress.kubernetes.io/group.order: '1'
      alb.ingress.kubernetes.io/healthcheck-path: "/"
spec:
    rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: "kube-ops-view"
                port:
                  number: 80
EOF

cat << EOF > deploy/service.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    application: kube-ops-view
    component: frontend
  name: kube-ops-view
    
spec:
  selector:
    application: kube-ops-view
    component: frontend
  type: NodePort
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
EOF

cat << EOF > deploy/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kube-ops-view
  labels:
    application: kube-ops-view
    component: frontend
EOF

cat << EOF > deploy/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - rbac.yaml
  - service.yaml
  - redis-deployment.yaml
  - redis-service.yaml
  - ingress.yaml
  - namespace.yaml
EOF



kubectl apply -k deploy

sleep 20s
kubectl get ingress kube-ops-view-ingress | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'