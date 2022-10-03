#!/bin/bash

echo 'export ISTIO_VERSION="1.14.1"' >> ${HOME}/.bash_profile
source ${HOME}/.bash_profile

cd ~/environment
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -

cd ${HOME}/environment/istio-${ISTIO_VERSION}

sudo cp -v bin/istioctl /usr/local/bin/
istioctl version --remote=false

cd ~/environment/eksworkshop-custom/310_servicemesh_with_istio

yes | istioctl install --set profile=demo
sleep 30s

kubectl -n istio-system get svc
kubectl -n istio-system get pods
