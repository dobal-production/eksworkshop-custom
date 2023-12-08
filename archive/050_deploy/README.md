## Deploy the Example Microservices
![Target architecture](images/crystal.svg)
* 하나의 Front, 두 개의 Backend 배포
* Front 접속을 위해 loadbalancer type의 service 배포

### Deploy NodeJS Backend API
    01.deploynodejs.sh

### Deploy Cristal Backend API
    02.deploycristal.sh

### Ensure the ELB service Role exists
    aws iam get-role --role-name "AWSServiceRoleForElasticLoadBalancing" || aws iam create-service-linked-role --aws-service-name "elasticloadbalancing.amazonaws.com"

### Deploy Frontend Service
    03.deployfrontend.sh
* loadbalancer 생성에 2~3분 소요됨  
* console에서 elb가 생성되는 것을 확인할 수 있음

### Find the Service Address
    04.viewservices.sh

### Scale the Frontend
    05.scalebackend.sh


