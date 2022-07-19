


一、master上安装以下软件包：
1、安装
root@master:~/k8s-v1.23.9/pkgs# dpkg -i k8s-etcd-3.4.18+bionic_amd64.deb k8s-kubernetes-master-1.23.9+bionic_amd64.deb k8s-kubernetes-node-1.23.9+bionic_amd64.deb 
Selecting previously unselected package k8s-etcd.
(Reading database ... 71556 files and directories currently installed.)
Preparing to unpack k8s-etcd-3.4.18+bionic_amd64.deb ...
Unpacking k8s-etcd (3.4.18+bionic) ...
Selecting previously unselected package k8s-kubernetes-master.
Preparing to unpack k8s-kubernetes-master-1.23.9+bionic_amd64.deb ...
Unpacking k8s-kubernetes-master (1.23.9+bionic) ...
Selecting previously unselected package k8s-kubernetes-node.
Preparing to unpack k8s-kubernetes-node-1.23.9+bionic_amd64.deb ...
Unpacking k8s-kubernetes-node (1.23.9+bionic) ...
Setting up k8s-etcd (3.4.18+bionic) ...
Setting up k8s-kubernetes-master (1.23.9+bionic) ...
Setting up k8s-kubernetes-node (1.23.9+bionic) ...




二、初始化etcd证书并启动服务

