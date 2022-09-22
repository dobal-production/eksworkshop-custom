#!/bin/bash

cat << EOF > nginx-deployment-spc.yaml
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: nginx-deployment-spc
spec:
  provider: aws
  parameters:
    objects: |
        - objectName: "DBSecret_eksworkshop"
          objectType: "secretsmanager"
EOF

echo "##### Create custom resource."
kubectl apply -f nginx-deployment-spc.yaml

kubectl get SecretProviderClass

echo "##### Create pod and mount secrets"
cat << EOF > nginx-deployment.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      serviceAccountName: nginx-deployment-sa
      containers:
      - name: nginx-deployment
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: secrets-store-inline
          mountPath: "/mnt/secrets"
          readOnly: true
      volumes:
      - name: secrets-store-inline
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: nginx-deployment-spc
EOF

kubectl apply -f nginx-deployment.yaml
sleep 10
kubectl get pods -l "app=nginx"

echo "##### Verify the mounted secret"
export POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath='{.items[].metadata.name}')
kubectl exec -it ${POD_NAME} -- cat /mnt/secrets/DBSecret_eksworkshop; echo
