

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
k8s-v1.23.9/pkgs/k8s-kubernetes-master-1.23.9+bionic_amd64.deb    # master核心组件（kube-apiserver、kube-controller-manager、kube-scheduler）
k8s-v1.23.9/pkgs/k8s-kubernetes-node-1.23.9+bionic_amd64.deb      # node核心组件（kubelet、kube-proxy）
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
链接: https://pan.baidu.com/s/1i1KOWIPpgS2qfGloXkXaBw </p>
提取码: 64uk 


#### 4、基础环境配置：
- 配置时间同步
- 配置master-1到master-2、master-3免密登录
- 关闭unattended-upgrades.service自动更新服务
- 提前安装部署Harbor（当前Harbor域名解析为：hub.speech.local）
- 添加各节点DNS解析或调整本地hosts文件：
```shell
root@master-1:~# vi /etc/hosts
10.0.0.181      master-1 etcd-1
10.0.0.182      master-2 etcd-2
10.0.0.183      master-3 etcd-3
10.0.0.184      node-1
10.0.0.185      node-2
10.0.0.186      node-3
```
- 安装配置Docker（各个节点都需要）：
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
#### 1、分别在etcd-1、etcd-2、etcd-3节点安装k8s-etcd-3.4.18+bionic_amd64.deb组件：
```shell
root@master-1:~# cd k8s-v1.23.9/pkgs/
root@master-1:~/k8s-v1.23.9/pkgs# dpkg -i k8s-etcd-3.4.18+bionic_amd64.deb 
Selecting previously unselected package k8s-etcd.
(Reading database ... 66889 files and directories currently installed.)
Preparing to unpack k8s-etcd-3.4.18+bionic_amd64.deb ...
Unpacking k8s-etcd (3.4.18+bionic) ...
Setting up k8s-etcd (3.4.18+bionic) ...
```
```shell
root@master-1:~/k8s-v1.23.9/pkgs# scp k8s-etcd-3.4.18+bionic_amd64.deb root@10.0.0.182:/root
root@master-1:~/k8s-v1.23.9/pkgs# scp k8s-etcd-3.4.18+bionic_amd64.deb root@10.0.0.183:/root
root@master-1:~/k8s-v1.23.9/pkgs# ssh root@10.0.0.182 'cd /root && dpkg -i k8s-etcd-3.4.18+bionic_amd64.deb'
root@master-1:~/k8s-v1.23.9/pkgs# ssh root@10.0.0.183 'cd /root && dpkg -i k8s-etcd-3.4.18+bionic_amd64.deb'
```

#### 2、在etcd-1节点初始化etcd证书（注意双下滑线开头结尾项需要调整）：
```shell
root@master-1:~# cd /k8s/etcd/ssl/cfssl-tools
root@master-1:/k8s/etcd/ssl/cfssl-tools# vi etcd-csr.json
{
    "CN": "etcd",
    "hosts": [
        "10.0.0.181",
        "10.0.0.182",
        "10.0.0.183",
        "127.0.0.1",
        "localhost"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "etcd",
            "OU": "System"
        }
    ]
}
root@master-1:/k8s/etcd/ssl/cfssl-tools# vi peer-csr.json
{
    "CN": "peer",
    "hosts": [
        "10.0.0.181",
        "10.0.0.182",
        "10.0.0.183",
        "127.0.0.1",
        "localhost"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "etcd",
            "OU": "System"
        }
    ]
}
root@master-1:/k8s/etcd/ssl/cfssl-tools# ./init-certs.sh 
Init Etcd Certs OK.
root@master-1:/k8s/etcd/ssl/cfssl-tools# ls -lh ../
total 40K
-rw-r--r-- 1 root root 1.1K Jul 20 14:11 ca.csr
-rw------- 1 root root 1.7K Jul 20 14:11 ca-key.pem
-rw-r--r-- 1 root root 1.3K Jul 20 14:11 ca.pem
drwxr-xr-x 2 root root 4.0K Jul 20 14:11 cfssl-tools
-rw-r--r-- 1 root root 1.1K Jul 20 14:11 etcd.csr
-rw------- 1 root root 1.7K Jul 20 14:11 etcd-key.pem
-rw-r--r-- 1 root root 1.4K Jul 20 14:11 etcd.pem
-rw-r--r-- 1 root root 1.1K Jul 20 14:11 peer.csr
-rw------- 1 root root 1.7K Jul 20 14:11 peer-key.pem
-rw-r--r-- 1 root root 1.5K Jul 20 14:11 peer.pem
```

