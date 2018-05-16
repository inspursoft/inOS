#!/bin/bash 
function modifygrublocal {
echo "Now modify the grub for inOS"
grub2-install --root-directory=${BOOTPATH} ${DISKNAME}
cat > ${BOOTPATH}/boot/grub2/grub.cfg << EOF
set timeout=5
menuentry "inOS-docker" {
        insmod gzio
        insmod part_gpt
        insmod xfs
        set root='hd0,gpt2'
        linux /vmlinuz-3.10.0-inOS net.ifnames=0 biosdevname=0
        initrd /initrd.img.gz
}
EOF
}
