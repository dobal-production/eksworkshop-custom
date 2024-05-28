#!/bin/bash

# shellcheck disable=SC2164
cd ~/environment/eks-workshop/base-application/
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
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
EOF

# built-in kustomization command with -k
kubectl apply -k deploy

# export KOV_POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=kube-ops-view,app.kubernetes.io/instance=kube-ops-view" -o jsonpath="{.items[0].metadata.name}")
# kubectl port-forward $KOV_POD_NAME 8080:8080

kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'