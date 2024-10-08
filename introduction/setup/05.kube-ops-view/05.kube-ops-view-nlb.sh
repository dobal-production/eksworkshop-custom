#!/bin/bash

# shellcheck disable=SC2164
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
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
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

kubectl apply -k deploy

sleep 20s

# export KOV_POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=kube-ops-view,app.kubernetes.io/instance=kube-ops-view" -o jsonpath="{.items[0].metadata.name}")
# kubectl port-forward $KOV_POD_NAME 8080:8080

kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'