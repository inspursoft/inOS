#!/bin/bash 
MYMASTERNAME=
MYMASTERIP=
MYHOSTNAME=
MYHOSTIP=
MYREGISTRYIP=
ROOTPW=inspuros

function usage {
	echo "inOS-k8s.build.sh [options]"
	echo "	options:"
	echo "		--mastername name: set the kubernetes master name"
	echo "		--masterip ip: set the kubernetes master ip"
	echo "		--hostname name: set this kubernetes node name"
	echo "		--hostip ip: set this kubernetes node ip"
	echo "		--registryip ip: set the registry ip"
	echo "		--rootpasswd passwd: set this kubernetes node's root password"
	echo "		--help: show this usage"
}

set -- `getopt -u -l help,mastername:,masterip:,hostname:,hostip:,rootpasswd:,registryip: -- $0 $@`
while true ; do
	case $1 in
	--help) usage ; exit 1;;
	--mastername) MYMASTERNAME="$2" ; shift 2 ;;
	--masterip) MYMASTERIP="$2" ; shift 2 ;;
	--hostname) MYHOSTNAME="$2" ; shift 2 ;;
	--hostip) MYHOSTIP="$2" ; shift 2 ;;
	--registryip) MYREGISTRYIP="$2" ; shift 2 ;;
	--rootpasswd) ROOTPW="$2" ; shift 2 ;;
	--) shift ; break ;;
	*) usage ; exit 1 ;;
	esac
done

yum -y install wget libvirt* yum-utils
yum -y groupinstall "Development" 

#On Nov 10th 2017, latest kernel is: kernel-3.10.0-693.5.2.el7.src.rpm
wget -c http://vault.centos.org/7.4.1708/updates/Source/SPackages/kernel-3.10.0-693.5.2.el7.src.rpm

mkdir -p ~/rpmbuild/{SPECS,SOURCES,BUILD,BUILDROOT,RPMS,SRPMS}
rpm -ivh kernel-3.10.0-693.5.2.el7.src.rpm

#Add ramdisk support
sed -i "s/CONFIG_BLK_DEV_RAM=m/CONFIG_BLK_DEV_RAM=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i "s/CONFIG_BLK_DEV_RAM=m/CONFIG_BLK_DEV_RAM=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config

#Add ethernet card support
sed -i "s/CONFIG_E1000E=m/CONFIG_E1000E=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i "s/CONFIG_E1000E=m/CONFIG_E1000E=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i "s/CONFIG_PPS=m/CONFIG_PPS=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i "s/CONFIG_PPS=m/CONFIG_PPS=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i "s/CONFIG_PTP_1588_CLOCK=m/CONFIG_PTP_1588_CLOCK=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i "s/CONFIG_PTP_1588_CLOCK=m/CONFIG_PTP_1588_CLOCK=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i "s/CONFIG_FS_MBCACHE=m/CONFIG_FS_MBCACHE=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i "s/CONFIG_FS_MBCACHE=m/CONFIG_FS_MBCACHE=y/" ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config

#Add ext2 support
sed -i '$a\CONFIG_EXT2_FS=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i '$a\CONFIG_EXT2_FS_XATTR=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i '$a\CONFIG_EXT2_FS_POSIX_ACL=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config
sed -i '$a\CONFIG_EXT2_FS_SECURITY=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64-debug.config

sed -i '$a\CONFIG_EXT2_FS=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i '$a\CONFIG_EXT2_FS_XATTR=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i '$a\CONFIG_EXT2_FS_POSIX_ACL=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config
sed -i '$a\CONFIG_EXT2_FS_SECURITY=y' ~/rpmbuild/SOURCES/kernel-3.10.0-x86_64.config


pushd ~/rpmbuild/SPECS
yum-builddep kernel.spec -y
rpmbuild -ba kernel.spec
popd

wget -c https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && rpm -ivh epel-release-latest-7.noarch.rpm

yum  -y install lxc*

setenforce 0
lxc-create --name docker -t /usr/share/lxc/templates/lxc-centos
echo "root:$ROOTPW" | chroot /var/lib/lxc/docker/rootfs chpasswd

yum -y --installroot=/var/lib/lxc/docker/rootfs install kubernetes-client kubernetes-node flannel python-rhsm-certificates
sed -i '/^SELINUX=/s/enforcing/disabled/g' /var/lib/lxc/docker/rootfs/etc/selinux/config
sed -i '/^KUBELET_ADDRESS=/s/127\.0\.0\.1/0\.0\.0\.0/g' /var/lib/lxc/docker/rootfs/etc/kubernetes/kubelet

if [ -n "$MYMASTERNAME" ] && [ -z "$MYMASTERIP" ] 
then
	echo "ERROR: $MYMASTERNAME need ipaddr!"
	exit 1
