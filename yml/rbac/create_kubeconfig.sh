#!/bin/bash
set -e
[ "$#" -ne 1 ] && echo "ERROR:Please Usage:bash $(basename $0) devops(devops表示使用kubeconfig的用户)" && exit 1
USER_NAME=$1
CA_CERT_PATH="/etc/kubernetes/pki"
MASTER_URL="https://192.168.1.10:6443"
CERT_PATH="/opt/cert"

[ ! -d "${CA_CERT_PATH}" ] && echo "ERROR:${CA_CERT_PATH}不存在!!!" && exit 1
if [ ! -f "${CERT_PATH}"/"${USER_NAME}"-key.pem -o ! -f "${CERT_PATH}"/"${USER_NAME}".pem ];then
    echo "ERROR:${CERT_PATH}下没有对应的证书和私钥" && exit 1
fi

kubectl config set-cluster kubernetes \
  --certificate-authority=${CA_CERT_PATH}/ca.crt \
  --embed-certs=true \
  --server=${MASTER_URL} \
  --kubeconfig=${CERT_PATH}/${USER_NAME}.kubeconfig
 
# 设置客户端认证
kubectl config set-credentials ${USER_NAME} \
  --client-key=${CERT_PATH}/${USER_NAME}-key.pem \
  --client-certificate=${CERT_PATH}/${USER_NAME}.pem \
  --embed-certs=true \
  --kubeconfig=${CERT_PATH}/${USER_NAME}.kubeconfig

# 设置默认上下文
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=${USER_NAME} \
  --kubeconfig=${CERT_PATH}/${USER_NAME}.kubeconfig

# 设置当前使用配置
kubectl config use-context kubernetes --kubeconfig=${CERT_PATH}/${USER_NAME}.kubeconfig

echo "INFO:${USER_NAME}用户的kubeconfig文件路径为${CERT_PATH}/${USER_NAME}.kubeconfig"
set +e

