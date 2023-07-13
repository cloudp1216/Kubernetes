#!/bin/bash


path=$(cd `dirname $0`; pwd)


if [ ! -f $path/env ]; then
    echo "Not exists 'env' file."
    exit 1
fi


source $path/env


yaml="${SA}-rbac.yaml"
function init_rbac() {
cat > $path/$yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: $SA
  namespace: $NS
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: $SA
  namespace: $NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: users-view
subjects:
- kind: ServiceAccount
  name: $SA
  namespace: $NS
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $SA
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: nodes-view
subjects:
- kind: ServiceAccount
  name: $SA
  namespace: $NS
EOF
}


if [ ! -f $path/$yaml ]; then
    init_rbac
    echo "Init file '$yaml' ok."

    echo "Apply to cluster, execute 'kubectl apply -f $yaml' command ?"
    read -a isExec -p "[y|n]: "
    if [ $isExec == "y" ]; then
	kubectl apply -f $yaml
    fi
else
    echo "File '$yaml' exists."
fi


