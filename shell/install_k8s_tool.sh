#!/bin/bash

set -e
cecho(){
    echo -e "\033[$1m$2\033[0m"
}

[ $# -ne 1 ] && cecho 31 "Invalid para" && exit 1
K8S_VERSION=$1

yum install kubelet-${K8S_VERSION} kubeadm-${K8S_VERSION} kubectl-${K8S_VERSION} --disableexcludes=kubernetes -y
systemctl enable kubelet && systemctl start kubelet
set +e
