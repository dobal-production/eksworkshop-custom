#!/bin/bash

cd ~/environment/calico_resources
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/apply_network_policies.files/default-deny.yaml

kubectl apply -n stars -f default-deny.yaml
kubectl apply -n client -f default-deny.yaml

cd ~/environment/calico_resources
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/apply_network_policies.files/allow-ui.yaml
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/apply_network_policies.files/allow-ui-client.yaml

kubectl apply -f allow-ui.yaml
kubectl apply -f allow-ui-client.yaml
