mkdir ~/environment/calico_resources
cd ~/environment/calico_resources

cd ~/environment/calico_resources
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/create_resources.files/namespace.yaml

kubectl apply -f namespace.yaml

cd ~/environment/calico_resources
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/create_resources.files/management-ui.yaml
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/create_resources.files/backend.yaml
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/create_resources.files/frontend.yaml
wget https://eksworkshop.com/beginner/120_network-policies/calico/stars_policy_demo/create_resources.files/client.yaml

kubectl apply -f management-ui.yaml
kubectl apply -f backend.yaml
kubectl apply -f frontend.yaml
kubectl apply -f client.yaml

kubectl get pods --all-namespaces
kubectl get svc -o wide -n management-ui