#### 3、分发etcd证书到etcd-2、etcd-3节点：
```shell
root@master-1:/k8s/etcd# scp -r ssl root@10.0.0.182:/k8s/etcd
root@master-1:/k8s/etcd# scp -r ssl root@10.0.0.183:/k8s/etcd
```

#### 4、分别调整etcd-1、etcd-2、etcd-3配置文件：
```shell
root@master-1:~# cd /k8s/etcd/cfg/
root@master-1:/k8s/etcd/cfg# ln -svf etcd.cluster etcd    # 注意etcd默认为单实例配置，这里调整为集群配置
'etcd' -> 'etcd.cluster'
root@master-1:/k8s/etcd/cfg# vi etcd                      # 注意所有双下滑杠开头结尾的配置项都需要调整，ETCD_ARGS和ETCD_DATA_DIR变量值建议调整和节点一致
#[Member]
ETCD_ARGS="--name=etcd-1"
ETCD_DATA_DIR="/k8s/etcd/etcd-1.data"
ETCD_LISTEN_CLIENT_URLS="https://10.0.0.181:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://10.0.0.181:2379"


#[Clustering]
ETCD_LISTEN_PEER_URLS="https://10.0.0.181:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://10.0.0.181:2380"
ETCD_INITIAL_CLUSTER="etcd-1=https://10.0.0.181:2380,etcd-2=https://10.0.0.182:2380,etcd-3=https://10.0.0.183:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"


#[Security]
ETCD_AUTO_TLS="true"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_CERT_FILE="/k8s/etcd/ssl/etcd.pem"
ETCD_KEY_FILE="/k8s/etcd/ssl/etcd-key.pem"
ETCD_PEER_AUTO_TLS="true"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_PEER_CERT_FILE="/k8s/etcd/ssl/peer.pem"
ETCD_PEER_KEY_FILE="/k8s/etcd/ssl/peer-key.pem"
```

```shell
root@master-2:~# cd /k8s/etcd/cfg/
root@master-2:/k8s/etcd/cfg# ln -svf etcd.cluster etcd
'etcd' -> 'etcd.cluster'
root@master-2:/k8s/etcd/cfg# vi etcd
#[Member]
ETCD_ARGS="--name=etcd-2"
ETCD_DATA_DIR="/k8s/etcd/etcd-2.data"
ETCD_LISTEN_CLIENT_URLS="https://10.0.0.182:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://10.0.0.182:2379"


#[Clustering]
ETCD_LISTEN_PEER_URLS="https://10.0.0.182:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://10.0.0.182:2380"
ETCD_INITIAL_CLUSTER="etcd-1=https://10.0.0.181:2380,etcd-2=https://10.0.0.182:2380,etcd-3=https://10.0.0.183:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"


#[Security]
ETCD_AUTO_TLS="true"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_CERT_FILE="/k8s/etcd/ssl/etcd.pem"
ETCD_KEY_FILE="/k8s/etcd/ssl/etcd-key.pem"
ETCD_PEER_AUTO_TLS="true"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_PEER_CERT_FILE="/k8s/etcd/ssl/peer.pem"
ETCD_PEER_KEY_FILE="/k8s/etcd/ssl/peer-key.pem"
```

