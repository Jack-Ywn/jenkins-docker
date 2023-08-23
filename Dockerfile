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
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
# Install Docker CE CLI and containerd.io (latest version)
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
# Install Jenkins plugins
RUN jenkins-plugin-cli --plugins "blueocean docker-workflow"  
