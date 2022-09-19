#!/bin/bash

cat << EOF > podconsumingsecret.yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: consumesecret
spec:
  containers:
  - name: shell
    image: amazonlinux:2
    command:
      - "bin/bash"
      - "-c"
      - "cat /tmp/test-creds && sleep 10000"
    volumeMounts:
      - name: sec
        mountPath: "/tmp"
        readOnly: true
  volumes:
  - name: sec
    secret:
      secretName: test-creds
EOF

# Deploy the pod on your EKS cluster:
kubectl --namespace secretslab apply -f podconsumingsecret.yaml

# Attach to the pod and attempt to access the secret:
kubectl --namespace secretslab exec -it consumesecret -- cat /tmp/test-creds

