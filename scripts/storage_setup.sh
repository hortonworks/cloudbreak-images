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
  elif [[ "${OS}" == "redhat8" || "${OS}" == "redhat9" ]] ; then
    PV_NAME=$(pvs --noheadings --rows | head -1 | tr -d '[:space:]')
    DISK=${PV_NAME//[0-9]/}
    PARTITION=${PV_NAME//[^0-9]/}
    # Relocating backup data structures to the end of the disk
    printf "x\ne\nw\nY\n" | gdisk $DISK
    # Resize partition to the end of the disk
    parted -s -a opt $DISK "resizepart $PARTITION 100%"
    # Resize physical volume
    pvresize $PV_NAME
    # Extend logical volumes to satisfy CM free space checks and allocate remaining free space
    lvextend -r -l +100%FREE /dev/mapper/rootvg-rootlv
  fi
fi