yum remove docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
    docker-engine-selinux docker-engine -y
    rm -rf /etc/docker
    rm -rf /run/docker
    rm -rf /var/run/docker
    rm -rf /var/lib/dockershim
    rm -rf /var/lib/docker


ifconfig cni0 down    
ip link delete cni0
