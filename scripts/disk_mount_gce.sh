#!/bin/bash
START_LABEL=61
mkdir /hadoopfs
for (( i=1; i<=15; i++ )); do
  LABEL=$(printf "\x$((START_LABEL+i))")
  if [ -e /dev/sd"$LABEL" ]; then
    mkfs -F -t ext4 /dev/sd${LABEL}
    mkdir /hadoopfs/fs${i}
    echo /dev/sd${LABEL} /hadoopfs/fs${i} ext4  defaults 0 2 >> /etc/fstab
    mount /hadoopfs/fs${i}
    DOCKER_VOLUME_PARAMS="${DOCKER_VOLUME_PARAMS} -v /hadoopfs/fs${i}:/hadoopfs/fs${i}"
  fi
done
