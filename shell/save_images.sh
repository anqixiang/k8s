#!/bin/bash

set -e
cecho(){
    echo -e "\033[$1m$2\033[0m"
}

[ $# -ne 2 ] && cecho 31 "Invalid para" && exit 1
IMAGE_PATH=$1
K8S_VERSION=$2
[ ! -d ${IMAGE_PATH}/images ] && mkdir -pv ${IMAGE_PATH}/images
cd ${IMAGE_PATH}/images
docker save registry.aliyuncs.com/google_containers/pause:3.1 -o pause.tar
docker save registry.aliyuncs.com/google_containers/kube-proxy:v${K8S_VERSION} -o kube-proxy.tar
docker save quay.io/coreos/flannel:v0.11.0-amd64 -o flannel.tar
set +e
