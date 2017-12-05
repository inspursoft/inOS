#!/bin/bash 
: ${root_password='inspuros'}

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


pushd ~/rpmbuild/SPECS
yum-builddep kernel.spec -y
rpmbuild -ba kernel.spec
popd

wget -c https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && rpm -ivh epel-release-latest-7.noarch.rpm

yum  -y install lxc*

setenforce 0
lxc-create --name docker -t /usr/share/lxc/templates/lxc-centos
echo "root:$root_password" | chroot /var/lib/lxc/docker/rootfs chpasswd

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
cp /etc/yum.repos.d/docker-ce.repo /var/lib/lxc/docker/rootfs/etc/yum.repos.d/
yum -y --installroot=/var/lib/lxc/docker/rootfs install docker-ce
sed -i '/^SELINUX=/s/enforcing/disabled/g' /var/lib/lxc/docker/rootfs/etc/selinux/config

yum -y --installroot=/var/lib/lxc/docker/rootfs install ~/rpmbuild/RPMS/x86_64/kernel-3.10.0-693.5.2.el7.x86_64.rpm

cp /var/lib/lxc/docker/rootfs/boot/vmlinuz-3.10.0-693.5.2.el7.x86_64 /boot/

dd if=/dev/zero of=/mnt/initrd.image bs=4096 count=1048576
mke2fs -F -m 0 -b 4096 /mnt/initrd.image 1048576
mkdir /ramdisk
mount -o loop /mnt/initrd.image /ramdisk

pushd /var/lib/lxc/docker/rootfs
find . -print | cpio -c -o > /mnt/docker.img
popd

pushd /ramdisk
cpio -id < /mnt/docker.img
popd

pushd /mnt
umount /ramdisk
gzip -9 initrd.image
mv initrd.image.gz /boot
popd

sed -i '$a\menuentry "inOS-docker" {' /boot/grub2/grub.cfg
sed -i '$a\set root="hd0,msdos1"' /boot/grub2/grub.cfg
sed -i '$a\    linux /vmlinuz-3.10.0-693.5.2.el7.x86_64 ramdisk_size=4194304 quiet' /boot/grub2/grub.cfg
sed -i '$a\    initrd /initrd.image.gz' /boot/grub2/grub.cfg
sed -i '$a\}' /boot/grub2/grub.cfg

echo "Now you can reboot your system and enter inOS-docker"
echo "The inOS-docker root password:$root_password"
