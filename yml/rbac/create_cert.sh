#!/bin/bash
set -e
[ "$#" -ne 1 ] && echo "ERROR:Please Usage:bash $(basename $0) devops(devops表示使用证书的用户)" && exit 1
USER_NAME=$1
CA_CERT_PATH="/etc/kubernetes/pki"
CERT_PATH="/opt/cert"

[ ! -d "${CA_CERT_PATH}" ] && echo "ERROR:${CA_CERT_PATH}不存在!!!" && exit 1
[ ! -d "${CERT_PATH}" ] && mkdir ${CERT_PATH}

cd ${CERT_PATH}
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF

cat > ${USER_NAME}-csr.json <<EOF
{
  "CN": "${USER_NAME}",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca="${CA_CERT_PATH}"/ca.crt -ca-key="${CA_CERT_PATH}"/ca.key -config=ca-config.json -profile=kubernetes ${USER_NAME}-csr.json | cfssljson -bare ${USER_NAME}
echo "INFO:证书路径为${CERT_PATH}"
set +e
