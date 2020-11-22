#!/bin/bash
# vim:sw=4:ts=4:et

set -e
TEMP_DIR="/tmp/ssl"

if [ ! -d "${TEMP_DIR}" ];then
    mkdir ${TEMP_DIR}
else
    echo "ERROR:${TEMP_DIR}已存在,请更换目录!!!" && exit 1
fi

cd ${TEMP_DIR}
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64  -O cfssl
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O cfssljson
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O cfssl-certinfo
chmod +x ./cfssl*
mv ./cfssl* /usr/local/bin/
[ -d "${TEMP_DIR}" ] && rm -rf ${TEMP_DIR}
if cfssl version;then
    echo "INFO:Install Success!"
else
    echo "ERROR:Install Fail!!!" && exit 1
fi
set +e
