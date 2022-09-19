#!/bin/bash

kubectl create ns secretslab

# Create a text file containing your secret:
echo -n "am i safe?" > ./test-creds

# Create your secret:
kubectl create secret \
        generic test-creds \
        --from-file=test-creds=./test-creds \
        --namespace secretslab

# Retrieve the secret via the CLI:
kubectl get secret test-creds \
  -o jsonpath="{.data.test-creds}" \
  --namespace secretslab | \
  base64 --decode

