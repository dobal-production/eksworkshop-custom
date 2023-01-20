## Deploy the official kubernetes dashboard
### 기본실행
- yaml을 다운 받아 실행하는 교재와 달리, helm chart를 이용한 설치
- Service Type을 LoadBalancer로 변경하여 브라우저로 접속 가능

        01.dashbaord.sh

### 01.dashboard.sh 내용
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

### Cleanup
    02.cleanup.sh