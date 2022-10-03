#!/bin/bash

#Print disk & partition sizes
lsblk
df -h


if [ "${OS}" == "centos7" ] && [ "${CLOUD_PROVIDER}" == "Azure" ] ; then
    (
    echo d # Delete
    echo 2 # 2nd partition
    echo n # Add a new partition
    echo p # Primary partition
    echo 2 # Partition number
    echo   # First sector (Accept default: 1)
    echo   # Last sector (Accept default: varies)
    echo w # Write changes
    ) | fdisk /dev/sda
    reboot
fi