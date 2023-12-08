#!/bin/bash

cd ~/environment/efs
kubectl delete -f efs-reader.yaml
kubectl delete -f efs-writer.yaml
kubectl delete -f efs-pvc.yaml

kubectl delete ds efs-csi-node -n kube-system

FILE_SYSTEM_ID=$(aws efs describe-file-systems | jq --raw-output '.FileSystems[].FileSystemId')
targets=$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID | jq --raw-output '.MountTargets[].MountTargetId')
for target in ${targets[@]}
do
    echo "deleting mount target " $target
    aws efs delete-mount-target --mount-target-id $target
done

sleep 2m
aws efs describe-file-systems --file-system-id $FILE_SYSTEM_ID
aws efs delete-file-system --file-system-id $FILE_SYSTEM_ID
aws ec2 delete-security-group --group-id $MOUNT_TARGET_GROUP_ID

kubectl delete -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable?ref=release-1.3"
