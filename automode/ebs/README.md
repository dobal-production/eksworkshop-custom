# Overview

* `StorageClass` : EKS Auto Mode가 자동으로 Amazon EBS 볼륨을 프로비저닝하기 위한 구성 정의
* 볼륨 유형, 암호화, KMS key, IOPS 등을 설정


### StatefulSet
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