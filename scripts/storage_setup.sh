#!/bin/bash

#Print disk & partition sizes
lsblk
df -h


if [ "${CLOUD_PROVIDER}" == "Azure" ] ; then
  if [ "${OS}" == "centos7" ] ; then
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
  elif [ "${OS}" == "redhat8" ] ; then
    lvextend -r -l +100%FREE /dev/mapper/rootvg-rootlv
  fi
fi