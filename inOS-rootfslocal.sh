#!/bin/bash 

function buildrootfslocal {

yum --installroot=${ROOTFSPATH} --disablerepo=* --enablerepo=inos install yum initscripts passwd rsyslog vim-minimal openssh-server openssh-clients dhclient chkconfig rootfiles policycoreutils cronie docker-ce kernel --nogpgcheck -y
echo "root:$ROOTPW" | chroot ${ROOTFSPATH} chpasswd
sed -i '/^SELINUX=/s/enforcing/disabled/g' ${ROOTFSPATH}/etc/selinux/config
sed -i '/native\.cgroupdriver/s/systemd/cgroupfs/' ${ROOTFSPATH}/usr/lib/systemd/system/docker.service

touch ${ROOTFSPATH}/etc/sysconfig/network
cat > ${ROOTFSPATH}/etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
NM_CONTROLLED=no
TYPE=Ethernet
EOF

cp ${ROOTFSPATH}/boot/vmlinuz-*x86_64 ${BOOTPATH}/vmlinuz-3.10.0-inOS

if [ "$TARGET" != "docker" ]
then
buildk8senvironment
fi

echo "Now compress rootfs image"
pushd ${ROOTFSPATH}
find . -print | cpio -c -o | gzip -9 > /opt/rootfs.img.gz
popd
}
