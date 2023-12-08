#!/bin/bash

kubectl delete pod pod-variable pod-volume -n octank 
kubectl delete secret database-credentials -n octank
kubectl get secret -n octank

# Now, let’s reuse the Secret created previously to create SealedSecret YAML manifests with kubeseal.
cd ~/environment/secrets
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml

cat secret.yaml 
cat sealed-secret.yaml 

kubectl apply -f sealed-secret.yaml 

kubectl get pods -n kube-system | grep sealed-secrets-controller

kubectl apply -f pod-variable.yaml
kubectl wait -n octank pod/pod-variable --for=condition=Ready
kubectl logs -n octank pod-variable

# output
# pod/pod-variable created
# pod/pod-variable condition met
# DATABASE_USER = admin
# DATABASE_PASSWROD = Tru5tN0!

