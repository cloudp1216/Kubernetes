#!/bin/bash


path=$(cd `dirname $0`; pwd)


if [ ! -f $path/env ]; then
    echo "Not exists 'env' file."
    exit 1
fi


source $path/env


yaml="${SA}-ns.yaml"
function init_ns() {
cat > $path/$yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NS
EOF
}


if [ ! -f $path/$yaml ]; then
    init_ns
    echo "Init file '$yaml' ok."

    echo "Apply to cluster, execute 'kubectl apply -f $yaml' command ?"
    read -a isExec -p "[y|n]: "
    if [ $isExec == "y" ]; then
	kubectl apply -f $yaml
    fi
else
    echo "File '$yaml' exists."
fi


