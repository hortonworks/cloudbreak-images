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
: ${RELOCATE_DOCKER:? required}
: ${SSH_USER:? required}
: ${DOCKER_IMAGES_DIR:=/var/lib/docker-images}
: ${XARGS_PARALLEL:=}
# : ${XARGS_PARALLEL:="-P 20"}

setup_tmp_ssh() {
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

extend_rootfs() {
  # Usable on GCP, does not harm anywhere else
  root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
  growpart $root_fs_device 1 || :
  xfs_growfs / || :
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

relocate_docker() {
  if [[ $CLOUD_PLATFORM == AZURE* ]] && [ -n "$(mount | grep ' /mnt/resource ')" ] && [ ! -f /var/docker-relocate ]; then
      touch /var/docker-relocate
      systemctl stop docker
      mv /var/lib/docker /var/lib/docker-backup
      mkdir -p /mnt/resource/docker
      ln -s /mnt/resource/docker /var/lib/docker
      systemctl start docker
      while ! docker run --rm tianon/true; do
        echo -n .
        sleep 1
      done
      time (ls -1 $DOCKER_IMAGES_DIR | xargs -n1 $XARGS_PARALLEL -I@ bash -c "time docker load -i $DOCKER_IMAGES_DIR/@")
      #release_udev_cookie
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

main() {
  reload_sysconf
  if [[ "$1" == "::" ]]; then
    shift
    eval "$@"
  elif [ ! -f "/var/cb-init-executed" ]; then
    extend_rootfs
    format_disks
    fix_hostname
    # release_udev_cookie
    [[ "$IS_GATEWAY" == "true" ]] && setup_tmp_ssh
    [[ "$RELOCATE_DOCKER" == "true" ]] &&  relocate_docker
    echo $(date +%Y-%m-%d:%H:%M:%S) >> /var/cb-init-executed
  fi
  [ -e /usr/bin/ssh-aliases ] && /usr/bin/ssh-aliases create
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
