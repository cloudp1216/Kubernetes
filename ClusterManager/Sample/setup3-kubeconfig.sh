#!/bin/bash


path=$(cd `dirname $0`; pwd)


if [ ! -f $path/env ]; then
    echo "Not exists 'env' file."
    exit 1
fi


source $path/env


config="${SA}.kubeconfig"
function init_kubeconfig() {
    SecretName=$(kubectl get sa/${SA} -n ${NS} -o jsonpath="{.secrets[0].name}")
    Token=$(kubectl get secret/${SecretName} -n ${NS} -o go-template="{{.data.token | base64decode}}")

    kubectl config set-cluster kubernetes \
        --certificate-authority=/k8s/kubernetes/ssl/ca.pem \
        --embed-certs=true \
        --server=${ApiServer} \
        --kubeconfig=${config}

    kubectl config set-credentials ${SA} \
        --token=${Token} \
        --kubeconfig=${SA}.kubeconfig

    kubectl config set-context ${SA}@kubernetes \
        --cluster=kubernetes \
        --user=${SA} \
        --kubeconfig=${config}

    kubectl config use-context ${SA}@kubernetes \
        --kubeconfig=${config}
}


if [ ! -f $path/$config ]; then
    init_kubeconfig
    echo "Please distribute this file '${config}' to user."
else
    echo "File '${config}' exists."
fi


