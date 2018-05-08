#!/bin/bash

function buildinitrdlocal {

yum --installroot=${INITRDPATH} --disablerepo=* --enablerepo=inos install yum initscripts passwd rsyslog vim-minimal openssh-server openssh-clients dhclient chkconfig rootfiles policycoreutils cronie kernel --nogpgcheck -y

pushd ${INITRDPATH}/etc
unlink centos-release
unlink os-release
unlink redhat-release
unlink system-release
touch initrd-release
touch sysconfig/network
cat > sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=dhcp
NM_CONTROLLED=no
TYPE=Ethernet
EOF

cd ..
ln -sv usr/lib/systemd/systemd init
echo "Copy the rootfs image into initrd"
cp /opt/rootfs.img.gz .

cd usr/lib/systemd/system-generators/
rm systemd-cryptsetup-generator systemd-debug-generator systemd-efi-boot-generator systemd-getty-generator systemd-hibernate-resume-generator systemd-rc-local-generator systemd-system-update-generator systemd-sysv-generator -f
cat <<EOF > build-root-generator
#!/bin/bash
mkdir /sysroot
mount -t tmpfs tmpfs /sysroot
pushd /
gunzip /rootfs.img.gz
popd
pushd /sysroot
cpio -id < /rootfs.img
popd
EOF
chmod +x build-root-generator

cd ../system
rm basic.target.wants/ -rf
rm graphical.target* -rf
rm default.target* -rf
ln -sv initrd.target default.target
rm local-fs.target.wants/ -rf
popd

echo "Now build the initrd for inOS"
pushd ${INITRDPATH}
find . -print | cpio -c -o | gzip -9 > ${BOOTPATH}/initrd.img.gz
popd
}
