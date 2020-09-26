#!/bin/bash

set -e
cecho(){
    echo -e "\033[$1m$2\033[0m"
}

[ $# -ne 4 ] && cecho 31 "Invalid para" && exit 1
k8s_master=$1
K8S_VERSION=$2
YML_PATH=$3
NET_FLAG=$4

if [ ${NET_FLAG} -eq 1 ];then
	echo "######拉取镜像......"
	kubeadm config images pull --config=${YML_PATH}/init.config.yaml
fi

echo "######安装Master......"
kubeadm init \
--apiserver-advertise-address=${k8s_master} \
--image-repository registry.aliyuncs.com/google_containers \
--kubernetes-version v${K8S_VERSION} \
--service-cidr=10.1.0.0/16 \
--pod-network-cidr=10.244.0.0/16

echo "######使kubectl命令可以正常使用......"
mkdir -p $HOME/.kube
\cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubectl version
set +e