2、初始化etcd证书
root@master:~# cd /k8s/etcd/ssl/cfssl-tools
root@master:/k8s/etcd/ssl/cfssl-tools# vi etcd-csr.json   # 注意双下划线开头修改为以下内容：
{
    "CN": "etcd",
    "hosts": [
        "10.0.0.175",                                     # 注意此行
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

root@master:/k8s/etcd/ssl/cfssl-tools# vi peer-csr.json 

{
    "CN": "peer",
    "hosts": [
        "10.0.0.175",                                      # 注意此行
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


root@master:/k8s/etcd/ssl/cfssl-tools# ./init-certs.sh 
Init Etcd Certs OK.
root@master:/k8s/etcd/ssl/cfssl-tools# cd ..
root@master:/k8s/etcd/ssl# ll
total 48
drwxr-xr-x 3 root root 4096 Jul 18 17:27 ./
drwxr-xr-x 5 root root 4096 Jul 18 17:23 ../
-rw-r--r-- 1 root root 1041 Jul 18 17:27 ca.csr
-rw------- 1 root root 1679 Jul 18 17:27 ca-key.pem
-rw-r--r-- 1 root root 1298 Jul 18 17:27 ca.pem
drwxr-xr-x 2 root root 4096 Jul 18 17:26 cfssl-tools/
-rw-r--r-- 1 root root 1062 Jul 18 17:27 etcd.csr
-rw------- 1 root root 1675 Jul 18 17:27 etcd-key.pem
-rw-r--r-- 1 root root 1383 Jul 18 17:27 etcd.pem
-rw-r--r-- 1 root root 1062 Jul 18 17:27 peer.csr
-rw------- 1 root root 1675 Jul 18 17:27 peer-key.pem
-rw-r--r-- 1 root root 1428 Jul 18 17:27 peer.pem



3、调整etcd配置文件
root@master:~# cd /k8s/etcd/cfg/
root@master:/k8s/etcd/cfg# vi etcd                            # 调整为以下内容，注意双下滑线开头内容需要调整
#[Member]
ETCD_ARGS="--name=etcd"
ETCD_DATA_DIR="/k8s/etcd/etcd.data"
ETCD_LISTEN_CLIENT_URLS="https://10.0.0.175:2379,https://127.0.0.1:2379"
ETCD_ADVERTISE_CLIENT_URLS="https://10.0.0.175:2379"


#[Clustering]
ETCD_LISTEN_PEER_URLS="https://127.0.0.1:2380"


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



4、启动etcd服务器
root@master:~# systemctl start etcd
root@master:~# systemctl enable etcd




三、初始化k8s集群证书并启动服务master相关服务

1、初始化k8s集群证书
root@master:~# cd /k8s/kubernetes/ssl/cfssl-tools
root@master:/k8s/kubernetes/ssl/cfssl-tools# vi kube-apiserver-csr.json
{
    "CN": "kubernetes",
    "hosts": [
        "10.0.0.175",
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


root@master:/k8s/kubernetes/ssl/cfssl-tools# ./init-certs.sh 
Init Kubernetes Certs OK.
Init Front Proxy Certs OK.
root@master:/k8s/kubernetes/ssl/cfssl-tools# cd ..
root@master:/k8s/kubernetes/ssl# ll
total 116
drwxr-xr-x 3 root root 4096 Jul 18 17:33 ./
drwxr-xr-x 5 root root 4096 Jul 18 17:23 ../
-rw-r--r-- 1 root root 1009 Jul 18 17:33 admin.csr
-rw------- 1 root root 1675 Jul 18 17:33 admin-key.pem
-rw-r--r-- 1 root root 1399 Jul 18 17:33 admin.pem
-rw-r--r-- 1 root root 1045 Jul 18 17:33 ca.csr
-rw------- 1 root root 1679 Jul 18 17:33 ca-key.pem
-rw-r--r-- 1 root root 1310 Jul 18 17:33 ca.pem
drwxr-xr-x 2 root root 4096 Jul 18 17:32 cfssl-tools/
-rw-r--r-- 1 root root  944 Jul 18 17:33 front-proxy-ca.csr
-rw------- 1 root root 1675 Jul 18 17:33 front-proxy-ca-key.pem
-rw-r--r-- 1 root root 1103 Jul 18 17:33 front-proxy-ca.pem
-rw-r--r-- 1 root root  903 Jul 18 17:33 front-proxy-client.csr
-rw------- 1 root root 1675 Jul 18 17:33 front-proxy-client-key.pem
-rw-r--r-- 1 root root 1192 Jul 18 17:33 front-proxy-client.pem
-rw-r--r-- 1 root root 1257 Jul 18 17:33 kube-apiserver.csr
-rw------- 1 root root 1679 Jul 18 17:33 kube-apiserver-key.pem
-rw-r--r-- 1 root root 1582 Jul 18 17:33 kube-apiserver.pem
-rw-r--r-- 1 root root 1029 Jul 18 17:33 kube-controller-manager.csr
-rw------- 1 root root 1675 Jul 18 17:33 kube-controller-manager-key.pem
-rw-r--r-- 1 root root 1419 Jul 18 17:33 kube-controller-manager.pem
-rw-r--r-- 1 root root 1009 Jul 18 17:33 kube-proxy.csr
-rw------- 1 root root 1679 Jul 18 17:33 kube-proxy-key.pem
-rw-r--r-- 1 root root 1403 Jul 18 17:33 kube-proxy.pem
-rw-r--r-- 1 root root 1017 Jul 18 17:33 kube-scheduler.csr
-rw------- 1 root root 1679 Jul 18 17:33 kube-scheduler-key.pem
-rw-r--r-- 1 root root 1407 Jul 18 17:33 kube-scheduler.pem
-rw------- 1 root root 1679 Jul 18 17:33 sa.key
-rw-r--r-- 1 root root  451 Jul 18 17:33 sa.pub
root@master:/k8s/kubernetes/ssl# 




2、初始化kubeconfig组件配置信息
root@master:~# cd /k8s/kubernetes/cfg/init-kubeconfig/
root@master:/k8s/kubernetes/cfg/init-kubeconfig# ./init-kubeconfig.sh 
Cluster "kubernetes" set.
User "kube-scheduler" set.
Context "kube-scheduler@kubernetes" created.
Switched to context "kube-scheduler@kubernetes".
Cluster "kubernetes" set.
User "kube-controller-manager" set.
Context "kube-controller-manager@kubernetes" created.
Switched to context "kube-controller-manager@kubernetes".
Cluster "kubernetes" set.
User "admin" set.
Context "admin@kubernetes" created.
Switched to context "admin@kubernetes".
Cluster "kubernetes" set.
User "kube-proxy" set.
Context "kube-proxy@kubernetes" created.
Switched to context "kube-proxy@kubernetes".
Cluster "kubernetes" set.
User "kubelet-bootstrap" set.
Context "kubelet-bootstrap@kubernetes" created.
Switched to context "kubelet-bootstrap@kubernetes".
Token: 0e80be89c1ed69964836517e0414dee2,kubelet-bootstrap,10001,system:kubelet-bootstrap
root@master:/k8s/kubernetes/cfg/init-kubeconfig# cd ..
root@master:/k8s/kubernetes/cfg# ll
total 72
drwxr-xr-x 3 root root 4096 Jul 18 17:34 ./
drwxr-xr-x 5 root root 4096 Jul 18 17:23 ../
-rw------- 1 root root 6205 Jul 18 17:34 admin.kubeconfig
-rw------- 1 root root 2141 Jul 18 17:34 bootstrap.kubeconfig
drwxr-xr-x 2 root root 4096 Jul 18 17:23 init-kubeconfig/
-rw-r--r-- 1 root root 1487 Jul 18 16:54 kube-apiserver
-rw-r--r-- 1 root root 1017 Jul 18 16:54 kube-controller-manager
-rw------- 1 root root 6301 Jul 18 17:34 kube-controller-manager.kubeconfig
-rw-r--r-- 1 root root  638 Jul 18 16:54 kubelet
-rw-r--r-- 1 root root  206 Jul 18 16:54 kube-proxy
-rw------- 1 root root 6233 Jul 18 17:34 kube-proxy.kubeconfig
-rw-r--r-- 1 root root  371 Jul 18 16:54 kube-scheduler
-rw------- 1 root root 6253 Jul 18 17:34 kube-scheduler.kubeconfig
-rw-r--r-- 1 root root   82 Jul 18 17:34 token.csv




3、调整kube-apiserver配置：
root@master:/k8s/kubernetes/cfg# vi kube-apiserver
KUBE_APISERVER_ARGS=" \
    --advertise-address=10.0.0.175 \
    --allow-privileged=true \
    --authorization-mode=Node,RBAC \
    --enable-admission-plugins=NodeRestriction \
    --anonymous-auth=false \
    --bind-address=0.0.0.0 \
    --secure-port=6443 \
    --enable-bootstrap-token-auth \
    --token-auth-file=/k8s/kubernetes/cfg/token.csv \
    --client-ca-file=/k8s/kubernetes/ssl/ca.pem \
    --tls-cert-file=/k8s/kubernetes/ssl/kube-apiserver.pem \
    --tls-private-key-file=/k8s/kubernetes/ssl/kube-apiserver-key.pem \
    --etcd-servers=https://127.0.0.1:2379 \
    --etcd-cafile=/k8s/etcd/ssl/ca.pem \
    --etcd-certfile=/k8s/etcd/ssl/etcd.pem \
    --etcd-keyfile=/k8s/etcd/ssl/etcd-key.pem \
    --service-cluster-ip-range=10.254.0.0/16 \
    --service-node-port-range=30000-50000 \
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \
    --service-account-key-file=/k8s/kubernetes/ssl/sa.pub \
    --service-account-signing-key-file=/k8s/kubernetes/ssl/sa.key \
    --proxy-client-cert-file=/k8s/kubernetes/ssl/front-proxy-client.pem \
    --proxy-client-key-file=/k8s/kubernetes/ssl/front-proxy-client-key.pem \
    --requestheader-allowed-names=front-proxy-client \
    --requestheader-client-ca-file=/k8s/kubernetes/ssl/front-proxy-ca.pem \
    --requestheader-extra-headers-prefix=X-Remote-Extra- \
    --requestheader-group-headers=X-Remote-Group \
    --requestheader-username-headers=X-Remote-User \
    --logtostderr=true \
    --v=2"


4、启动kube-apiserver服务
root@master:/k8s/kubernetes/cfg# systemctl start kube-apiserver
root@master:/k8s/kubernetes/cfg# systemctl enable kube-apiserver


5、启动kube-controller-manager kube-scheduler服务
root@master:/k8s/kubernetes/cfg# systemctl start kube-controller-manager kube-scheduler
root@master:/k8s/kubernetes/cfg# systemctl enable kube-controller-manager kube-scheduler


6、添加k8s可执行程序路径：
root@master:~# echo 'PATH=$PATH:/k8s/kubernetes/bin' >> /etc/profile 
root@master:~# . /etc/profile


7、生成集群管理员配置
root@master:~# mkdir -p ~/.kube
root@master:~# cp /k8s/kubernetes/cfg/admin.kubeconfig ~/.kube/config


8、查看集群组件状态
root@master:~# kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok                  
scheduler            Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   


9、创建kubelet-bootstrap clusterrolebinding
root@master:~# kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
clusterrolebinding.rbac.authorization.k8s.io/kubelet-bootstrap created



四、添加master上的node到集群
1、调整kubelet配置文件pause镜像仓库为本地，要提前推送pause镜像到本地仓库：
root@master:~# cd /k8s/kubernetes/cfg/
root@master:/k8s/kubernetes/cfg# vi kubelet 
KUBELET_ARGS=" \
    --bootstrap-kubeconfig=/k8s/kubernetes/cfg/bootstrap.kubeconfig \
    --kubeconfig=/k8s/kubernetes/cfg/kubelet.kubeconfig \
    --cgroup-driver=systemd \
    --kubelet-cgroups=/systemd/system.slice \
    --runtime-cgroups=/systemd/system.slice \
    --network-plugin=cni \
    --cluster-dns=10.254.0.2 \
    --cluster-domain=cluster.local \
    --fail-swap-on=false \
    --cert-dir=/k8s/kubernetes/ssl \
    --hairpin-mode=promiscuous-bridge \
    --serialize-image-pulls=false \
    --pod-infra-container-image=hub.speech.local/k8s.gcr.io/pause:3.6 \            # 注意调整此项
    --logtostderr=true \
    --v=2"


2、启动kubelet和kube-proxy
root@master:/k8s/kubernetes/cfg# systemctl start kubelet kube-proxy
root@master:/k8s/kubernetes/cfg# systemctl enable kubelet kube-proxy


4、允许master上的node加入集群
root@master:~# kubectl get csr
NAME                                                   AGE   SIGNERNAME                                    REQUESTOR           REQUESTEDDURATION   CONDITION
node-csr-GG6WA6VgWKAQkaLLTtBrlUpo9U9jklFRnz3TgAzkW60   38s   kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   <none>              Pending
root@master:~# kubectl certificate approve node-csr-GG6WA6VgWKAQkaLLTtBrlUpo9U9jklFRnz3TgAzkW60
certificatesigningrequest.certificates.k8s.io/node-csr-GG6WA6VgWKAQkaLLTtBrlUpo9U9jklFRnz3TgAzkW60 approved


5、查看node信息
root@master:~# kubectl get node -o wide
NAME     STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master   Ready    <none>   41s   v1.23.9   10.0.0.175    <none>        Ubuntu 18.04.6 LTS   4.15.0-156-generic   docker://20.10.12



五、初始化集群网络插件calico
1、调整calico.yaml清单镜像文件为本地harbor仓库（镜像要事先存在）
root@master:~# cd k8s-v1.23.9/calico-v3.22.3/
root@master:~/k8s-v1.23.9/calico-v3.22.3# cat calico.yaml | grep image -n
235:          image: docker.io/calico/cni:v3.22.3
279:          image: docker.io/calico/pod2daemon-flexvol:v3.22.3
290:          image: docker.io/calico/node:v3.22.3
535:          image: docker.io/calico/kube-controllers:v3.22.3


调整为：
root@master:~/k8s-v1.23.9/calico-v3.22.3# vi calico.yaml
235:          image: hub.speech.local/calico/cni:v3.22.3
279:          image: hub.speech.local/calico/pod2daemon-flexvol:v3.22.3
290:          image: hub.speech.local/calico/node:v3.22.3
535:          image: hub.speech.local/calico/kube-controllers:v3.22.3


2、设置etcd地址(或etcd集群以逗号分割)：
root@master:~/k8s-v1.23.9/calico-v3.22.3# ETCD_ENDPOINTS="https://10.0.0.175:2379"
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i "s#.*etcd_endpoints:.*#  etcd_endpoints: \"${ETCD_ENDPOINTS}\"#g" calico.yaml


3、设置etcd证书
root@master:~/k8s-v1.23.9/calico-v3.22.3# ETCD_CA=`cat /k8s/etcd/ssl/ca.pem | base64 | tr -d '\n'`
root@master:~/k8s-v1.23.9/calico-v3.22.3# ETCD_CERT=`cat /k8s/etcd/ssl/etcd.pem | base64 | tr -d '\n'`
root@master:~/k8s-v1.23.9/calico-v3.22.3# ETCD_KEY=`cat /k8s/etcd/ssl/etcd-key.pem | base64 | tr -d '\n'`
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i "s#.*etcd-ca:.*#  etcd-ca: ${ETCD_CA}#g" calico.yaml
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i "s#.*etcd-cert:.*#  etcd-cert: ${ETCD_CERT}#g" calico.yaml
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i "s#.*etcd-key:.*#  etcd-key: ${ETCD_KEY}#g" calico.yaml
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i 's#.*etcd_ca:.*#  etcd_ca: "/calico-secrets/etcd-ca"#g' calico.yaml
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i 's#.*etcd_cert:.*#  etcd_cert: "/calico-secrets/etcd-cert"#g' calico.yaml
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i 's#.*etcd_key:.*#  etcd_key: "/calico-secrets/etcd-key"#g' calico.yaml



4、设置Pod地址池（注意要和kube-proxy配置项--cluster-cidr地址池一致）
root@master:~/k8s-v1.23.9/calico-v3.22.3# CALICO_IPV4POOL_CIDR="10.244.0.0/16"
root@master:~/k8s-v1.23.9/calico-v3.22.3# sed -i "s#192.168.0.0/16#${CALICO_IPV4POOL_CIDR}#g" calico.yaml


5、在集群中创建calico相关资源
root@master:~/k8s-v1.23.9/calico-v3.22.3# kubectl apply -f calico.yaml
secret/calico-etcd-secrets created
configmap/calico-config created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
serviceaccount/calico-node created
deployment.apps/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
poddisruptionbudget.policy/calico-kube-controllers created



6、查看pod
root@master:~/k8s-v1.23.9/calico-v3.22.3# kubectl get pods -A -o wide
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE   IP           NODE     NOMINATED NODE   READINESS GATES
kube-system   calico-kube-controllers-867987dd7c-ng2rc   1/1     Running   0          25s   10.0.0.175   master   <none>           <none>
kube-system   calico-node-68fhj                          1/1     Running   0          25s   10.0.0.175   master   <none>           <none>



六、部署CoreDNS
1、调整coredns.yaml清单镜像文件为本地harbor仓库（镜像要事先存在）
root@master:~# cd k8s-v1.23.9/coredns-v1.8.6/
root@master:~/k8s-v1.23.9/coredns-v1.8.6# vi coredns.yaml
143         image: registry.cn-hangzhou.aliyuncs.com/google_containers/coredns:v1.8.6

调整为：

143         image: hub.speech.local/k8s.gcr.io/coredns:v1.8.6



2、基础配置调整：
root@master:~/k8s-v1.23.9/coredns-v1.8.6# CLUSTER_DNS_DOMAIN="cluster.local"
root@master:~/k8s-v1.23.9/coredns-v1.8.6# CLUSTER_DNS_SERVER="10.254.0.2"
root@master:~/k8s-v1.23.9/coredns-v1.8.6# CLUSTER_DNS_MEMORY_LIMIT="200Mi"
root@master:~/k8s-v1.23.9/coredns-v1.8.6# sed -i -e "s@__DNS__DOMAIN__@${CLUSTER_DNS_DOMAIN}@" \
        -e "s@__DNS__SERVER__@${CLUSTER_DNS_SERVER}@" \
        -e "s@__DNS__MEMORY__LIMIT__@${CLUSTER_DNS_MEMORY_LIMIT}@" \
        coredns.yaml


3、部署CoreDNS：
root@master:~/k8s-v1.23.9/coredns-v1.8.6# kubectl apply -f coredns.yaml
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created


4、查看pod和svc：
root@master:~# kubectl get pod,svc -A -o wide
NAMESPACE     NAME                                           READY   STATUS    RESTARTS   AGE     IP             NODE     NOMINATED NODE   READINESS GATES
kube-system   pod/calico-kube-controllers-867987dd7c-ng2rc   1/1     Running   0          6m35s   10.0.0.175     master   <none>           <none>
kube-system   pod/calico-node-68fhj                          1/1     Running   0          6m35s   10.0.0.175     master   <none>           <none>
kube-system   pod/coredns-54d7c66b75-2zsp2                   1/1     Running   0          108s    10.244.134.1   master   <none>           <none>
kube-system   pod/coredns-54d7c66b75-5nx2m                   1/1     Running   0          108s    10.244.134.0   master   <none>           <none>

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE    SELECTOR
default       service/kubernetes   ClusterIP   10.254.0.1   <none>        443/TCP                  30m    <none>
kube-system   service/kube-dns     ClusterIP   10.254.0.2   <none>        53/UDP,53/TCP,9153/TCP   108s   k8s-app=kube-dns



七、给master打污点并重启
1、给master打污点
kubectl taint node master node-role.kubernetes.io/master:NoSchedule


2、重启master
reboot


3、查看调度策略是否自动调整为lvs
root@master:~# ipvsadm -ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.254.0.1:443 lc
  -> 10.0.0.175:6443              Masq    1      3          2         
TCP  10.254.0.2:53 lc
  -> 10.244.134.2:53              Masq    1      0          0         
  -> 10.244.134.3:53              Masq    1      0          0         
TCP  10.254.0.2:9153 lc
  -> 10.244.134.2:9153            Masq    1      0          0         
  -> 10.244.134.3:9153            Masq    1      0          0         
UDP  10.254.0.2:53 lc
  -> 10.244.134.2:53              Masq    1      0          0         
  -> 10.244.134.3:53              Masq    1      0          0         



八、添加普通node到集群
1、在node上安装以下软件包
root@node-1:~# dpkg -i k8s-kubernetes-node-1.23.9+bionic_amd64.deb k8s-slb-1.16.1+bionic_amd64.deb 
Selecting previously unselected package k8s-kubernetes-node.
(Reading database ... 71695 files and directories currently installed.)
Preparing to unpack k8s-kubernetes-node-1.23.9+bionic_amd64.deb ...
Unpacking k8s-kubernetes-node (1.23.9+bionic) ...
Preparing to unpack k8s-slb-1.16.1+bionic_amd64.deb ...
Unpacking k8s-slb (1.16.1+bionic) over (1.16.1+bionic) ...
Setting up k8s-kubernetes-node (1.23.9+bionic) ...
Setting up k8s-slb (1.16.1+bionic) ...


2、编辑slb服务指定kube-apiserver
root@node-1:~# cd /k8s/slb/cfg/nginx.conf.d/
root@node-1:/k8s/slb/cfg/nginx.conf.d# vi kube-apiserver.conf
upstream kube-apiserver {
    least_conn;
    server 10.0.0.175:6443;
}

server {
    listen 127.0.0.1:6443;
    proxy_pass kube-apiserver;
    proxy_timeout 10s;
}


3、启动本地slb服务（nginx服务）
root@node-1:/k8s/slb/cfg/nginx.conf.d# systemctl start slb
root@node-1:/k8s/slb/cfg/nginx.conf.d# systemctl enable slb


4、调整kubelet配置文件指定pause镜像仓库：
root@node-1:~# cd /k8s/kubernetes/cfg/
root@node-1:/k8s/kubernetes/cfg# vi kubelet 
KUBELET_ARGS=" \
    --bootstrap-kubeconfig=/k8s/kubernetes/cfg/bootstrap.kubeconfig \
    --kubeconfig=/k8s/kubernetes/cfg/kubelet.kubeconfig \
    --cgroup-driver=systemd \
    --kubelet-cgroups=/systemd/system.slice \
    --runtime-cgroups=/systemd/system.slice \
    --network-plugin=cni \
    --cluster-dns=10.254.0.2 \
    --cluster-domain=cluster.local \
    --fail-swap-on=false \
    --cert-dir=/k8s/kubernetes/ssl \
    --hairpin-mode=promiscuous-bridge \
    --serialize-image-pulls=false \
    --pod-infra-container-image=hub.speech.local/k8s.gcr.io/pause:3.6 \            # 注意调整此项
    --logtostderr=true \
    --v=2"


5、从master复制bootstrap.kubeconfig、kube-proxy.kubeconfig文件到node节点
root@master:~# cd /k8s/kubernetes/cfg
root@master:/k8s/kubernetes/cfg# scp bootstrap.kubeconfig kube-proxy.kubeconfig root@10.0.0.176:/k8s/kubernetes/cfg


6、在node节点启动kubelet、kube-proxy
root@node-1:~# systemctl start kubelet kube-proxy
root@node-1:~# systemctl enable kubelet kube-proxy


7、允许node加入集群，在master执行
root@master:~# kubectl get csr
NAME                                                   AGE     SIGNERNAME                                    REQUESTOR           REQUESTEDDURATION   CONDITION
node-csr-GG6WA6VgWKAQkaLLTtBrlUpo9U9jklFRnz3TgAzkW60   54m     kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   <none>              Approved,Issued
node-csr-unpUwlK40n8xq-79EnVZIp4D4ZwjudflkruO_PADH28   2m11s   kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   <none>              Pending
root@master:~# kubectl certificate approve node-csr-unpUwlK40n8xq-79EnVZIp4D4ZwjudflkruO_PADH28
certificatesigningrequest.certificates.k8s.io/node-csr-unpUwlK40n8xq-79EnVZIp4D4ZwjudflkruO_PADH28 approved


8、查看node
root@master:~# kubectl get node -o wide
NAME     STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION       CONTAINER-RUNTIME
master   Ready    <none>   54m   v1.23.9   10.0.0.175    <none>        Ubuntu 18.04.6 LTS   4.15.0-156-generic   docker://20.10.12
node-1   Ready    <none>   20s   v1.23.9   10.0.0.176    <none>        Ubuntu 18.04.6 LTS   4.15.0-156-generic   docker://20.10.12


9、重启一下node
reboot



九、部署metrics-server
1、未部署metrics-server无法查看集群核心指标数据
root@master:~# kubectl top node
error: Metrics API not available
root@master:~# kubectl top pod -A
error: Metrics API not available


2、调整metrics-server镜像（注意镜像要提前拖到本地仓库）
root@master:~# cd k8s-v1.23.9/metrics-server-v0.6.1/
root@master:~/k8s-v1.23.9/metrics-server-v0.6.1# vi +141 components.yaml


3、创建资源
root@master:~/k8s-v1.23.9/metrics-server-v0.6.1# kubectl apply -f components.yaml
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created


4、查看pod
root@master:~# kubectl get pods -A -o wide
NAMESPACE     NAME                                       READY   STATUS    RESTARTS        AGE     IP             NODE     NOMINATED NODE   READINESS GATES
kube-system   calico-kube-controllers-867987dd7c-ng2rc   1/1     Running   2 (43m ago)     60m     10.0.0.175     master   <none>           <none>
kube-system   calico-node-68fhj                          1/1     Running   2 (43m ago)     60m     10.0.0.175     master   <none>           <none>
kube-system   calico-node-nzrbc                          1/1     Running   1 (7m51s ago)   8m40s   10.0.0.177     node-2   <none>           <none>
kube-system   calico-node-xcd6t                          1/1     Running   1 (17m ago)     20m     10.0.0.176     node-1   <none>           <none>
kube-system   coredns-54d7c66b75-2zsp2                   1/1     Running   2 (43m ago)     55m     10.244.134.5   master   <none>           <none>
kube-system   coredns-54d7c66b75-5nx2m                   1/1     Running   2 (43m ago)     55m     10.244.134.4   master   <none>           <none>
kube-system   metrics-server-6c865bb754-zs7lv            1/1     Running   0               49s     10.244.5.0     node-2   <none>           <none>


5、查看资源指标
root@master:~# kubectl top node
NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
master   212m         10%    994Mi           52%       
node-1   105m         5%     451Mi           23%       
node-2   128m         6%     542Mi           28%       
root@master:~# kubectl top pod -A
NAMESPACE     NAME                                       CPU(cores)   MEMORY(bytes)   
kube-system   calico-kube-controllers-867987dd7c-ng2rc   3m           21Mi            
kube-system   calico-node-68fhj                          27m          135Mi           
kube-system   calico-node-nzrbc                          43m          135Mi           
kube-system   calico-node-xcd6t                          37m          134Mi           
kube-system   coredns-54d7c66b75-2zsp2                   2m           11Mi            
kube-system   coredns-54d7c66b75-5nx2m                   2m           11Mi            
kube-system   metrics-server-6c865bb754-zs7lv            4m           14Mi          



十、部署dashboard（按需部署）
1、调整dashboard镜像地址为私有仓库
root@master:~# cd k8s-v1.23.9/dashboard-v2.5.1
root@master:~/k8s-v1.23.9/dashboard-v2.5.1# cat recommended.yaml | grep image: -n
194:          image: kubernetesui/dashboard:v2.5.1
279:          image: kubernetesui/metrics-scraper:v1.0.7

调整为

root@master:~/k8s-v1.23.9/dashboard-v2.5.1# vi recommended.yaml
194:          image: hub.speech.local/kubernetesui/dashboard:v2.5.1
279:          image: hub.speech.local/kubernetesui/metrics-scraper:v1.0.7


2、创建资源
root@master:~/k8s-v1.23.9/dashboard-v2.5.1# kubectl apply -f recommended.yaml
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created


3、创建ServiceAccount账号dashboard-view（该账号只有查看权限）
root@master:~/k8s-v1.23.9/dashboard-v2.5.1# kubectl apply -f dashboard-view.yaml 
serviceaccount/dashboard-view created
clusterrolebinding.rbac.authorization.k8s.io/dashboard-view created


4、得到dashboard-view账号token
root@master:~/k8s-v1.23.9/dashboard-v2.5.1# ./get_token.sh 
eyJhbGciOiJSUzI1NiIsImtpZCI6ImpncHVJQXRGazhzX0Y0T...


5、查看dashboard NodePort为30201
root@master:~/k8s-v1.23.9/dashboard-v2.5.1# kubectl get svc -A
NAMESPACE              NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                  AGE
default                kubernetes                  ClusterIP   10.254.0.1      <none>        443/TCP                  95m
kube-system            kube-dns                    ClusterIP   10.254.0.2      <none>        53/UDP,53/TCP,9153/TCP   66m
kube-system            metrics-server              ClusterIP   10.254.74.180   <none>        443/TCP                  12m
kubernetes-dashboard   dashboard-metrics-scraper   ClusterIP   10.254.91.27    <none>        8000/TCP                 2m43s
kubernetes-dashboard   kubernetes-dashboard        NodePort    10.254.65.71    <none>        443:30201/TCP            2m43s


6、通过集群任意节点，例如 https://10.0.0.176:30201 打开管理界面粘贴dashboard-view账号的token值即可登录




