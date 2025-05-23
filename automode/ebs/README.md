# Overview

* `StorageClass` : EKS Auto Mode가 자동으로 Amazon EBS 볼륨을 프로비저닝하기 위한 구성 정의
* 볼륨 유형, 암호화, KMS key, IOPS 등을 설정


## StatefulSet
* `catalog`, `order` 서비스는 데이터베이스를 실행하는 파드가 있음
* `catalog` 서비스용 데이터베이스로 MySQL이 싱글 StatefulSet으로 배포되어 있음

    ```shell
    kubectl describe statefulset retail-store-app-catalog-mysql
    ```
    ```yaml
    Name:               retail-store-app-catalog-mysql
    Namespace:          default
    CreationTimestamp:  Wed, 21 May 2025 01:59:12 +0000
    Selector:           app.kubernetes.io/component=mysql,app.kubernetes.io/instance=retail-store-app-catalog,app.kubernetes.io/name=retail-store-app-catalog
    Labels:             app.kubernetes.io/component=mysql
                        app.kubernetes.io/instance=retail-store-app-catalog
                        app.kubernetes.io/managed-by=Helm
                        app.kubernetes.io/name=retail-store-app-catalog
                        helm.sh/chart=catalog-0.8.5
    Annotations:        meta.helm.sh/release-name: retail-store-app-catalog
                        meta.helm.sh/release-namespace: default
    Replicas:           1 desired | 1 total
    Update Strategy:    RollingUpdate
      Partition:        0
    Pods Status:        1 Running / 0 Waiting / 0 Succeeded / 0 Failed
    Pod Template:
      Labels:  app.kubernetes.io/component=mysql
               app.kubernetes.io/instance=retail-store-app-catalog
               app.kubernetes.io/name=retail-store-app-catalog
      Containers:
       mysql:
        Image:      public.ecr.aws/docker/library/mysql:8.0
        Port:       3306/TCP
        Host Port:  0/TCP
        Environment:
          MYSQL_ROOT_PASSWORD:  my-secret-pw
          MYSQL_DATABASE:       catalog
          MYSQL_USER:           <set to the key 'username' in secret 'catalog-db'>  Optional: false
          MYSQL_PASSWORD:       <set to the key 'password' in secret 'catalog-db'>  Optional: false
        Mounts:
          /var/lib/mysql from data (rw)
      Volumes:
       data:
        Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
        Medium:        
        SizeLimit:     <unset>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Volume Claims:     <none>
    Events:            <none>
    ```
* `order` 서비스용 데이터베이스로 PostgreSQL이 싱글 StatefulSet으로 배포되어 있음

    ```shell
    kubectl describe statefulset retail-store-app-orders-postgresql
    ```
    ```yaml
    Name:               retail-store-app-orders-postgresql
    Namespace:          default
    CreationTimestamp:  Wed, 21 May 2025 01:59:14 +0000
    Selector:           app.kubernetes.io/component=postgresql,app.kubernetes.io/instance=retail-store-app-orders,app.kubernetes.io/name=retail-store-app-orders
    Labels:             app.kubernetes.io/component=postgresql
                        app.kubernetes.io/instance=retail-store-app-orders
                        app.kubernetes.io/managed-by=Helm
                        app.kubernetes.io/name=retail-store-app-orders
                        helm.sh/chart=orders-0.8.5
    Annotations:        meta.helm.sh/release-name: retail-store-app-orders
                        meta.helm.sh/release-namespace: default
    Replicas:           1 desired | 1 total
    Update Strategy:    RollingUpdate
      Partition:        0
    Pods Status:        1 Running / 0 Waiting / 0 Succeeded / 0 Failed
    Pod Template:
      Labels:  app.kubernetes.io/component=postgresql
               app.kubernetes.io/instance=retail-store-app-orders
               app.kubernetes.io/name=retail-store-app-orders
      Containers:
       postgresql:
        Image:      public.ecr.aws/docker/library/postgres:16.1
        Port:       5432/TCP
        Host Port:  0/TCP
        Environment:
          POSTGRES_DB:        orders
          POSTGRES_USER:      <set to the key 'username' in secret 'orders-db'>  Optional: false
          POSTGRES_PASSWORD:  <set to the key 'password' in secret 'orders-db'>  Optional: false
          PGDATA:             /data/pgdata
        Mounts:
          /data from data (rw)
      Volumes:
       data:
        Type:          EmptyDir (a temporary directory that shares a pod's lifetime)
        Medium:        
        SizeLimit:     <unset>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Volume Claims:     <none>
    Events:            <none>
    ```
