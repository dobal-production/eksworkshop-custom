# Compute
## Overview 
### 기본 기능
- EKS가 컴퓨팅 리소스를 자동으로 프로비저닝하고 관리
- EC2 인스턴스 생성 및 EKS 클러스터에 노드로 자동 연결
- 워크로드가 기존 노드에서 실행될 수 없을 때 적절한 크기의 새 EC2 인스턴스를 자동 생성

### 관리형 인스턴스 특징
- EC2 관리형 인스턴스로 운영됨
- 운영 제어를 서비스 제공자(EKS)에게 위임
- AWS의 운영 전문성과 모범 사례 활용 가능

### 관리 범위
- 인스턴스 프로비저닝
- 소프트웨어 구성 
- 용량 조정
- 인스턴스 장애 및 교체 처리
- AWS 콘솔에서 인스턴스 모니터링 가능
- 임시 스토리지로 인스턴스 스토리지 사용 가능

## EKS Auto Mode 설정
| 구성                     | 설명 |
|--------------------------|------|
| **주요 구성 요소**       | <ul><li>Karpenter 객체 기반 동작</li><li>NodeClass와 NodePools 사양 사용</li></ul> |
| **NodeClass 사양**       | <ul><li>인프라 수준 설정 정의</li><li>네트워크 구성, 스토리지 설정, 리소스 태깅 등</li></ul> |
| **NodePool 사양**        | <ul><li>세부적인 컴퓨팅 리소스 제어</li><li>EC2 인스턴스 카테고리, CPU 구성, 가용영역, 아키텍처(ARM64/AMD64), 용량 유형(스팟/온디맨드)  등</li></ul> |
| **기본 관리형 NodePool** | <ul><li><b>일반 용도(general-purpose)</b> : 사용자 배포 애플리케이션 및 서비스 처리</li><li><b>시스템(system)</b> : 클러스터 운영을 위한 핵심 시스템 구성 요소 전용</li></ul> |


```shell
kubectl get nodes -l karpenter.sh/nodepool=general-purpose
```
<img src="../../images/automode-10.png" />