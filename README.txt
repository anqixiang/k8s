#注意事项

1.只支持root用户安装
2.所有节点的密码保持一致
3.默认为在线安装，在线安装需保证所有节点均可以访问外网,如果只有一个节点能访问外网，需把相关的镜像传到别的机器，
可以参考手动部署文档：https://blog.csdn.net/anqixiang/article/details/107715892
4.yum源不可用的超时时间为1800秒,需按crtl+c退出安装，待yum配置正确后再执行安装

#执行方式
./autoinstall.sh -c all
