## Deploy the official kubernetes dashboard
### 1. yaml파일을 이용한 설치
#### 공식 사이트에서 yaml 파일 다운로드

        wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

#### service spec에 type을 LoadBalancer로 설정
    kind: Service
    apiVersion: v1
    metadata:
      labels:
        k8s-app: kubernetes-dashboard
      name: kubernetes-dashboard
      namespace: kubernetes-dashboard
    spec:
      ports:
        - port: 443
          targetPort: 8443
      # 43번째 줄에 아래와 같이 한 줄 추가
      type: LoadBalancer
      selector:
        k8s-app: kubernetes-dashboard

#### Dashboard 설치
    kubectl apply -f ./recommended.yaml
    
### LoadBalancer URL 확인
    kubectl get svc kubernetes-dashboard -n kubernetes-dashboard | tail -n 1 | awk '{ print "kube-dashboard URL = https://"$4 }'

### Token 가져오기
    aws eks get-token --cluster-name eksworkshop-eksctl | jq -r '.status.token'

### 삭제
    kubectl delete -f ./recommended.yaml

### 2. Helm을 이용한 설치
#### 01.dashboard.sh 실행
    01.dashbaord.sh

#### 01.dashboard.sh 파일 내용
    # helm repository 추가
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
    
    # kubernetes-dashboard 설치
    helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard

    # Service를 LoadBalaner로 변경
    kubectl patch svc kubernetes-dashboard -n default -p '{"spec":{"type":"LoadBalancer"}}'

    # Service URL 출력
    kubectl get svc kubernetes-dashboard -n default | tail -n 1 | awk '{ print "kube-dashboard URL = https://"$4 }'

    # 로그인에 사용할 토큰 가져오기
    aws eks get-token --cluster-name eksworkshop-eksctl | jq -r '.status.token'

#### Cleanup
    02.cleanup.sh