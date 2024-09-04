## Secrets Management
* 보안에 민감한 주요 환경변수들(예, DB 계정 정보들)을 개발 소스에 보관하는 것은 좋지 않음
* 민감 정보들을 관리하는 주체와 사용하는 주체는 분리하여 운영하는 것이 답

### Exploring Secrets
* K8S Secrets는 암호, 토큰, 키와 같은 민감정보를 저장하는 오브젝트
* ConfigMap과 유사하지만 base64로 인코딩되어 저장된다는 것이 차이
* AWS KMS를 이용하여 암호화 가능 

```shell
# catalog-db secret
kubectl get secret -n catalog catalog-db -o json

# username key
kubectl get secret -n catalog catalog-db -o jsonpath="{.data.username}" | base64 --decode
kubectl get secret -n catalog catalog-db -o jsonpath="{.data.password}" | base64 --decode
```

* 환경 변수
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: someName
      namespace: someNamespace
    spec:
      containers:
        - name: someContainer
          image: someImage
          env:
            - name: DATABASE_USER
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: username
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: password
    ```
* 볼륨 마운트
  * mountPath에 텍스트로 노출
  * 아래의 예제는 `/etc/data/DATABASE_USR` `/etc/data/DATABASE_PASSWORD`에 위치
  

```yaml
apiVersion: v1
kind: Pod
metadata:
name: someName
namespace: someNamespace
spec:
containers:
  - name: someContainer
    image: someImage
    volumeMounts:
      - name: secret-volume
        mountPath: "/etc/data"
        readOnly: true
volumes:
  - name: secret-volume
    secret:
      secretName: database-credentials
      items:
        - key: username
          path: DATABASE_USER
        - key: password
          path: DATABASE_PASSWORD
```