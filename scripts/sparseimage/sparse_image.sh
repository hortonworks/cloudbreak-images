#!/usr/bin/env bash
set -xe

if [ -f /etc/redhat-release ]; then
    sudo yum install -y epel-release
    sudo yum install -y -q ddpt
else
    sudo apt-get install -y ddpt
fi

sudo sfdisk /dev/xvdd <<EOF
;
;
;
;
EOF
sudo mkfs.xfs /dev/xvdd1
    sudo mkdir /image
    sudo mount -t xfs /dev/xvdd1 /image
    sudo dd if=/dev/xvdb of=/image/sparse.img bs=1M status=progress
    sudo mkdir /loop
    sudo mount -t xfs -o loop,discard,offset=1048576 -o nouuid /image/sparse.img /loop
    sudo fstrim /loop
    sudo umount /loop
    sudo ddpt of=/dev/xvdc if=/image/sparse.img bs=1M oflag=sparse