## EmptyDir
* 파드가 실행될 때 자동으로 마운트되는 저장공간
* 파드 내 모든 컨테이너들이 읽고 쓸 수 있음
* 파드가 삭제되면 EmptyDir내용도 삭제됨
* PostgreSQL가 실행중인 파드에 파일을 쓰고, 읽기

    ```shell
    kubectl exec retail-store-app-orders-postgresql-0 -- bash -c "echo 123 > /data/pgdata/test.txt"
    ```
    ```shell
    kubectl exec retail-store-app-orders-postgresql-0 -- cat /data/pgdata/test.txt
    ```

* 파드를 삭제한 후, 다시 확인 : 파드가 삭제되면 자동으로 신규 파드가 실행됨

    ```shell
    kubectl delete pod retail-store-app-orders-postgresql-0
    ```
    ```shell
    kubectl wait --for=condition=Ready pod retail-store-app-orders-postgresql-0 --timeout=30s
    ```
    ```shell
    kubectl exec retail-store-app-orders-postgresql-0 -- cat /data/pgdata/test.txt
    ```
    ```shell
    cat: /data/pgdata/test.txt: No such file or directory
    command terminated with exit code 1
    ```

## Default Storage Class using EBS CSI driver
### KMS 키로 암호화되는 기본 `StorageClass` 생성
* KMS 키 생성

    ```shell
    KEY_ID=$(aws kms create-key --tags TagKey=Name,TagValue=eks-automode-workshop --query 'KeyMetadata.KeyId' --output text)
    KEY_ARN=$(aws kms describe-key --key-id $KEY_ID --query 'KeyMetadata.Arn' --output text)
    echo "Key Id:" $KEY_ID
    echo "Key Arn:" $KEY_ARN
    ```
* KMS 키에 대한 보안 정책 생성

    ```shell
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure list | grep region | awk '{print $2}')
    cat >key-policy.json <<EOF
    {
        "Version": "2012-10-17",
        "Id": "key-auto-policy-3",
        "Statement": [
            {
                "Sid": "iam-kms",
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::$AWS_ACCOUNT_ID:root"
                },
                "Action": "kms:*",
                "Resource": "*"
            },
            {
                "Sid": "ec2-kms",
                "Effect": "Allow",
                "Principal": {
                    "AWS": "*"
                },
                "Action": [
                    "kms:Encrypt",
                    "kms:Decrypt",
                    "kms:ReEncrypt*",
                    "kms:GenerateDataKey*",
                    "kms:CreateGrant",
                    "kms:DescribeKey"
                ],
                "Resource": "*",
                "Condition": {
                    "StringEquals": {
                        "kms:CallerAccount": "$AWS_ACCOUNT_ID",
                        "kms:ViaService": "ec2.$AWS_REGION.amazonaws.com"
                    }
                }
            }
        ]
    }
    EOF
    ```

* KMS 키에 정책 연결

    ```shell
    aws kms put-key-policy --key-id $KEY_ID --policy file://key-policy.json
    ```

