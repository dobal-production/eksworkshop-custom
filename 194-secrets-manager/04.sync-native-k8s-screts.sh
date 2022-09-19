cat << EOF > nginx-deployment-spc-k8s-secrets.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: nginx-deployment-spc-k8s-secrets
spec:
  provider: aws
  parameters: 
    objects: |
      - objectName: "DBSecret_eksworkshop"
        objectType: "secretsmanager"
        jmesPath:
          - path: username
            objectAlias: dbusername
          - path: password
            objectAlias: dbpassword
  # Create k8s secret. It requires volume mount first in the pod and then sync.
  secretObjects:                
    - secretName: my-secret-01
      type: Opaque
      data:
        #- objectName: <objectName> or <objectAlias> 
        - objectName: dbusername
          key: db_username_01
        - objectName: dbpassword
          key: db_password_01
EOF

kubectl apply -f nginx-deployment-spc-k8s-secrets.yaml

kubectl get SecretProviderClass nginx-deployment-spc-k8s-secrets


# Create pod mount secrets volumes and set up Environment variables.
cat << EOF > nginx-deployment-k8s-secrets.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-k8s-secrets
  labels:
    app: nginx-k8s-secrets
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-k8s-secrets
  template:
    metadata:
      labels:
        app: nginx-k8s-secrets
    spec:
      serviceAccountName: nginx-deployment-sa
      containers:
      - name: nginx-deployment-k8s-secrets
        image: nginx
        imagePullPolicy: IfNotPresent
        ports:
          - containerPort: 80
        volumeMounts:
          - name: secrets-store-inline
            mountPath: "/mnt/secrets"
            readOnly: true
        env:
          - name: DB_USERNAME_01
            valueFrom:
              secretKeyRef:
                name: my-secret-01
                key: db_username_01
          - name: DB_PASSWORD_01
            valueFrom:
              secretKeyRef:
                name: my-secret-01
                key: db_password_01
      volumes:
        - name: secrets-store-inline
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: nginx-deployment-spc-k8s-secrets
EOF

kubectl apply -f nginx-deployment-k8s-secrets.yaml
sleep 10
kubectl get pods -l "app=nginx-k8s-secrets"

kubectl exec -it ${POD_NAME} -- cat /mnt/secrets/dbusername; echo
kubectl exec -it ${POD_NAME} -- cat /mnt/secrets/dbpassword; echo
kubectl exec -it ${POD_NAME} -- env | grep DB; echo

kubectl describe secrets my-secret-01


