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

docker_pull_images() {
  for i in ${IMAGES:? required}; do
    docker pull ${i}
  done
}

reinstall_docker() {
  debug 'reinstall docker as a workaround for failing "docker service start" ... '

  local docker_version=$(docker version -f '{{.Client.Version}}' 2>/dev/null)
  debug "docker version: $docker_version"
    
  service docker stop || :
  rm -rf /var/lib/docker/ /var/run/docker.sock
  yum remove -y docker-engine-${docker_version}
  yum install -y docker-engine-${docker_version}
  systemctl enable docker.service
}

start_docker() {
  debug "starting docker daemon"
  service docker start

  debug "wait for docker daemon responding (max 10 retry)"
  for i in {0..10}; do
      docker version &>/dev/null && break
      echo -n .; sleep ${SLEEP:=3}
  done
}

reset_docker() {
  service docker stop
  echo "Deleting key.json in order to avoid swarm conflicts"
  rm -vf /etc/docker/key.json
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

    sed -i '/ExecStart=/ i ExecStartPre=/usr/bin/docker-helper' /etc/systemd/system/docker.service
  fi
}



main() {
  init
  extend_rootfs
  configure_cloud_init
  modify_waagent
  reinstall_docker
  start_docker
  docker_pull_images "$@"
  reset_docker
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
