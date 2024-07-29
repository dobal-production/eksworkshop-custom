## Kube Opes View Install
<img style="float: left" src="./images/kube-ops-view-clb.png">  

* pod/node의 변화를 쉽게 보여줌, 교육시 효과적이나 운영에서는 다른 툴들을 권장
* [How to install](./05.kube-ops-view/README.md)

## Switch cluster context
```
kubectl config get-contexts
kubectl config use-context [context_name]
kubectl config delete-context [context_name]
```
