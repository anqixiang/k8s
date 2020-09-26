#设置节点IP
k8smaster=192.168.1.10
k8snode1=192.168.1.11

#部署集群的用户
USERNAME=root

#工作目录,选磁盘空间最大的分区
DATA_DIR=/data
#docker版本
DOCKER_VERSION="docker-ce-18.06.3.ce-3.el7"
#k8s版本
K8S_VERSION=1.16.2

#为1代表在线部署，为0代表离线部署
NET_FLAG=0
