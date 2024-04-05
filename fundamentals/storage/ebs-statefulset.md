## Storage
### StatefulSets
* 데몬셋처럼 특수한 형태의 레플리카셋
* Scale명령도 replica와 유사
* 생성된 pod명 접미사에 숫자(0번 부터)가 부여
* 기본적으로 앞선 숫자의 pod부터 차례대로 생성
* pod명이 바뀌지 않음 (persistent identifier) → 재배포시에도 동일한 pod명(식별자)
* 데이터를 영구적으로 저장하기 위한 구조
* <podName-일련번호>.<serviceName> 형식으로 접근 가능
* 본 예제에서는 EKS상에서 실행중인 MySQL DB를 이용하는 Catalog microservice을 StatefulSet으로 배포  
  ```sh
  kubectl get pod -n catalog
  kubectl log -n catalog catalog-mysql-0 --tail 5
  kubectl get pod -n catalog catalog-mysql-0 -o jsonpath='{.metadata.labels}{\"\n\"}'
  ```  

  ![StatefulSet](https://www.eksworkshop.com/assets/images/mysql-emptydir-2f2957717a2a5f66c238b6dc19587248.png)

  * 파드의 볼륨은 파드 내의 컨테이들 모두 읽기/쓰기가 가능
  * 파드 생성시 기본으로 할당되는 emptyDir 볼륨의 수명은 파드의 수명과 같이하여 노드에서 파드가 제거되면 emtpyDir내의 데이터도 영구히 삭제
  * 실습에서는 emptyDir에 파일을 생성한 뒤, 파드를 삭제하고 재시작하여 emptyDir내 파일이 살아있는지 확인  
    ```
    kubectl exec catalog-mysql-0 -n catalog -- bash -c  "echo 123 > /var/lib/mysql/test.txt"
    ```
    ```
    kubectl exec catalog-mysql-0 -n catalog -- ls -larth /var/lib/mysql/ | grep -i test
    ```
    ```
    kubectl delete pods -n catalog -l app.kubernetes.io/component=mysql
    ```
    ```
    kubectl wait --for=condition=Ready pod -n catalog \
    -l app.kubernetes.io/component=mysql --timeout=30s
    kubectl get pods -n catalog -l app.kubernetes.io/component=mysql
    ```
    ```
    kubectl exec catalog-mysql-0 -n catalog -- cat /var/lib/mysql/test.txt
    ```





### References
* [Kubernetes를 위한 영구 스토리지 적용하기](https://aws.amazon.com/ko/blogs/tech/persistent-storage-for-kubernetes/)