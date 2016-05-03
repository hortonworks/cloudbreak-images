#!/bin/bash

set -eo pipefail
if [[ "$TRACE" ]]; then
    : ${START_TIME:=$(date +%s)}
    export START_TIME
    export PS4='+ [TRACE $BASH_SOURCE:$LINENO][ellapsed: $(( $(date +%s) -  $START_TIME ))] '
    set -x
fi

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

init() {
  : ${DEBUG:=1}
}

extend_rootfs() {
  yum -y install cloud-utils-growpart

  # Usable on GCP, does not harm anywhere else
  root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
  growpart $root_fs_device 1 || :
  xfs_growfs / || :
}

configure_cloud_init() {
  if [ -f /etc/cloud/cloud.cfg ]; then
    #/etc/sysconfig/network is not used by CentOS 7 anymore
    sed -i.bak '/syslog_fix_perms: ~/a preserve_hostname: true' /etc/cloud/cloud.cfg
    diff /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.bak || :
  fi
}


modify_waagent() {
  if [ -f /etc/waagent.conf ]; then
    cp /etc/waagent.conf /etc/waagent.conf.bak
    sed -i 's/Provisioning.SshHostKeyPairType.*/Provisioning.SshHostKeyPairType=ecdsa/' /etc/waagent.conf
    sed -i 's/Provisioning.DecodeCustomData.*/Provisioning.DecodeCustomData=y/' /etc/waagent.conf
    sed -i 's/Provisioning.ExecuteCustomData.*/Provisioning.ExecuteCustomData=y/' /etc/waagent.conf
    diff /etc/waagent.conf /etc/waagent.conf.bak || :
  fi
}



main() {
  init
  extend_rootfs
  configure_cloud_init
  modify_waagent
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
