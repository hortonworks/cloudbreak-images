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

setup_tmp_ssh() {
  mkdir -p /home/${SSH_USER}/.ssh
  echo "#tmpssh_start" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "$TMP_SSH_KEY" >> /home/${SSH_USER}/.ssh/authorized_keys
  echo "#tmpssh_end" >> /home/${SSH_USER}/.ssh/authorized_keys
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

format_disks() {
  local disks=( $(list_attached_disks) )
  if [[ $CLOUD_PLATFORM == AZURE* ]] && [ "${#disks[*]}" -gt "$LAZY_FORMAT_DISK_LIMIT" ]; then
    format_disks_with_itable_init "${disks[@]}"
    mount_disks "${disks[@]}"
  else
    lazy_format_disks
  fi
  cd /hadoopfs/fs1 && mkdir logs logs/ambari-server logs/ambari-agent logs/consul-watch logs/kerberos
}

list_attached_disks() {
  local ind=0
  local disks=()
  for (( i=1; i<=24; i++ )); do
    label=$(printf "\x$(printf %x $((START_LABEL+i)))")
    device=/dev/${PLATFORM_DISK_PREFIX}${label}
    if [ -e $device ]; then
      disks[$ind]=$device
      (( ind++ ))
    fi
  done
  echo "${disks[*]}"
}

format_disks_with_itable_init() {
  local disks=( "${@}" )
  for disk in "${disks[@]}"; do
    MOUNTPOINT=$(grep $disk /etc/fstab | tr -s ' \t' ' ' | cut -d' ' -f 2)
    if [ -n "$MOUNTPOINT" ]; then
      umount "$MOUNTPOINT"
      sed -i "\|^$disk|d" /etc/fstab
    fi
    mkfs -E lazy_itable_init=0,lazy_journal_init=0 -O uninit_bg -F -t ext4 $disk &
  done
  wait
}

mount_disks() {
  local disks=( "${@}" )
  mkdir /hadoopfs
  for (( i=0; i<$(( ${#disks[@]} )); i++ )); do
    mountPoint="/hadoopfs/fs$(( i+1 ))"
    mkdir $mountPoint
    echo UUID=$(blkid -o value ${disks[i]} | head -1) $mountPoint ext4  defaults,noatime,nofail 0 2 >> /etc/fstab
    mount $mountPoint
    chmod 777 $mountPoint
  done
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