elif [ -n "$MYMASTERNAME" ] && [ -n "$MYMASTERIP" ]
then
	sed -i "/^KUBE_MASTER=/s/127\.0\.0\.1/${MYMASTERNAME}/g" /var/lib/lxc/docker/rootfs/etc/kubernetes/config
	sed -i "/^KUBELET_API_SERVER=/s/127\.0\.0\.1/${MYMASTERNAME}/g" /var/lib/lxc/docker/rootfs/etc/kubernetes/kubelet
	sed -i "/^FLANNEL_ETCD_ENDPOINTS=/s/127\.0\.0\.1/${MYMASTERNAME}/g" /var/lib/lxc/docker/rootfs/etc/sysconfig/flanneld
	echo "${MYMASTERIP} ${MYMASTERNAME}" /var/lib/lxc/docker/rootfs/etc/hosts
elif [ -n "$MYMASTERIP" ]
then
	sed -i "/^KUBE_MASTER=/s/127\.0\.0\.1/${MYMASTERIP}/g" /var/lib/lxc/docker/rootfs/etc/kubernetes/config
	sed -i "/^KUBELET_API_SERVER=/s/127\.0\.0\.1/${MYMASTERIP}/g" /var/lib/lxc/docker/rootfs/etc/kubernetes/kubelet
	sed -i "/^FLANNEL_ETCD_ENDPOINTS=/s/127\.0\.0\.1/${MYMASTERIP}/g" /var/lib/lxc/docker/rootfs/etc/sysconfig/flanneld
fi

if [ -n "$MYHOSTNAME" ] && [ -z "$MYHOSTIP" ]
then
	echo "ERROR: $MYHOSTNAME need ipaddr!"
	exit 1
elif [ -n "$MYHOSTNAME" ] && [ -n "$MYHOSTIP" ]
then
	sed -i "/^KUBELET_HOSTNAME=/s/127\.0\.0\.1/${MYHOSTNAME}/g" /var/lib/lxc/docker/rootfs/etc/kubernetes/kubelet
	echo "${MYHOSTIP} ${MYHOSTNAME}" >> /var/lib/lxc/docker/rootfs/etc/hosts
elif [ -n "$MYHOSTIP" ]
then
	sed -i "/^KUBELET_HOSTNAME=/s/127\.0\.0\.1/${MYHOSTIP}/g" /var/lib/lxc/docker/rootfs/etc/kubernetes/kubelet
fi

if [ -n "$MYREGISTRYIP" ]
then
	echo "ADD_REGISTRY=\"--insecure-registry ${MYREGISTRYIP}:5000\"" >> /var/lib/lxc/docker/rootfs/etc/sysconfig/docker
fi

mv /var/lib/lxc/docker/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0 /var/lib/lxc/docker/rootfs/etc/sysconfig/network-scripts/ifcfg-enp0s31f6
sed -i "/DEVICE=/s/eth0/enp0s31f6/" /var/lib/lxc/docker/rootfs/etc/sysconfig/network-scripts/ifcfg-enp0s31f6

chroot /var/lib/lxc/docker/rootfs ln -s /usr/lib/systemd/system/flanneld.service /etc/systemd/system/multi-user.target.wants/
mkdir /var/lib/lxc/docker/rootfs/etc/systemd/system/docker.service.requires
chroot /var/lib/lxc/docker/rootfs ln -s /usr/lib/systemd/system/flanneld.service /etc/systemd/system/docker.service.requires
chroot /var/lib/lxc/docker/rootfs ln -s /usr/lib/systemd/system/docker.service /etc/systemd/system/multi-user.target.wants/
chroot /var/lib/lxc/docker/rootfs ln -s /usr/lib/systemd/system/kubelet.service /etc/systemd/system/multi-user.target.wants/
chroot /var/lib/lxc/docker/rootfs ln -s /usr/lib/systemd/system/kube-proxy.service /etc/systemd/system/multi-user.target.wants/

yum -y --installroot=/var/lib/lxc/docker/rootfs install ~/rpmbuild/RPMS/x86_64/kernel-3.10.0-693.5.2.el7.x86_64.rpm

cp /var/lib/lxc/docker/rootfs/boot/vmlinuz-3.10.0-693.5.2.el7.x86_64 /boot/vmlinuz-3.10.0-inOS_kubernetes

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

sed -i '$a\menuentry "inOS-kubernetes" {' /boot/grub2/grub.cfg
sed -i '$a\set root="hd0,msdos1"' /boot/grub2/grub.cfg
sed -i '$a\    linux /vmlinuz-3.10.0-inOS_kubernetes ramdisk_size=4194304 quiet' /boot/grub2/grub.cfg
sed -i '$a\    initrd /initrd.image.gz' /boot/grub2/grub.cfg
sed -i '$a\}' /boot/grub2/grub.cfg

echo "Now you can reboot your system and enter inOS-kubernetes"
echo "The inOS-docker root password:$ROOTPW"
