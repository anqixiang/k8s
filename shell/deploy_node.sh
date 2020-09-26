#!/bin/bash

set -e
cecho(){
    echo -e "\033[$1m$2\033[0m"
}

[ $# -ne 4 ] && cecho 31 "Invalid para" && exit 1

k8s_master=$1
NODE_NAME=$2
YML_PATH=$3
TOKEN=$4

\cp ${YML_PATH}/join-config.yaml.module ${YML_PATH}/join-config.yaml
sed -ri "s#\{k8s_master\}#${k8s_master}#" ${YML_PATH}/join-config.yaml
sed -ri "s#\{NODE_NAME\}#${NODE_NAME}#" ${YML_PATH}/join-config.yaml
sed -ri "s#\{TOKEN\}#${TOKEN}#g" ${YML_PATH}/join-config.yaml

echo "######${NODE_NAME}加入集群......"
kubeadm join --config=${YML_PATH}/join-config.yaml
set +e
