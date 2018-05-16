#!/bin/bash 
: ${root_password='123456a?'}

yum -y install wget libvirt* yum-utils epel-release
yum -y install lxc*

setenforce 0
lxc-create --name docker -t /usr/share/lxc/templates/lxc-centos
echo "root:$root_password" | chroot /var/lib/lxc/docker/rootfs chpasswd

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
cp /etc/yum.repos.d/docker-ce.repo /var/lib/lxc/docker/rootfs/etc/yum.repos.d/
yum -y --installroot=/var/lib/lxc/docker/rootfs install docker-ce
sed -i '/^SELINUX=/s/enforcing/disabled/g' /var/lib/lxc/docker/rootfs/etc/selinux/config

yum -y --installroot=/var/lib/lxc/docker/rootfs install kernel

cp /var/lib/lxc/docker/rootfs/boot/vmlinuz-*x86_64 /boot/vmlinuz-3.10.0-inOS_docker

pushd /var/lib/lxc/docker/rootfs
find . -print | cpio -c -o | gzip -9 > /opt/myroot.img.gz
popd
