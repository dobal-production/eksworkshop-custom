#!/bin/bash

curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm version --short

helm repo add stable https://charts.helm.sh/stable

helm search repo stable

helm completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
source <(helm completion bash)

# ops_view
cd ~/environment
git clone https://codeberg.org/hjacobs/kube-ops-view.git
cd kube-ops-view
sed -i 's/ClusterIP/LoadBalancer/g' deploy/service.yaml 
kubectl apply -k deploy

# sleep 20s
kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'

# echo "##### Deploy the metric server"
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml

cd ~/environment
