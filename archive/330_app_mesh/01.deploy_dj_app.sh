#!/bin/bash

# First, be sure you are in your environment directory
cd ~/environment

git clone https://github.com/aws/aws-app-mesh-examples

# Change to the repo's project directory:
cd aws-app-mesh-examples/examples/apps/djapp/

kubectl apply -f 1_base_application/base_app.yaml

sleep 10s
kubectl -n prod get all
