## 容器镜像说明

```
docker pull jenkinsci/blueocean   #该映像包含Docker CLI并且与常用的Blue Ocean插件及其功能捆绑在一起
docker pull jenkins/jenkins:lts   #该映像不包含Docker CLI并且未与常用的Blue Ocean插件及其功能捆绑在一起
```



## [使用jenkins/jenkins:lts镜像部署](jenkins/jenkins:lts镜像部署)

- 官方步骤

```shell
#创建网络
docker network create jenkins

#创建数据目录
mkdir -p /data/jenkins && cd /data/jenkins

#创建Dockerfile
vim Dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update && apt-get install -y lsb-release
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"

#构建jenkins-blueocean:lts的容器
docker build -t jenkins-blueocean:lts .

#步骤4运行jenkins-blueocean容器
docker run \
  --name jenkins-blueocean \
  --restart=on-failure \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=unix:///var/run/docker.sock \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume /data/jenkins/jenkins-data:/var/jenkins_home \
  jenkins-blueocean:lts
```

- docker-compose

```shell
#创建启动yaml
vim docker-compose.yaml 
version: '3.5'
services:
  jenkins:
    container_name: jenkins
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock  
    user: root
    networks:
      - jenkins
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./jenkins-data:/var/jenkins_home
      - /root/.ssh:/root/.ssh 
networks:
  jenkins:
    driver: bridge

#创建Dockerfile
vim Dockerfile 
FROM jenkins/jenkins:lts
USER root
# Set up apt source for aliyun
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye main non-free contrib" > /etc/apt/sources.list
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye-updates main non-free contrib" >> /etc/apt/sources.list
RUN echo "deb https://mirrors.aliyun.com/debian/ bullseye-backports main non-free contrib" >> /etc/apt/sources.list
RUN echo "deb https://mirrors.aliyun.com/debian-security/ bullseye-security main" >> /etc/apt/sources.list
# Install dependencies
RUN apt-get update && apt-get install -y lsb-release
# Add Docker GPG key and set up Docker repository
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
# Install Docker CE CLI and containerd.io (latest version)
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
# Install Jenkins plugins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"    

#启动服务
docker-compose up -d

#查看容器日志
docker logs jenkins -f
```



## [使用jenkinsci/blueocean镜像部署](https://www.jenkins.io/zh/doc/book/installing/)

- 官方步骤

```shell
#创建数据目录
mkdir -p /data/jenkins && cd /data/jenkins

#运行容器
docker run \
  -u root \
  --rm \  
  -d \ 
  -p 8080:8080 \ 
  -p 50000:50000 \ 
  -v /data/jenkins:/var/jenkins_home \ 
  -v /var/run/docker.sock:/var/run/docker.sock \ 
  jenkinsci/blueocean 
```

- docker-compose

```shell
#创建数据目录
mkdir -p /data/jenkins && cd /data/jenkins

#创建启动yaml
vim docker-compose.yaml
version: '3.5'
services:
  jenkins:
    container_name: jenkins  
    user: root
    restart: always    
    ports:
        - '8080:8080'
        - '50000:50000'
    volumes:
        - './jenkins-data:/var/jenkins_home'
        - '/var/run/docker.sock:/var/run/docker.sock'
        #- ./ssh/ssh_config:/etc/ssh/ssh_config 
        #- /root/.ssh:/root/.ssh         
    image: jenkinsci/blueocean

#启动服务
docker-compose up -d

#查看容器日志
docker logs jenkins -f

#连接Jenkins容器
docker container exec -it jenkins bash  

#查看初始化密码
cat /var/jenkins_home/secrets/initialAdminPassword 
```





## Jenkins更新镜像改成国内

- 国内镜像地址

```shell
#中文社区
https://updates.jenkins-zh.cn/update-center.json

#清华大学
https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json

#华为开源镜像站
https://mirrors.huaweicloud.com/jenkins/updates/update-center.json

#腾讯
https://mirrors.cloud.tencent.com/jenkins/updates/update-center.json

#ustc
https://mirrors.ustc.edu.cn/jenkins/updates/update-center.json

#bit
https://mirror.bit.edu.cn/jenkins/updates/update-center.json

#lework
https://cdn.jsdelivr.net/gh/lework/jenkins-update-center/updates/tencent/update-center.json https://cdn.jsdelivr.net/gh/lework/jenkins-update-center/updates/tsinghua/update-center.json https://cdn.jsdelivr.net/gh/lework/jenkins-update-center/updates/ustc/update-center.json https://cdn.jsdelivr.net/gh/lework/jenkins-update-center/updates/bit/update-center.json
```

- 修改更新源

```shell
vim jenkins-data/hudson.model.UpdateCenter.xml 
<?xml version='1.1' encoding='UTF-8'?>
<sites>
  <site>
    <id>default</id>
    <url>https://mirrors.cloud.tencent.com/jenkins/updates/update-center.json</url>
  </site>
</sites>
```

- 替换目录里面的default.json文件内容

```shell
sed -i 's/http:\/\/updates.jenkinsci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' jenkins-data/updates/default.json

sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' jenkins-data/updates/default.json
```

- 替换Jenkins的国内源

![image-20230320020426253](http://pic.swireb.cn/images/image-20230320020426253.png)

![image-20230320020452442](http://pic.swireb.cn/images/image-20230320020452442.png)

![image-20230320020505851](http://pic.swireb.cn/images/image-20230320020505851.png)



## Jenkins安装中文环境

![image-20230320020643933](http://pic.swireb.cn/images/image-20230320020643933.png)







## 解决报错`Unsupported option "gssapiauthentication"`

![image-20230320034735802](http://pic.swireb.cn/images/image-20230320034735802.png)

```shell
#将SSH客户端的配置文件映射到容器内部
vim /etc/ssh/ssh_config
StrictHostKeyChecking no
```

