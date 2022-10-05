#!/usr/bin/env bash
set -xe

if [ -f /etc/redhat-release ]; then
    sudo yum install -y epel-release 
    sudo yum install -y -q ddpt 
else
    sudo sed -i 's/http:\/\/archive.ubuntu.com/http:\/\/us-west-1.ec2.archive.ubuntu.com/' /etc/apt/sources.list
    sudo apt-get clean
    sudo apt-get update
    sudo apt-get install -y ddpt
fi

OFFSET=1048576
if [ "$OS" == "redhat8" ]; then
    OFFSET=2097152
fi

sudo sysctl kernel.dmesg_restrict=0
sudo mkdir /image
sudo dd if=/dev/xvdb of=/image/sparse.img bs=1M status=progress
blkid /image/sparse.img
sudo fdisk -l /image/sparse.img
sudo mkdir /loop
sudo mount -t xfs -o loop,discard,offset=$OFFSET -o nouuid /image/sparse.img /loop
sudo fstrim /loop
sudo umount /loop
sudo ddpt of=/dev/xvdc if=/image/sparse.img bs=1M oflag=sparse