#!/bin/bash
lxc-create --name first -t /usr/share/lxc/templates/lxc-centos

cd /var/lib/lxc/first/rootfs/etc
unlink centos-release
unlink os-release
unlink redhat-release
unlink system-release
touch initrd-release

cd ..
ln -sv usr/lib/systemd/systemd init
cp /opt/myroot.img.gz .

cd usr/lib/systemd/system-generators/
rm systemd-cryptsetup-generator systemd-debug-generator systemd-efi-boot-generator systemd-getty-generator systemd-hibernate-resume-generator systemd-rc-local-generator systemd-system-update-generator systemd-sysv-generator -f
cat <<EOF > build-root-generator
#!/bin/bash
mkdir /sysroot
mount -t tmpfs tmpfs /sysroot
pushd /
gunzip /myroot.img.gz
popd
pushd /sysroot
cpio -id < /myroot.img
popd
EOF
chmod +x build-root-generator

cd ../system
rm basic.target.wants/ -rf
rm graphical.target* -rf
rm default.target* -rf
ln -sv initrd.target default.target
rm local-fs.target.wants/ -rf

cd /var/lib/lxc/first/rootfs
find . -print | cpio -c -o | gzip -9 > /boot/initrd.img.gz
