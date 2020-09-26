#!/bin/bash

set -e
cecho(){
    echo -e "\033[$1m$2\033[0m"
}

[ $# -ne 2 ] && cecho 31 "Invalid para" && exit 1
DATA_DIR=$1				#docker存储路径
DOCKER_VERSION=$2		#docker版本

#安装docker,存在先卸载
if ! which docker &>/dev/null;then
	yum install ${DOCKER_VERSION} -y
	systemctl enable docker && systemctl start docker
fi
docker -v

#配置镜像加速器和docker存储路径
cat > /etc/docker/daemon.json << EOF
{
    "registry-mirrors": ["https://registry.docker-cn.com"],
	"graph":"${DATA_DIR}/docker"
}
EOF
systemctl daemon-reload
systemctl restart docker
set +e
