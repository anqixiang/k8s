#!/bin/bash
#SCRIPYT:autoinstall.sh
#AUTHOR:nsd_anqixiang@163.com
#DATE:2020-08-09
#DESCRIBE:一键式部署k8s集群
#SYSTEM:CentOS7.5
#VERSION:1.0
#MODIFY:

WORKDIR=$(cd `dirname $0`;pwd)      #脚本所在路径
PROFILE_PATH=${WORKDIR}/profile
REPO_PATH=${WORKDIR}/repo
YML_PATH=${WORKDIR}/yml
source ${PROFILE_PATH}

######################profile######################
k8s_master=${k8smaster}
USERNAME=${USERNAME}
DATA_DIR=${DATA_DIR}
DOCKER_VERSION=${DOCKER_VERSION}
K8S_VERSION=${K8S_VERSION}
NET_FLAG=${NET_FLAG}			#为1代表在线部署，为0代表离线部署,默认为1
#提取所有节点的IP地址
all_ip=($(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' ${PROFILE_PATH}))
#提取node节点的IP
node_ip=($(grep 'node' ${PROFILE_PATH} |awk -F'=' '{print $2}')) 

######################功能函数######################
cecho(){
	echo -e "\033[$1m$2\033[0m"
}

#修改配置文件
Modify_Conf(){
	cecho 32 "############修改配置文件......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
	set -e
	\cp ${REPO_PATH}/config/local.repo.module ${REPO_PATH}/config/local.repo
	sed -ri "s#\{YUM_DIR\}#${DATA_DIR}/k8s/repo/yum#" ${REPO_PATH}/config/local.repo
	#修改kubeadm初始化文件
	\cp ${YML_PATH}/init.config.yaml.module ${YML_PATH}/init.config.yaml
	sed -ri "s#\{k8s_master\}#${k8s_master}#" ${YML_PATH}/init.config.yaml
	sed -ri "s#\{K8S_VERSION\}#${K8S_VERSION}#" ${YML_PATH}/init.config.yaml
	set +e
}

#配置免密ssh，并传包
Config_Ssh(){
	cecho 32 "############配置免密ssh，并传包......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
    read -sp "输入${USERNAME}密码": PASSWD
	for((i=0;i<${#all_ip[@]};i++))
	do
		bash shell/config_ssh.sh ${USERNAME} ${all_ip[i]} ${PASSWD}
		ssh ${USERNAME}@${all_ip[i]} -t -t "mkdir -pv ${DATA_DIR}/k8s"
		scp -r ${WORKDIR}/tools ${USERNAME}@${all_ip[i]}:${DATA_DIR}/k8s/
		ssh ${USERNAME}@${all_ip[i]} -t -t "rpm -ivh ${DATA_DIR}/k8s/tools/rsync-3.1.2-10.el7.x86_64.rpm"
	done

	rsync -avzP ${WORKDIR}/* ${USERNAME}@${k8s_master}:${DATA_DIR}/k8s/
	for((i=0;i<${#node_ip[@]};i++))
    do
        rsync -avzP ${WORKDIR}/* --exclude-from="${WORKDIR}/exclude.list" ${USERNAME}@${node_ip[i]}:${DATA_DIR}/k8s/
		rsync -avzP ${WORKDIR}/images/{flannel-v0.11.0.tar,kube-proxy-v1.16.2.tar,pause.tar,coredns-v1.6.2.tar} ${USERNAME}@${node_ip[i]}:${DATA_DIR}/k8s/images/
    done
	unset PASSWD
}

#检测网络
Check_Net(){
	cecho 32 "############检测网络......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
	if [ ${NET_FLAG} -eq 1 ];then
		for((i=0;i<${#all_ip[@]};i++))
		do
			ssh ${USERNAME}@${all_ip[i]} -t -t "curl -I www.baidu.com --connect-timeout 5 &>/dev/null"
			if [ $? -ne 0 ];then
				cecho 31 "${all_ip[i]}不能访问外网,按crtl+c退出安装" && sleep 1800
				exit 1
			fi
		done
		cecho 96 "网络正常"
	else
		cecho 36 "采用离线部署"
	fi	
}

#环境准备
Prepare_Env(){
	cecho 32 "############环境准备......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
	for((i=0;i<${#all_ip[@]};i++))
    do
		local hostname=$(grep "${all_ip[i]}" profile |awk -F'=' '{print $1}')	
        ssh ${USERNAME}@${all_ip[i]} -t -t "bash ${DATA_DIR}/k8s/shell/prepare_environment.sh ${hostname} ${DATA_DIR}/k8s/repo/config ${NET_FLAG}"
    done
}

#安装工具
Install_Tools(){
	cecho 32 "############安装工具......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
	for((i=0;i<${#all_ip[@]};i++))
    do
        ssh ${USERNAME}@${all_ip[i]} -t -t "bash ${DATA_DIR}/k8s/shell/install_docker.sh ${DATA_DIR} ${DOCKER_VERSION}"
		ssh ${USERNAME}@${all_ip[i]} -t -t "bash ${DATA_DIR}/k8s/shell/install_k8s_tool.sh ${K8S_VERSION}"
    done
}

#部署Master
Deploy_Master(){
	cecho 32 "############部署Master......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
	ssh ${USERNAME}@${k8s_master} -t -t "kubeadm reset -f"
	ssh ${USERNAME}@${k8s_master} -t -t	"bash ${DATA_DIR}/k8s/shell/load_images.sh ${DATA_DIR}/k8s/images"
	ssh ${USERNAME}@${k8s_master} -t -t "bash ${DATA_DIR}/k8s/shell/deploy_master.sh ${k8s_master} ${K8S_VERSION} ${DATA_DIR}/k8s/yml ${NET_FLAG}"
}

#将node加入集群
Join_Node(){
	cecho 32 "############将node加入集群......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
	local token=$(ssh ${k8s_master} -t -t "kubeadm token list" |grep 'kubeadm init' |awk '{print $1}')
	for((i=0;i<${#node_ip[@]};i++))
    do
		ssh ${USERNAME}@${node_ip[i]} -t -t "kubeadm reset -f"
		local node_name=$(grep "${node_ip[i]}" ${PROFILE_PATH} |awk -F'=' '{print $1}')
		ssh ${USERNAME}@${node_ip[i]} -t -t "bash ${DATA_DIR}/k8s/shell/deploy_node.sh ${k8s_master} ${node_name} ${DATA_DIR}/k8s/yml ${token}"
    done
	ssh ${USERNAME}@${k8s_master} -t -t "kubectl get nodes"
}

#部署pod网络
Deploy_Pod_Netwrok(){
	cecho 32 "############部署pod网络......" && sleep 1
	echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
	#把proxy、flannel、pause镜像传到node节点上
	if [ ${NET_FLAG} -eq 0 ];then
		for((i=0;i<${#node_ip[@]};i++))
    	do
			ssh ${USERNAME}@${node_ip[i]} -t -t "docker load -i ${DATA_DIR}/k8s/images/flannel-v0.11.0.tar"
			ssh ${USERNAME}@${node_ip[i]} -t -t "docker load -i ${DATA_DIR}/k8s/images/kube-proxy-v1.16.2.tar"
			ssh ${USERNAME}@${node_ip[i]} -t -t "docker load -i ${DATA_DIR}/k8s/images/pause.tar"
    	done
	else
		ssh ${USERNAME}@${k8s_master} -t -t "docker pull quay.io/coreos/flannel:v0.11.0-amd64"
		#ssh ${USERNAME}@${k8s_master} -t -t "bash ${DATA_DIR}/k8s/shell/save_images.sh ${DATA_DIR}/k8s ${K8S_VERSION}"
	fi
	sleep 5
	ssh ${USERNAME}@${k8s_master} -t -t "kubectl apply -f ${DATA_DIR}/k8s/yml/kube-flannel.yml"
	ssh ${USERNAME}@${k8s_master} -t -t "kubectl get nodes && kubectl get pods -n kube-system"
	cecho 96 "k8s集群部署完毕，等待所有pod为Running状态"
}

#帮助信息
Help(){
	cat << EOF
Usage: 
=======================================================================
optional arguments:
	-h		提供帮助信息
	-all	一键式部署
	conf	修改配置文件
	ssh		ssh免密,传包
	cnet	检测网络
	pre		环境准备(配置主机名/关闭防火墙/配置yum源)
	tool	安装docker、kubeadm等
	master	部署master节点
	node	部署node节点
	net		部署pod网络
EXAMPLE:
	bash autoinstall.sh -c all
EOF
}
######################主函数######################
main(){
if [ "x$1" == "x-c" -a "$#" -eq 2 ];then
    case $2 in
    all)
		Modify_Conf 2>&1 | tee ${WORKDIR}/logs/modify_conf.log
		Config_Ssh 2>&1 | tee ${WORKDIR}/logs/config_ssh.log
		Check_Net 2>&1 | tee  ${WORKDIR}/logs/check_net.log
		Prepare_Env 2>&1 | tee  ${WORKDIR}/logs/prepare_env.log
		Install_Tools 2>&1 | tee  ${WORKDIR}/logs/install_tools.log
		Deploy_Master 2>&1 | tee  ${WORKDIR}/logs/deploy_master.log
		Join_Node 2>&1 | tee  ${WORKDIR}/logs/join_node.log
		Deploy_Pod_Netwrok 2>&1 | tee  ${WORKDIR}/logs/deploy_pod_network.log
        ;;
	conf)
		Modify_Conf 2>&1 | tee ${WORKDIR}/logs/modify_conf.log;;
	ssh)
		Config_Ssh 2>&1 | tee ${WORKDIR}/logs/config_ssh.log;;
	cnet)
		Check_Net 2>&1 | tee  ${WORKDIR}/logs/check_net.log;;
	pre)
		Prepare_Env 2>&1 | tee  ${WORKDIR}/logs/prepare_env.log;;
	tool)
		Install_Tools 2>&1 | tee  ${WORKDIR}/logs/install_tools.log;;
	master)
		Deploy_Master 2>&1 | tee  ${WORKDIR}/logs/deploy_master.log;;
	node)
		Join_Node 2>&1 | tee  ${WORKDIR}/logs/join_node.log;;
	net)
		Deploy_Pod_Netwrok 2>&1 | tee  ${WORKDIR}/logs/deploy_pod_network.log;;
    *)
        cecho 31 "Invalid option:bash `basename $0` [-h]"
    esac
elif [ "x$1" == "x-h" ];then
    Help
else
    Help && exit 1
fi
}
main $1 $2
