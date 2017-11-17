#!/bin/bash 

yum -y install wget libvirt* yum-utils
yum -y groupinstall "Development" 

#On Nov 10th 2017, latest kernel is: kernel-3.10.0-693.5.2.el7.src.rpm
wget -c http://vault.centos.org/7.4.1708/updates/Source/SPackages/kernel-3.10.0-693.5.2.el7.src.rpm

mkdir -p rpmbuild/{SPECS,SOURCES,BUILD,BUILDROOT,RPMS,SRPMS}
rpm -ivh kernel-3.10.0-693.5.2.el7.src.rpm

sed -i "s/CONFIG_BLK_DEV_RAM=m/CONFIG_BLK_DEV_RAM=y/" rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i "s/CONFIG_BLK_DEV_RAM=m/CONFIG_BLK_DEV_RAM=y/" rpmbuild/SOURCES/kernel-3.10.0-x86_64.config

sed -i '$a\CONFIG_EXT2_FS=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i '$a\CONFIG_EXT2_FS_XATTR=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i '$a\CONFIG_EXT2_FS_POSIX_ACL=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i '$a\CONFIG_EXT2_FS_SECURITY=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config

sed -i '$a\CONFIG_EXT2_FS=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i '$a\CONFIG_EXT2_FS_XATTR=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i '$a\CONFIG_EXT2_FS_POSIX_ACL=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i '$a\CONFIG_EXT2_FS_SECURITY=y' rpmbuild/SOURCES/kernel-3.10.0-x86_64.config


cd ~/rpmbuild/SPECS
yum-builddep kernel.spec
rpmbuild -ba kernel.spec

wget -c https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && rpm -ivh epel-release-latest-7.noarch.rpm

yum  -y install lxc*

lxc-create –name docker –t /usr/share/lxc/templates/lxc-centos

systemctl start libvirtd
lxc-start --name docker

yum -y install yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce

lxc-stop --name docker

yum -y --installroot=/var/lib/lxc/docker/rootfs install ~/rpmbuild/RPMS/x86_64/kernel-3.10.0-693.5.2.el7.x86_64.rpm

cp /var/lib/lxc/docker/rootfs/boot/vmlinuz-3.10.0-693.5.2.el7.x86_64 /boot/

dd if=/dev/zero of=/mnt/initrd.image bs=4096 count=1048576
mke2fs -F -m 0 -b 4096 /mnt/initrd.image 1048576
mkdir /ramdisk
mount -o loop /mnt/initrd.image /ramdisk
cd /var/lib/lxc/docker/rootfs
find . –print | cpio –c –o > /mnt/docker.img
cd /ramdisk
cpio -id < /mnt/docker.img
cd /mnt
umount /ramdisk
gzip -9 initrd.image
mv initrd.image.gz /boot

sed -i '$a\menuentry "inOS-docker" {' /boot/grub2/grub.cfg
sed -i '$a\set root="hd0,msdos1"' /boot/grub2/grub.cfg
sed -i '$a\    linux /vmlinuz-3.10.0-693.5.2.el7.x86_64 ramdisk_size=4194304' /boot/grub2/grub.cfg
sed -i '$a\    initrd /initrd.image.gz' /boot/grub2/grub.cfg
sed -i '$a\}' /boot/grub2/grub.cfg

