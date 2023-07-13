

#### 1、集群管理整体目录结构：
```shell
root@master03:~/ClusterManager# ll
drwxr-xr-x 2 root root 4096 Mar  8 10:32 Global/      # 全局配置，一般clusterrole放在此目录下
-rw-r--r-- 1 root root 1873 Mar  7 14:35 README.md    # 描述文件
drwxr-xr-x 2 root root 4096 Mar  8 13:58 Sample/      # 用户初始化脚本模板
drwxr-xr-x 2 root root 4096 Mar  9 09:11 Users/       # 该目录下的子目录为用户目录，以用户名命名，一个用户创建一个
```

#### 2、新建一个用户，复制模板目录Sample并以用户名命名：
```shell
root@master03:~/ClusterManager# cp -fr Sample Users/cloudp
root@master03:~/ClusterManager# cd Users/cloudp/
```

#### 3、编辑用户env文件一般只需调整Username项即可：
```shell
root@master03:~/ClusterManager# cd Users/cloudp
root@master03:~/ClusterManager/Users/cloudp# vim env
...
# Username
Username="cloudp"
...
```

#### 4、执行用户目录下`setup1-ns.sh`脚本，创建用户命名空间，交互式`y`表示应用到集群（即创建），否则只生成yaml清单文件：
```shell
root@master03:~/ClusterManager/Users/cloudp# ./setup1-ns.sh 
Init file 'cloudp-ns.yaml' ok.
Apply to cluster, execute 'kubectl apply -f cloudp-ns.yaml' command ?
[y|n]: y
namespace/cloudp created
```

#### 5、执行用户目录下`setup2-rbac.sh`脚本，创建sa用户和rbac授权，交互式`y`表示应用到集群（即创建），否则只生成yaml清单文件：
```shell
root@master03:~/ClusterManager/Users/cloudp# ./setup2-rbac.sh
Init file 'cloudp-rbac.yaml' ok.
Apply to cluster, execute 'kubectl apply -f cloudp-rbac.yaml' command ?
[y|n]: y
serviceaccount/cloudp created
rolebinding.rbac.authorization.k8s.io/cloudp created
clusterrolebinding.rbac.authorization.k8s.io/cloudp created
```

#### 6、执行用户目录下`setup3-kubeconfig.sh`脚本，创建用户kubeconfig文件，该文件作为用户访问集群的唯一凭证（文件内部包含用户访问集群的Token认证信息），需要单独发给用户：
```shell
root@master03:~/ClusterManager/Users/cloudp# ./setup3-kubeconfig.sh
Cluster "kubernetes" set.
User "cloudp" set.
Context "cloudp@kubernetes" created.
Switched to context "cloudp@kubernetes".
Please distribute this file 'cloudp.kubeconfig' to user.
```

#### 7、执行用户目录下`setup4-deployment.sh`脚本，生成deployment.yaml模板文件，该文件为用户创建pod的模板文件，文件内容要根据用户需调整，修改完以后执行`kubectl apply -f deployment.yaml`创建用户pod：
```shell
root@master03:~/ClusterManager/Users/cloudp# ./setup4-deployment.sh 
Please modify the user 'deployment.yaml' file and create pods.
```

