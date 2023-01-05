## 사전 조건
> eksworkshop-admin role 생성
> cloud9 인스턴스에 eksworkshop-admin role 추가

## 기본실행 (Blueprint를 사용하지 않은 경우)
    . 01.modify-disk-size.sh
    . 02.install-tools.sh
    . 03.setting-environment.sh
    . 04.launch-eks-cluster.sh
    . 05.post-eks-cluster.sh

## Brueprint를 사용한 경ㅜ
    aws s3 cp s3://ee-assets-prod-us-east-1/modules/bd7b369f613f452dacbcea2a5d058d5b/v6/eksinit.sh . && chmod +x eksinit.sh && ./eksinit.sh ; source ~/.bash_profile ; source ~/.bashrc

## Helm & OpsView 설치
    . 06.install-helm.sh