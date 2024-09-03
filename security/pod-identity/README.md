## Amazon EKS Pod Identity
* IRSA은 사용하지만, OIDC는 사용하지 않음
* Pod Identity Agent를 애드온으로 설치 필요
* 생성한 IAM Role의 신뢰 관계 정책에 `pods.eks.amazonaws.com`을 보안주체로 등록
* IAM Role과 Service Account 연결이 더 쉬워짐

### Intruduction
```shell
# Sample application
kubectl -n ui get service ui-nlb -o jsonpath='http://{.status.loadBalancer.ingress[*].hostname}{"\n"}'
```

```shell
echo $CARTS_DYNAMODB_TABLENAME
kubectl kustomize ~/environment/eks-workshop/modules/security/eks-pod-identity/dynamo \
  | envsubst | kubectl apply -f-

kubectl -n carts get cm carts -o yaml

kubectl -n carts rollout restart deployment/carts
kubectl -n carts rollout status deployment/carts

kubectl -n carts get pod
```
### Using EKS Pod Identity
```shell
# EKS Pod Identity Agent 애드온 설치
aws eks create-addon --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent
aws eks wait addon-active --cluster-name $EKS_CLUSTER_NAME --addon-name eks-pod-identity-agent

kubectl -n kube-system get daemonset eks-pod-identity-agent
kubectl -n kube-system get pods -l app.kubernetes.io/name=eks-pod-identity-agent
```
```shell
# carts 서비스에서 사용하는 DynamoDB 권한을 가지는 정책
aws iam get-policy-version \
  --version-id v1 --policy-arn \
  --query 'PolicyVersion.Document' \
  arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EKS_CLUSTER_NAME}-carts-dynamo | jq .

# Pod를 위한 IAM Role
aws iam get-role \
  --query 'Role.AssumeRolePolicyDocument' \
  --role-name ${EKS_CLUSTER_NAME}-carts-dynamo | jq .
```
```shell
# 해당 IAM Role을 carts service account에 연결
aws eks create-pod-identity-association --cluster-name ${EKS_CLUSTER_NAME} \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/${EKS_CLUSTER_NAME}-carts-dynamo \
  --namespace carts --service-account carts
  
# carts 재배포
kubectl -n carts rollout restart deployment/carts
kubectl -n carts rollout status deployment/carts
```

### Verifying DynamoDB Access
```shell
# ui service의 nlb 가져오기
kubectl -n ui get service ui-nlb -o jsonpath='http://{.status.loadBalancer.ingress[*].hostname}{"\n"}'
```
