#!/bin/bash
START_LABEL=65
mkdir /hadoopfs
for (( i=1; i<=15; i++ )); do
  LABEL=$(printf "\x$((START_LABEL+i))")
  if [ -e /dev/xvd"$LABEL" ]; then
    mkfs -t ext4 /dev/xvd${LABEL}
    mkdir /hadoopfs/fs${i}
    echo /dev/xvd${LABEL} /hadoopfs/fs${i} ext4  defaults 0 2 >> /etc/fstab
    mount /hadoopfs/fs${i}
    DOCKER_VOLUME_PARAMS="${DOCKER_VOLUME_PARAMS} -v /hadoopfs/fs${i}:/hadoopfs/fs${i}"
  fi
done