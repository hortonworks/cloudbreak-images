#!/bin/bash
START_LABEL=65
for (( i=1; i<=15; i++ )); do
  LABEL=$(printf "\x$((START_LABEL+i))")
  if [ -e /dev/xvd"$LABEL" ]; then
    mkfs -t ext4 /dev/xvd${LABEL}
    mkdir /mnt/fs${i}
    echo /dev/xvd${LABEL} /mnt/fs${i} ext4  defaults 0 2 >> /etc/fstab
    mount /mnt/fs${i}
    DOCKER_VOLUME_PARAMS="${DOCKER_VOLUME_PARAMS} -v /mnt/fs${i}:/mnt/fs${i}"
  fi
done