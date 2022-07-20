

## 一、基于二进制包安装部署生产级别Kubernetes集群
#### 1、环境规划：
|ID  |服务器IP    |主机名           |系统版本            |
|:-: |:-:         |:-:              |:-:                 |
|1   |10.0.0.181  |master-1,etcd-1  |Ubuntu 18.04.6 LTS  |
|2   |10.0.0.182  |master-2,etcd-2  |Ubuntu 18.04.6 LTS  |
|3   |10.0.0.183  |master-3,etcd-3  |Ubuntu 18.04.6 LTS  |
|4   |10.0.0.184  |node-1           |Ubuntu 18.04.6 LTS  |
|5   |10.0.0.185  |node-2           |Ubuntu 18.04.6 LTS  | 
|6   |10.0.0.186  |node-3           |Ubuntu 18.04.6 LTS  |

#### 2、软件包及相关信息：
```shell
k8s-v1.23.9/pkgs/k8s-etcd-3.4.18+bionic_amd64.deb                 # 持久状态存储etcd
k8s-v1.23.9/pkgs/k8s-kubernetes-master-1.23.9+bionic_amd64.deb    # master核心组件(kube-apiserver、kube-controller-manager、kube-scheduler)
k8s-v1.23.9/pkgs/k8s-kubernetes-node-1.23.9+bionic_amd64.deb      # node核心组件(kubelet、kube-proxy)
k8s-v1.23.9/pkgs/k8s-slb-1.16.1+bionic_amd64.deb                  # nginx四层代理，部署在node之上，作为kubelet、kube-proxy的代理访问kube-apiserver
k8s-v1.23.9/calico-v3.22.3                                        # 网络插件calico
k8s-v1.23.9/coredns-v1.8.6                                        # 服务发现coredns
k8s-v1.23.9/dashboard-v2.5.1                                      # 集群可视化dashboard
k8s-v1.23.9/docker-ce-v20.10.12                                   # 容器服务docker
k8s-v1.23.9/metrics-server-v0.6.1                                 # 核心指标监控metrics-server


注意：
k8s-etcd、k8s-kubernetes-master、k8s-kubernetes-node包中二进制程序由官方下载，此处仅做了二次封装，k8s-slb由nginx-1.16.1.tar.gz源码编译，未更改过任何源代码：
https://dl.k8s.io/v1.23.9/kubernetes-server-linux-amd64.tar.gz
https://dl.k8s.io/v1.23.9/kubernetes-client-linux-amd64.tar.gz
https://dl.k8s.io/v1.23.9/kubernetes-node-linux-amd64.tar.gz
https://nginx.org/download/nginx-1.16.1.tar.gz
https://github.com/etcd-io/etcd/releases/download/v3.4.18/etcd-v3.4.18-linux-amd64.tar.gz
```

#### 3、软件包下载地址：
https://pan.baidu.com

#### 4、基础环境配置(略)：
- 配置时间同步
- 配置master-1到master-2、master-3免密登录
- 关闭unattended-upgrades.service自动更新服务
- 提前安装部署Harbor(当前Harbor使用：hub.speech.local)
- 添加各节点dns解析或调整本地host文件：
```shell
root@master-1:~# vi /etc/hosts
10.0.0.181      master-1 etcd-1
10.0.0.182      master-2 etcd-2
10.0.0.183      master-3 etcd-3
10.0.0.184      node-1
10.0.0.185      node-2
10.0.0.186      node-3
```
- 安装配置Docker(各个节点都需要)：
```shell
root@master-1:~# tar zxf k8s-v1.23.9.tar.gz
root@master-1:~# cd k8s-v1.23.9/docker-ce-v20.10.12/
root@master-1:~/k8s-v1.23.9/docker-ce-v20.10.12# dpkg -i *.deb
root@master-1:~/k8s-v1.23.9/docker-ce-v20.10.12# vi /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "insecure-registries": ["hub.speech.local"]
}
root@master-1:~/k8s-v1.23.9/docker-ce-v20.10.12# systemctl restart docker
```


## 二、部署etcd集群
#### 1、分别在master-1、master-2、master-3中安装etcd：
```shell
root@master-1:~# ls
k8s-v1.23.9.tar.gz
root@master-1:~# tar zxf k8s-v1.23.9.tar.gz 
root@master-1:~# cd k8s-v1.23.9/pkgs/
root@master-1:~/k8s-v1.23.9/pkgs# dpkg -i k8s-etcd-3.4.18+bionic_amd64.deb 
Selecting previously unselected package k8s-etcd.
(Reading database ... 66889 files and directories currently installed.)
Preparing to unpack k8s-etcd-3.4.18+bionic_amd64.deb ...
Unpacking k8s-etcd (3.4.18+bionic) ...
Setting up k8s-etcd (3.4.18+bionic) ...
```


