# Workshop guide: __Step 1__ Installing Tools

We will use the following tools for the workshop exercise: 
 - Docker CE
 - docker-compose
 - K3S
 
 This guide will explain how to install them.

## Pre-Reqs
- A 4Gb of RAM CentOS 8 Machine with 2 CPUs, 30 GB HDD
- Access to root account

## Docker CE
### Installation
```bash
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf config-manager --set-disabled docker-ce-stable
sudo rpm --install --nodeps --replacefiles --excludepath=/usr/bin/runc https://download.docker.com/linux/centos/8/x86_64/stable/Packages/containerd.io-1.6.8-3.1.el8.x86_64.rpm
sudo dnf install --enablerepo=docker-ce-stable docker-ce
sudo systemctl enable --now docker
```
### Manage Docker as a non-root user
```bash
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```
### Enable auto-completion for Docker
```bash
sudo yum -y install bash-completion
```
### Test
Let's run docker hello world
```bash
docker run --name hello-world hello-world
docker rm hello-world
docker rmi hello-world
```
## docker-compose
### Installation
```bash
sudo curl -L "https://github.com/docker/compose/releases/download/2.11.2/docker-compose-$(uname -s)-$(uname -m)"  -o /usr/local/bin/docker-compose
sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
```
### Test
We should be able to call docker-compose from the CLI
```bash
docker-compose --version
```
## K3S
### Pre steps
If enabled, it is required to disable nm-cloud-setup and reboot the node:
```bash
sudo systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
sudo reboot
```
### Installation
```bash
curl -sfL https://get.k3s.io | sh -
```
### Allow access to kubeconfig file from non-root user
```bash
sudo groupadd rancher
sudo usermod -aG rancher $USER
newgrp rancher
sudo chgrp rancher /etc/rancher/k3s/k3s.yaml
sudo chmod 660 /etc/rancher/k3s/k3s.yaml
```
### Test
We should be able to see a master node on our VM
```bash
kubectl get nodes -o wide
```