* KMS 키를 사용한 `StorageClass` 생성
    * `ReclaimPolicy` 는 default 값이 `delete` : `PersistentVolumeClaim`이 삭제될 때 `PersistentVolume` 도 삭제

    ```shell
    cat >~/environment/ebs-kms-sc.yaml <<EOF
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: eks-auto-ebs-kms-sc
      annotations:
        storageclass.kubernetes.io/is-default-class: "true"
    provisioner: ebs.csi.eks.amazonaws.com
    volumeBindingMode: WaitForFirstConsumer  # PVC를 사용하는 파드가 생성될 때까지 PV 생성이 대기
    parameters:
      type: gp3 # defaults to 3000 IOPS
      encrypted: "true"
      kmsKeyId: $KEY_ID
    EOF
    
    kubectl apply -f ~/environment/ebs-kms-sc.yaml
    ```

### Calalog 서비스용 MySQL 파드 재배포
* 기존 애플레리케이션 삭제

    ```shell
    helm uninstall retail-store-app-catalog
    ```

* DB 관련 설정을 업데이트하여 재배포

    ```shell
    helm upgrade -i retail-store-app-catalog oci://public.ecr.aws/aws-containers/retail-store-sample-catalog-chart --version ${RETAIL_STORE_APP_HELM_CHART_VERSION} -f - <<EOF
    mysql:
      secret:
        create: true
        name: catalog-db
        username: catalog
        password: "mysqlcatalog123"
      persistentVolume:
        enabled: true
        accessMode:
          - ReadWriteOnce
        size: 30Gi
    EOF
    ```

* `Catalog`용 MySQL이 생성되었는지 확인
* 
    ```shell
    kubectl describe statefulset retail-store-app-catalog-mysql
    ```
    ```shell
    Name:               retail-store-app-catalog-mysql
    Namespace:          default
    CreationTimestamp:  Fri, 23 May 2025 04:57:44 +0000
    Selector:           app.kubernetes.io/component=mysql,app.kubernetes.io/instance=retail-store-app-catalog,app.kubernetes.io/name=retail-store-app-catalog
    Labels:             app.kubernetes.io/component=mysql
                        app.kubernetes.io/instance=retail-store-app-catalog
                        app.kubernetes.io/managed-by=Helm
                        app.kubernetes.io/name=retail-store-app-catalog
                        helm.sh/chart=catalog-0.8.5
    Annotations:        meta.helm.sh/release-name: retail-store-app-catalog
                        meta.helm.sh/release-namespace: default
    Replicas:           1 desired | 1 total
    Update Strategy:    RollingUpdate
      Partition:        0
    Pods Status:        1 Running / 0 Waiting / 0 Succeeded / 0 Failed
    Pod Template:
      Labels:  app.kubernetes.io/component=mysql
               app.kubernetes.io/instance=retail-store-app-catalog
               app.kubernetes.io/name=retail-store-app-catalog
      Containers:
       mysql:
        Image:      public.ecr.aws/docker/library/mysql:8.0
        Port:       3306/TCP
        Host Port:  0/TCP
        Environment:
          MYSQL_ROOT_PASSWORD:  my-secret-pw
          MYSQL_DATABASE:       catalog
          MYSQL_USER:           <set to the key 'username' in secret 'catalog-db'>  Optional: false
          MYSQL_PASSWORD:       <set to the key 'password' in secret 'catalog-db'>  Optional: false
        Mounts:
          /var/lib/mysql from data (rw)
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Volume Claims:
      Name:          data
      StorageClass:  
      Labels:        <none>
      Annotations:   <none>
      Capacity:      30Gi
      Access Modes:  [ReadWriteOnce]
    Events:
      Type    Reason            Age   From                    Message
      ----    ------            ----  ----                    -------
      Normal  SuccessfulCreate  25s   statefulset-controller  create Claim data-retail-store-app-catalog-mysql-0 Pod retail-store-app-catalog-mysql-0 in StatefulSet retail-store-app-catalog-mysql success
      Normal  SuccessfulCreate  25s   statefulset-controller  create Pod retail-store-app-catalog-mysql-0 in StatefulSet retail-store-app-catalog-mysql successful
    ```

* PVC 확인
    
    ```shell
    kubectl get pvc
    kubectl describe pvc data-retail-store-app-catalog-mysql-0
    ```
