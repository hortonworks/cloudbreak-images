#!/bin/bash

#Print disk & partition sizes
lsblk
df -h


if [ "${CLOUD_PROVIDER}" == "Azure" ] ; then
  PV_NAME=$(pvs --noheadings --rows | head -1 | tr -d '[:space:]')
  DISK="/dev/$(lsblk -ndo PKNAME "$PV_NAME")"
  PARTITION=$(cat "/sys/class/block/$(basename "$PV_NAME")/partition")
  # Relocating backup data structures to the end of the disk
  printf "x\ne\nw\nY\n" | gdisk $DISK
  # Resize partition to the end of the disk
  parted -s -a opt $DISK "resizepart $PARTITION 100%"
  # Resize physical volume
  pvresize $PV_NAME
  # Extend logical volumes to satisfy CM free space checks and allocate remaining free space
  lvextend -r -l +100%FREE /dev/mapper/rootvg-rootlv
fi