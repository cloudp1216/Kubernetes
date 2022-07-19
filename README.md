

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
k8s-v1.23.9/pkgs/k8s-kubernetes-master-1.23.9+bionic_amd64.deb    # master组件(kube-apiserver、kube-controller-manager、kube-scheduler)
k8s-v1.23.9/pkgs/k8s-kubernetes-node-1.23.9+bionic_amd64.deb      # node组件(kubelet、kube-proxy)
k8s-v1.23.9/pkgs/k8s-slb-1.16.1+bionic_amd64.deb                  # nginx四层代理，部署在node之上，作为kubelet、kube-proxy的代理访问kube-apiserver
k8s-v1.23.9/calico-v3.22.3                                        # 网络插件calico
k8s-v1.23.9/coredns-v1.8.6                                        # 服务发现coredns
k8s-v1.23.9/dashboard-v2.5.1                                      # 集群可视化dashboard
k8s-v1.23.9/docker-ce-v20.10.12                                   # 容器服务docker
k8s-v1.23.9/metrics-server-v0.6.1                                 # 核心指标监控metrics-server
```