```shell
root@master-3:~# cd /k8s/etcd/cfg/
root@master-3:/k8s/etcd/cfg# ln -svf etcd.cluster etcd
'etcd' -> 'etcd.cluster'
root@master-3:/k8s/etcd/cfg# vi etcd
#[Member]
ETCD_ARGS="--name=etcd-3"
ETCD_DATA_DIR="/k8s/etcd/etcd-3.data"
ETCD_LISTEN_CLIENT_URLS="https://10.0.0.183:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://10.0.0.183:2379"


#[Clustering]
ETCD_LISTEN_PEER_URLS="https://10.0.0.183:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://10.0.0.183:2380"
ETCD_INITIAL_CLUSTER="etcd-1=https://10.0.0.181:2380,etcd-2=https://10.0.0.182:2380,etcd-3=https://10.0.0.183:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"


#[Security]
ETCD_AUTO_TLS="true"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_CERT_FILE="/k8s/etcd/ssl/etcd.pem"
ETCD_KEY_FILE="/k8s/etcd/ssl/etcd-key.pem"
ETCD_PEER_AUTO_TLS="true"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_PEER_CERT_FILE="/k8s/etcd/ssl/peer.pem"
ETCD_PEER_KEY_FILE="/k8s/etcd/ssl/peer-key.pem"
```

#### 5、分别在etcd-1、etcd-2、etcd-3节点启动etcd：
```shell
root@master-1:~# systemctl start etcd && systemctl enable etcd
root@master-1:~# ssh root@10.0.0.182 'systemctl start etcd && systemctl enable etcd'
root@master-1:~# ssh root@10.0.0.183 'systemctl start etcd && systemctl enable etcd'
```
```shell
root@master-1:~# ps -ef | grep -v grep | grep etcd
root      6371     1  2 14:50 ?        00:00:12 /k8s/etcd/bin/etcd --name=etcd-1
root@master-1:~# ssh root@10.0.0.182 'ps -ef | grep -v grep | grep etcd'
root      6115     1  2 14:50 ?        00:00:11 /k8s/etcd/bin/etcd --name=etcd-2
root@master-1:~# ssh root@10.0.0.183 'ps -ef | grep -v grep | grep etcd'
root      5824     1  2 14:50 ?        00:00:11 /k8s/etcd/bin/etcd --name=etcd-3
```


## 三、部署Kubernetes集群
#### 1、分别在master-1、master-2、master-3上安装k8s-kubernetes-master-1.23.9+bionic_amd64.deb与k8s-kubernetes-node-1.23.9+bionic_amd64.deb组件：
```shell
root@master-1:~# cd k8s-v1.23.9/pkgs/
root@master-1:~/k8s-v1.23.9/pkgs# dpkg -i k8s-kubernetes-master-1.23.9+bionic_amd64.deb k8s-kubernetes-node-1.23.9+bionic_amd64.deb 
Selecting previously unselected package k8s-kubernetes-master.
(Reading database ... 67136 files and directories currently installed.)
Preparing to unpack k8s-kubernetes-master-1.23.9+bionic_amd64.deb ...
Unpacking k8s-kubernetes-master (1.23.9+bionic) ...
Selecting previously unselected package k8s-kubernetes-node.
Preparing to unpack k8s-kubernetes-node-1.23.9+bionic_amd64.deb ...
Unpacking k8s-kubernetes-node (1.23.9+bionic) ...
Setting up k8s-kubernetes-master (1.23.9+bionic) ...
Setting up k8s-kubernetes-node (1.23.9+bionic) ...
```
```shell
root@master-1:~/k8s-v1.23.9/pkgs# scp k8s-kubernetes-master-1.23.9+bionic_amd64.deb k8s-kubernetes-node-1.23.9+bionic_amd64.deb root@10.0.0.182:/root
root@master-1:~/k8s-v1.23.9/pkgs# scp k8s-kubernetes-master-1.23.9+bionic_amd64.deb k8s-kubernetes-node-1.23.9+bionic_amd64.deb root@10.0.0.183:/root
root@master-1:~/k8s-v1.23.9/pkgs# ssh root@10.0.0.182 'cd /root && dpkg -i k8s-kubernetes-master-1.23.9+bionic_amd64.deb k8s-kubernetes-node-1.23.9+bionic_amd64.deb'
root@master-1:~/k8s-v1.23.9/pkgs# ssh root@10.0.0.183 'cd /root && dpkg -i k8s-kubernetes-master-1.23.9+bionic_amd64.deb k8s-kubernetes-node-1.23.9+bionic_amd64.deb'
```

