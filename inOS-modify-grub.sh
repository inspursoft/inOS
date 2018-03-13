#!/bin/bash 
sed -i '$a\menuentry "inOS-docker" {' /boot/grub2/grub.cfg
sed -i '$a\set root="hd0,msdos1"' /boot/grub2/grub.cfg
sed -i '$a\    linux /vmlinuz-3.10.0-inOS_docker quiet' /boot/grub2/grub.cfg
sed -i '$a\    initrd /initrd.img.gz' /boot/grub2/grub.cfg
sed -i '$a\}' /boot/grub2/grub.cfg
