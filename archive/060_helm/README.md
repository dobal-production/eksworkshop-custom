#### Introduciton

- 서비스를 배포하기 위해 xxx-deployment.yaml, xxx-service.yaml, ingress.yaml를 반복적으로 배포해야 했음.
    
        cd ~/environment/ecsdemo-crystal
        kubectl apply -f kubernetes/deployment.yaml
        kubectl apply -f kubernetes/service.yaml
        kubectl apply -f kubernetes/ingress.yaml
- 대부분의 구조가 유사
- dev/stage/prod 환경 배포시 9개 이상의 yaml파일 필요
- 신규 서비스 생성시 복붙신공 후, 편집 → 파일 중 하나의 편집을 누락할 경우 → 대환장파티
- 서비스가 많아질 수록 yaml파일 관리가 어려워짐.
- 이 리소스들을 하나의 논리적 배포 단위로 패키징하고 관리해주는 솔루션이 Helm임.
- “우리는 그 논리적 배포 단위를 차트(chart)라고 부르기로 했어요“
- Chart는 k8s 리소스를 기술한 파일 및 템플릿의 모음.
- 웹 서버를 배포한다고 할 때, 서비스, 웹 서버, 프록시 등을 모두 담아 Chart로 만들어 사용.
- 동일한 류의 배포를 위해 템플릿화하여 찍어낼 수 있음.
- 어플리케이션과 서비스의 버저닝을 이용하여 어플리케이션의 종속성 관리.
- 어플리케이션을 배포하는 동안 pre/post 작업 실행.
- [020_prerequisites/06.install-helm.sh](../020_prerequisites/06.install-helm.sh)

#### Deploy nginx with Helm
- Chart 레포지토리는 계속 업데이트 되기 때문에 최신 상태로 업데이트 할 필요가 있음.

        01.updatecharts.sh

- 특정 키워드로 helm chart를 찾는 방법

        # Search for stable release versions matching the keyword "nginx"
        $ helm search repo nginx
    
        # Search for release versions matching the keyword "nginx", including pre-release versions
        $ helm search repo nginx --devel
    
        # Search for the latest stable release for nginx-ingress with a major version of 1
        $ helm search repo nginx-ingress --version ^1.0.0
    

- bitnami의 레포지토리에서 Standalone 웹서버를 사용할 예정
        
        02.addbitnamirepo.sh
- 하나의 chart를 가지고 여러 식별자(이름)로 설치할 수 있음. 
        
        helm install [NAME] [CHART] [flags]

- bitnami/nginx chart 설치 (참고 : [Helm Install](https://helm.sh/docs/helm/helm_install/))
    
        03.installnginx.sh
    
- 서비스 삭제에 1~2분 정도 시간이 걸림.
- kubectl 명령어를 이용하여 리플리카 셋을 3으로 늘려보기

        kubectl scale deployment -n default mywebserver-nginx --replicas=3

- cleanup

        helm list
        helm uninstall mywebserver
