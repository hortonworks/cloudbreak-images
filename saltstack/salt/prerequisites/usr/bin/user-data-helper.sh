#!/bin/bash

set -x
set

: ${CLOUD_PLATFORM:? required}
: ${START_LABEL:? required}
: ${PLATFORM_DISK_PREFIX:? required}
: ${LAZY_FORMAT_DISK_LIMIT:? required}
: ${IS_GATEWAY:? required}
: ${TMP_SSH_KEY:? required}
: ${PUBLIC_SSH_KEY:? required}
: ${SALT_BOOT_PASSWORD:? required}
: ${SALT_BOOT_SIGN_KEY:? required}
: ${SSH_USER:? required}

: ${XARGS_PARALLEL:=}
# : ${XARGS_PARALLEL:="-P 20"}

wait_for_authorized_keys() {
  if [[ $CLOUD_PLATFORM != "GCP" ]]; then return 0; fi
  echo "Wait for /home/${SSH_USER}/.ssh/authorized_keys to be created"
  while [[ ! -f /home/${SSH_USER}/.ssh/authorized_keys ]]; do
    echo "/home/${SSH_USER}/.ssh/authorized_keys does not exist"
    sleep 1
  done
  echo "/home/${SSH_USER}/.ssh/authorized_keys is created"
}

setup_tmp_ssh() {
  wait_for_authorized_keys
  echo "#tmpssh_start" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "$TMP_SSH_KEY" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "#tmpssh_end" >> /home/${SSH_USER}/.ssh/authorized_keys
}

get_ip() {
  ifconfig eth0 | sed -En 's/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'
}

fix_hostname() {
  if grep -q $(get_ip) /etc/hosts ;then
    sed -i "/$(get_ip)/d" /etc/hosts
  else
    echo OK
  fi
}

format_disks() {
  lazy_format_disks
  cd /hadoopfs/fs1 && mkdir logs logs/ambari-server logs/ambari-agent logs/consul-watch logs/kerberos
}

lazy_format_disks() {
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
      echo UUID=$(blkid -o value $DEVICE | head -1) /hadoopfs/fs${i} ext4  defaults,noatime,nofail 0 2 >> /etc/fstab
      mount /hadoopfs/fs${i}
      chmod 777 /hadoopfs/fs${i}
    fi
  done
}

reload_sysconf() {
  sysctl -p
}

configure-salt-bootstrap() {
  mkdir -p /etc/salt-bootstrap
  chmod 700 /etc/salt-bootstrap
  cat > /etc/salt-bootstrap/security-config.yml <<EOF
username: cbadmin
password: ${SALT_BOOT_PASSWORD}
signKey: |-
 -----BEGIN PUBLIC KEY-----
 ${SALT_BOOT_SIGN_KEY}
 -----END PUBLIC KEY-----
EOF
  chmod 600 /etc/salt-bootstrap/security-config.yml
}

main() {
  configure-salt-bootstrap
  reload_sysconf
  if [[ "$1" == "::" ]]; then
    shift
    eval "$@"
  elif [ ! -f "/var/cb-init-executed" ]; then
    format_disks
    fix_hostname
    [[ "$IS_GATEWAY" == "true" ]] && setup_tmp_ssh
    echo $(date +%Y-%m-%d:%H:%M:%S) >> /var/cb-init-executed
  fi
  [ -e /usr/bin/ssh-aliases ] && /usr/bin/ssh-aliases create
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
