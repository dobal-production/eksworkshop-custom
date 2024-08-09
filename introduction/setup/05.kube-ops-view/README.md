### Install with CLB (Easy, Not recommend)
* type을 LoadBalancer로 변경하면 CLB가 생성됨
  ```shell
  cd ~/environment
  git clone https://codeberg.org/hjacobs/kube-ops-view.git
  cd kube-ops-view
  sed -i 's/ClusterIP/LoadBalancer/g' deploy/service.yaml
  kubectl apply -k deploy
  
  sleep 20s
  kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'
  ```

### Install with NLB (Easy)
* annotation을 이용하여 clb대신 nlb를 생성할 수 있음
  ```shell
  cd ~/environment
  git clone https://codeberg.org/hjacobs/kube-ops-view.git
  cd kube-ops-view
  
  cat << EOF > deploy/service.yaml
  apiVersion: v1
  kind: Service
  metadata:
    labels:
      application: kube-ops-view
      component: frontend
    name: kube-ops-view
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
  spec:
    selector:
      application: kube-ops-view
      component: frontend
    type: LoadBalancer
    ports:
    - port: 80
      protocol: TCP
      targetPort: 8080
  EOF
  
  kubectl apply -k deploy
      
  sleep 20s
  kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'
  ```

### Install with ingress/ALB (Recommend)
* [AWS load balancer controller](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html) 설치 필수
* subnet에 관련 tag가 설정되어 있어야 함 ([VPC 및 Subnet 요구사항](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/network_reqs.html))
* Ingress를 이용하여 서비스 노출(AWS는 ALB 새성)
* kube-ops-view-ingress.sh
    ```shell
    cd ~/environment
    git clone https://codeberg.org/hjacobs/kube-ops-view.git
    cd kube-ops-view
    
    cat << EOF > deploy/ingress.yaml
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
        name: "kube-ops-view-ingress"
        annotations:
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/group.name: kube-ops-view
          alb.ingress.kubernetes.io/group.order: '1'
          alb.ingress.kubernetes.io/healthcheck-path: "/"
    spec:
        ingressClassName: alb
        rules:
        - http:
            paths:
              - path: /
                pathType: Prefix
                backend:
                  service:
                    name: "kube-ops-view"
                    port:
                      number: 80
    EOF
    
    cat << EOF > deploy/service.yaml
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        application: kube-ops-view
        component: frontend
      name: kube-ops-view
    spec:
      selector:
        application: kube-ops-view
        component: frontend
      type: NodePort
      ports:
      - port: 80
        protocol: TCP
        targetPort: 8080
    EOF
    
    cat << EOF > deploy/kustomization.yaml
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - deployment.yaml
      - rbac.yaml
      - service.yaml
      - redis-deployment.yaml
      - redis-service.yaml
      - ingress.yaml
    EOF
    
    kubectl apply -k deploy
    
    sleep 20s
    kubectl get ingress kube-ops-view-ingress | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }' 
    ```
  
### Install with NLB
* [AWS load balancer controller](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/aws-load-balancer-controller.html) 설치 필수
* subnet에 관련 tag가 설정되어 있어야 함 ([VPC 및 Subnet 요구사항](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/network_reqs.html))
* service를 NLB로 노출
* kube-ops-view-nlb.sh
    ```shell
    #!/bin/bash
    
    # shellcheck disable=SC2164
    cd ~/environment
    git clone https://codeberg.org/hjacobs/kube-ops-view.git
    cd kube-ops-view
    
    cat << EOF > deploy/service.yaml
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        application: kube-ops-view
        component: frontend
      name: kube-ops-view
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: external
        service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
    spec:
      selector:
        application: kube-ops-view
        component: frontend
      type: LoadBalancer
      ports:
        - port: 80
          protocol: TCP
          targetPort: 8080
    EOF
    
    # built-in kustomization command with -k
    kubectl apply -k deploy
    
    sleep 20s
    kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'
    ```

