#!/bin/bash
START_LABEL=61
for (( i=1; i<=20; i++ )); do
  LABEL=$(printf "\x$((START_LABEL+i))")
  if [ -e /dev/sd"$LABEL" ]; then
    mkfs -F -t ext4 /dev/sd${LABEL}
    mkdir /mnt/fs${i}
    mount /dev/sd${LABEL} /mnt/fs${i} ext4 defaults 0 2 >> /etc/fstab
    DOCKER_VOLUME_PARAMS="${DOCKER_VOLUME_PARAMS} -v /mnt/fs${i}:/mnt/fs${i}"
  fi
done