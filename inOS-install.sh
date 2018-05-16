#!/bin/bash
setenforce 0
mkdir -p /mnt/{boot,rootfs,initrd}
pushd /opt/inOS
. ./inOS-functionlocal

echo "Choose the target you want to build:"
echo "(docker/kubemaster/kubenode)"

while read TARGET
do
if [ "$TARGET" != "docker" ] && [ "$TARGET" != "kubemaster" ] && [ "$TARGET" != "kubenode" ]
then
echo "Target is wrong. You can choose docker/kubemaster/kubenode"
else
break
fi
done

if [ "$TARGET" != "docker" ]
then
echo "Set the master ip:"
read MASTERIP
if [ "$INOSTARGET" = "kubenode" ]
then
echo "Set the node ip:"
read NODEIP
fi
fi

parted -s ${DISKNAME} mklabel gpt
parted -s ${DISKNAME} mkpart 'non-fs 0 2MB'
parted -s ${DISKNAME} mkpart 'BOOT 2MB 5GB'
parted -s ${DISKNAME} mkpart 'DATA 5GB -1'
parted -s ${DISKNAME} set 1 bios_grub on

mkfs.xfs ${DISKNAME}2 -f
mkfs.xfs ${DISKNAME}3 -f

mount ${DISKNAME}2 ${BOOTPATH}

buildrootfslocal
buildinitrdlocal
modifygrublocal

umount ${BOOTPATH}
popd
