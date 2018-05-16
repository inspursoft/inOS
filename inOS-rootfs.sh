#!/bin/bash 

function buildrootfs {
echo "Prepare basic tools"
yum -y install wget libvirt* yum-utils epel-release
yum -y install lxc*

echo "Use lxc to build basic rootfs"
setenforce 0
lxc-create --name docker -t /usr/share/lxc/templates/lxc-centos
echo "root:$ROOTPW" | chroot ${ROOTFSPATH} chpasswd

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
cp /etc/yum.repos.d/docker-ce.repo ${ROOTFSPATH}/etc/yum.repos.d/
yum -y --installroot=/var/lib/lxc/docker/rootfs install docker-ce
sed -i '/^SELINUX=/s/enforcing/disabled/g' ${ROOTFSPATH}/etc/selinux/config
sed -i '/native\.cgroupdriver/s/systemd/cgroupfs/' ${ROOTFSPATH}/usr/lib/systemd/system/docker.service
unlink ${ROOTFSPATH}/etc/systemd/system/multi-user.target.wants/firewalld.service

yum -y --installroot=/var/lib/lxc/docker/rootfs install kernel

cp ${ROOTFSPATH}/boot/vmlinuz-*x86_64 /boot/vmlinuz-3.10.0-inOS_docker

if [ "$TARGET" != "docker" ]
then
buildk8senvironment
fi

echo "Now compress rootfs image"
pushd ${ROOTFSPATH}
find . -print | cpio -c -o | gzip -9 > /opt/myroot.img.gz
popd
}
