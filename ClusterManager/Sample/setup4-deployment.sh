#!/bin/bash


path=$(cd `dirname $0`; pwd)


if [ ! -f $path/env ]; then
    echo "Not exists 'env' file."
    exit 1
fi


source $path/env


yaml="deployment.yaml"
function init_deployment() {
cat > $path/${yaml}.base <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SA
  namespace: $NS
spec:
  replicas: 1
  selector:
    matchLabels:
      podID: "1"
  template:
    metadata:
      labels:
        podID: "1"
    spec:
      #nodeSelector:
      #  kubernetes.io/hostname: nodex
      ## OR
      #affinity:
      #  nodeAffinity:
      #    requiredDuringSchedulingIgnoredDuringExecution:
      #      nodeSelectorTerms:
      #      - matchExpressions:
      #        - key: "GPU.Model.NVIDIA-A10"
      #          operator: Exists
      containers:
      - name: $SA
        securityContext:
          # WARNING: privileged must disable (value: false)
          privileged: false
          # User UID
          runAsUser: 5000
          # User GID
          runAsGroup: 5000
        image: hub.speech.local/pytorch/pytorch:1.12.0-cuda11.3-cudnn8-runtime
        command:
        - sleep
        - infinity
        #env:
        #- name: NVIDIA_VISIBLE_DEVICES
        #  value: all
        resources:
          limits:
            nvidia.com/gpu: 1
        #ports:
        #- name: nginx
        #  containerPort: 80
        #volumeMounts:
        #- name: shm
        #  mountPath: /dev/shm
        #- name: cds
        #  mountPath: /$SA/cds
      #volumes:
      #- name: shm
      #  emptyDir:
      #    medium: Memory
      #    sizeLimit: 16Gi
      #- name: cds
      #  hostPath:
      #    path: /gpfs/home/$SA/cds
      #  name: data
      #  nfs: 
      #    server: x.x.x.x
      #    path: /export/dir
#---
#apiVersion: v1
#kind: Service
#metadata:
#  name: $SA
#  namespace: $NS
#spec:
#  type: NodePort
#  ports:
#  - port: 8080
#    targetPort: 8080
#    protocol: TCP
#  selector:
#    podID: "1"
EOF
}


if [ ! -f $path/${yaml}.base ]; then
    init_deployment
    if [ ! -f $path/$yaml ]; then
        cp $path/${yaml}.base $path/$yaml
        echo "Please modify the user '$yaml' file and create pods."
    else
        echo "File '${yaml}' exists."
    fi
else
    echo "File '${yaml}.base' exists."
fi


