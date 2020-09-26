#!/bin/bash

set -e
cecho(){
    echo -e "\033[$1m$2\033[0m"
}

[ $# -ne 1 ] && cecho 31 "Invalid para" && exit 1
IMAGE_PATH=$1

cd ${IMAGE_PATH}
for image in $(ls ./*.tar)
do
	docker load -i ${image}
done
set +e
