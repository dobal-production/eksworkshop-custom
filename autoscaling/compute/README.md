## Cluster Autoscaler (CA)
### Scale with CA
* 클러스터의 사이즈를 자동으로 조정
  * 리소스가 부족하여 파드가 클러스터에 실행될 수 없을 때
  * 장시간 사용율이 낮은 노드가 있을 경우, 해당 노드의 파드들을 다른 노드로 배치
* CA는 AWS Auto Scaling Group과 연동
    ```
    aws autoscaling \
    describe-auto-scaling-groups \
    --query "AutoScalingGroups[? Tags[? (Key=='eks:cluster-name') && Value=='eks-workshop']].[AutoScalingGroupName, MinSize, MaxSize,DesiredCapacity]" \
    --output table
    ```
* Cluster가 증가하는 것은 콘솔에서도 확인 가능

### Cluster Over-Provisioning
* AWS의 ASG와 연동기 되기 때문에 노드가 증가하는데 시간이 다소 걸릴 수 있음
* 우선 순위가 낮은 빈 파드를 이용하여 오버프로비저닝
* 빈 파드는 우선순위가 낮으며 중요한 애플리케이션 파드가 배포될 때 제거
* 빈 파드는 CPU 및 메모리 리소스뿐만 아니라 AWS VPC 컨테이너 네트워크 인터페이스(CNI)에서 할당된 IP 주소도 할당

### PriorityClass
* [PriorityClass](https://kubernetes.io/ko/docs/concepts/scheduling-eviction/pod-priority-preemption/)는 파드의 우선순위를 할당하는 리소스
* `value` : 1 부터 10억 사이의 값
* 값이 클 수록 우선순위가 높음
* 파드 스펙에 `priorityClassName` 기재
* 클러스터의 리소스가 부족할 경우, 우선순위가 낮은 쩌리 파드들이 축출(eviction)됨
* `priorityClassName`이 없는 파드의 경우 0

### How it works
* 우선순위 값이 -1인 빈 "Pause" 컨테이너 파드를 생성 (cpu, memory가 기재되어야 함)
* priority class를 지정하지 않을 경우, 0
* 신규 워크로드를 추가할 경우, 0인 파드들이 생성이 되면서 기존의 -1인 빈 파드들이 축출됨
* 노드의 생성을 기다리지 않고도 빠르게 전개 가능
* 축출된 더미 파드는 `Pending`상태가 되고, ASG가 연쇄적으로 동작하여 노드도 늘어남