#!/bin/bash
yum -y install libvirt* yum-utils epel-release
yum -y install lxc*

#yum -y --installroot=/var/lib/lxc/install/rootfs --disablerepo=* --enablerepo=inos install anaconda-core tmux libvirt* yum-utils epel-release
#yum -y --installroot=/var/lib/lxc/install/rootfs install lxc*
lxc-create --name iso -t /usr/share/lxc/templates/lxc-centos

#pushd /var/lib/lxc/iso/rootfs/etc/yum.repos.d
yum -y --installroot=/var/lib/lxc/iso/rootfs install parted grub2-tools kernel anaconda-core tmux xfsprogs grub2-pc-modules
pushd /var/lib/lxc/iso/rootfs/etc/systemd/system/
unlink default.target
ln -sv /usr/lib/systemd/system/anaconda.target default.target
popd

pushd /var/lib/lxc/iso/rootfs/etc/yum.repos.d
cat > inos.repo << EOF
[inos]
name=inos
baseurl=file:///opt/inOS/repos
gpgcheck=0
EOF
popd

pushd /var/lib/lxc/iso/rootfs/usr/lib/systemd/system
mkdir anaconda.target.wants/
cd anaconda.target.wants/
ln -sv /lib/systemd/system/anaconda-nm-config.service .
ln -sv /lib/systemd/system/anaconda-pre.service .
ln -sv /lib/systemd/system/anaconda-tmux@.service anaconda-tmux@tty1.service
popd


pushd /var/lib/lxc/iso/rootfs/usr/share/anaconda
sed -i '/new-window.*tail/d' tmux.conf
sed -i '/new-session/s@\"anaconda\"@\"/opt/inOS/inOS-install.sh\"@' tmux.conf
popd

cp  -r /opt/inOS /var/lib/lxc/iso/rootfs/opt/

pushd /var/lib/lxc/iso/rootfs
ln -sv /usr/lib/systemd/systemd init
find . -print | cpio -c -o | gzip -9 > /boot/iso.img.gz
popd