#### 2、在master-1节点初始化kubernetes集群证书：
```shell
root@master-1:~# cd /k8s/kubernetes/ssl/cfssl-tools/
root@master-1:/k8s/kubernetes/ssl/cfssl-tools# vi kube-apiserver-csr.json  # 注意双下滑杠开头结尾的配置项需要调整
{
    "CN": "kubernetes",
    "hosts": [
        "10.0.0.181",
        "10.0.0.182",
        "10.0.0.183",
        "10.254.0.1",
        "127.0.0.1",
        "localhost",
        "kubernetes",
        "kubernetes.default",
        "kubernetes.default.svc",
        "kubernetes.default.svc.cluster",
        "kubernetes.default.svc.cluster.local"
    ],
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
root@master-1:/k8s/kubernetes/ssl/cfssl-tools# ./init-certs.sh 
Init Kubernetes Certs OK.
Init Front Proxy Certs OK.
root@master-1:/k8s/kubernetes/ssl/cfssl-tools# ls -lh ../
total 108K
-rw-r--r-- 1 root root 1009 Jul 20 15:18 admin.csr
-rw------- 1 root root 1.7K Jul 20 15:18 admin-key.pem
-rw-r--r-- 1 root root 1.4K Jul 20 15:18 admin.pem
-rw-r--r-- 1 root root 1.1K Jul 20 15:18 ca.csr
-rw------- 1 root root 1.7K Jul 20 15:18 ca-key.pem
-rw-r--r-- 1 root root 1.3K Jul 20 15:18 ca.pem
drwxr-xr-x 2 root root 4.0K Jul 20 15:17 cfssl-tools
-rw-r--r-- 1 root root  944 Jul 20 15:18 front-proxy-ca.csr
-rw------- 1 root root 1.7K Jul 20 15:18 front-proxy-ca-key.pem
-rw-r--r-- 1 root root 1.1K Jul 20 15:18 front-proxy-ca.pem
-rw-r--r-- 1 root root  903 Jul 20 15:18 front-proxy-client.csr
-rw------- 1 root root 1.7K Jul 20 15:18 front-proxy-client-key.pem
-rw-r--r-- 1 root root 1.2K Jul 20 15:18 front-proxy-client.pem
-rw-r--r-- 1 root root 1.3K Jul 20 15:18 kube-apiserver.csr
-rw------- 1 root root 1.7K Jul 20 15:18 kube-apiserver-key.pem
-rw-r--r-- 1 root root 1.6K Jul 20 15:18 kube-apiserver.pem
-rw-r--r-- 1 root root 1.1K Jul 20 15:18 kube-controller-manager.csr
-rw------- 1 root root 1.7K Jul 20 15:18 kube-controller-manager-key.pem
-rw-r--r-- 1 root root 1.4K Jul 20 15:18 kube-controller-manager.pem
-rw-r--r-- 1 root root 1009 Jul 20 15:18 kube-proxy.csr
-rw------- 1 root root 1.7K Jul 20 15:18 kube-proxy-key.pem
-rw-r--r-- 1 root root 1.4K Jul 20 15:18 kube-proxy.pem
-rw-r--r-- 1 root root 1017 Jul 20 15:18 kube-scheduler.csr
-rw------- 1 root root 1.7K Jul 20 15:18 kube-scheduler-key.pem
-rw-r--r-- 1 root root 1.4K Jul 20 15:18 kube-scheduler.pem
-rw------- 1 root root 1.7K Jul 20 15:18 sa.key
-rw-r--r-- 1 root root  451 Jul 20 15:18 sa.pub
```


