## Karpenter
* Kubernetes 클러스터에서 사용할 수 있는 오픈소스 오토스케일링 기능
* CA가 분 단위의 시간이 걸린 것과 달리 수 초만에 스케일링 쌉가능
* ASG의 인스턴스, EKS Cluster의 노드간 싱크 과정에서 문제가 발생할 수 있음
  * 수동으로 노드를 삭제려면, ASG 인스턴스도 수동으로 삭제해주어야 함
  * 특정 노드를 삭제하면서 동시에 노드 개수를 줄이기 어려움
  * ASG의 메커니즘은 오래된 놈 또는 어린 놈 순으로 삭제
  * 파드가 적은 노드가 항상 오래된 인스턴스 또는 어린 인스턴스가 아님 --> 문제 발생
  * 스케쥴링이 안된 파드가 발생되어도, ASG 인터벌까지는 기다려야 함 --> 빠른 스케일 인/아웃에 한계

![Karpenter](images/karpenter-1.png)
* 스케쥴링이 안된 파드가 발생하면(event 발생) 즉시 반응
* 파드가 어떤 노드에 할당되어야 할지를 평가 후에 배치
* 비어있는 노드가 발견되면 제거
* 시작 템플릿이 필요 없음
* 보안그룹과 서브넷은 필수
* 참조 : [Karpenter Doc](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/#4-install-karpenter)