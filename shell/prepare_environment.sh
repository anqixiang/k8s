#!/bin/bash

set -e
cecho(){
	echo -e "\033[$1m$2\033[0m"
}

echo $#
[ $# -ne 3 ] && cecho 31 "没有参数" && exit 1
hostname=$1
REPO_PATH=$2
NET_FLAG=$3
#设置主机名
Set_Hostname(){
    cecho 32 "############设置主机名......"
	hostnamectl set-hostname ${hostname}
	hostnamectl
}

#关闭防火墙，禁用selinux
Security_Conf(){
   cecho 32 "############关闭防火墙，禁用selinux......"
   systemctl disable firewalld  &>/dev/null
   systemctl stop firewalld &>/dev/null
   local selinux_mode=$(grep '^SELINUX=' /etc/selinux/config |awk -F'=' '{print $2}')
   if [ ${selinux_mode} != "disabled" ];then
      setenforce 0
      sed -i '/^SELINUX=/c SELINUX=disabled' /etc/selinux/config
      cecho 92 "selinux需重启系统才能生效"
   fi
}

#关闭swap
Close_Swap(){
    cecho 32 "############关闭swap......"
	swapoff -a
	sed -i 's/.*swap.*/#&/' /etc/fstab	
	free -h
}

#开启路由转发
Open_Router(){
    cecho 32 "############开启路由转发......"
	cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system
}

#配置yum源
Config_Yum(){
    cecho 32 "############配置yum源......"
	[ ! -d /etc/yum.repos.d/repo ] && mkdir /etc/yum.repos.d/repo
	\mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repo
	if [ ${NET_FLAG} -eq 1 ];then
		cp ${REPO_PATH}/{CentOS-Base.repo,docker-ce.repo,kubernetes.repo} /etc/yum.repos.d/
	else
    	cp ${REPO_PATH}/local.repo /etc/yum.repos.d/ 
	fi
	yum makecache &> /dev/null
	yum clean all
    local yum_num=$(yum repolist |grep '^repolist' |awk '{print $2}' |sed 's/,//')
	if [ ${yum_num} -ge 20 ];then
		cecho 96 "yum源可用"
    else
		cecho 31 "yum源不可用,crtl+c退出安装脚本" && sleep 1800
	fi
}
######################主函数######################
Set_Hostname
Security_Conf
Close_Swap
Open_Router
Config_Yum
set +e
