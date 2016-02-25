#!/bin/bash

set -x
set

: ${CLOUD_PLATFORM:? required}
: ${START_LABEL:? required}
: ${PLATFORM_DISK_PREFIX:? required}
: ${IS_GATEWAY:? required}
: ${TMP_SSH_KEY:? required}
: ${PUBLIC_SSH_KEY:? required}
: ${RELOCATE_DOCKER:? required}
: ${SSH_USER:? required}

setup_tmp_ssh() {
  echo "#tmpssh_start" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "$TMP_SSH_KEY" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "#tmpssh_end" >> /home/${SSH_USER}/.ssh/authorized_keys
}

append_aws_ssh_user_key() {
    SSH_DIR="/home/$SSH_USER/.ssh"
    mkdir -p $SSH_DIR
    cat /home/ec2-user/.ssh/authorized_keys >> $SSH_DIR/authorized_keys
    chown -R $SSH_USER:$SSH_USER $SSH_DIR
    chmod 644 $SSH_DIR/authorized_keys
}

get_ip() {
  ifconfig eth0 | awk '/inet addr/{print substr($2,6)}'
}

fix_hostname() {
  if grep -q $(get_ip) /etc/hosts ;then
    sed -i "/$(get_ip)/d" /etc/hosts
  else
    echo OK
  fi
}

extend_rootfs() {
  # Usable on GCP, does not harm anywhere else
  root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
  growpart $root_fs_device 1 || :
  xfs_growfs / || :
}

relocate_docker() {
  if [[ $CLOUD_PLATFORM == AZURE* ]] && [ -n "$(mount | grep ' /mnt/resource ')" ]; then
      touch /var/docker-relocate
      mv /var/lib/docker /mnt/resource/docker
      ln -s /mnt/resource/docker /var/lib/docker
  fi
}

format_disks() {
  mkdir /hadoopfs
  for (( i=1; i<=24; i++ )); do
    LABEL=$(printf "\x$(printf %x $((START_LABEL+i)))")
    DEVICE=/dev/${PLATFORM_DISK_PREFIX}${LABEL}
    if [ -e $DEVICE ]; then
      MOUNTPOINT=$(grep $DEVICE /etc/fstab | tr -s ' \t' ' ' | cut -d' ' -f 2)
      if [ -n "$MOUNTPOINT" ]; then
        umount "$MOUNTPOINT"
        sed -i "\|^$DEVICE|d" /etc/fstab
      fi
      mkfs -E lazy_itable_init=1 -O uninit_bg -F -t ext4 $DEVICE
      mkdir /hadoopfs/fs${i}
      echo $DEVICE /hadoopfs/fs${i} ext4  defaults,noatime 0 2 >> /etc/fstab
      mount /hadoopfs/fs${i}
      chmod 777 /hadoopfs/fs${i}
    fi
  done
  cd /hadoopfs/fs1 && mkdir logs logs/ambari-server logs/ambari-agent logs/consul-watch logs/kerberos
}

release_udev_cookie() {
cat>/tmp/cookie.sh<<"EOF"
: ${LOGFILE:=/var/log/cookie.log}
: ${LAST_CONTAINER:=baywatch}
: ${TIMEOUT:=2}
echo "Cookie script started at $(date)" >> $LOGFILE
while [ $(docker ps 2>/dev/null | grep $LAST_CONTAINER -c) -eq 0 ]; do
  dmsetup udevcookies | grep -v Semid | while read line; do
    COOKIE=$(echo $line|cut -f 1 -d ' ')
    COOKIE_UPDATE=$(echo $line | awk '{print $4,$5,$6,$7,$8}')
    ELAPSED_SEC=$((`date +%s`-`date -d "$COOKIE_UPDATE" +%s`))
    ELAPSED_MIN=$((ELAPSED_SEC/60))
    echo "Elapsed time for cookie: $COOKIE is: $ELAPSED_MIN min" >> $LOGFILE
    if [ $ELAPSED_MIN -gt $TIMEOUT ]; then
      echo "Cookie ($COOKIE) stuck, release it" >> $LOGFILE
      dmsetup udevcomplete $COOKIE
    fi
  done
  sleep 65
done
echo "Cookie script finished at $(date)" >> $LOGFILE
EOF
chmod +x /tmp/cookie.sh
nohup /tmp/cookie.sh &
}

reload_sysconf() {
  sysctl -p
}

main() {
  reload_sysconf
  if [[ "$1" == "::" ]]; then
    shift
    eval "$@"
  elif [ ! -f "/var/cb-init-executed" ]; then
    [[ "$IS_GATEWAY" == "true" ]] && setup_tmp_ssh
    [[ "$RELOCATE_DOCKER" == "true" ]] &&  relocate_docker
    [[ `getent passwd ec2-user` ]] && [[ "ec-2user" != "$SSH_USER" ]] && append_aws_ssh_user_key
    extend_rootfs
    format_disks
    fix_hostname
    release_udev_cookie
    echo $(date +%Y-%m-%d:%H:%M:%S) >> /var/cb-init-executed
  fi
  [ -e /usr/bin/ssh-aliases ] && /usr/bin/ssh-aliases create
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
