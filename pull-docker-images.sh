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
  : ${DOCKER_IMAGES_DIR:=/var/lib/docker-images}
  : ${XARGS_PARALLEL:=}
  # : ${XARGS_PARALLEL:="-P 20"}
}

docker_pull_images() {
  time (echo ${IMAGES:? required} | xargs -n1 -P 20 docker pull)

  # save images as tar file on azure
  if [[ $PACKER_BUILDER_TYPE =~ azure ]] ; then
    mkdir -p $DOCKER_IMAGES_DIR
    export DOCKER_IMAGES_DIR
    time (echo $IMAGES | xargs -n1 | xargs -n1 $XARGS_PARALLEL -I@ bash -c 'IMAGE=@; IMG=${IMAGE//\//_}; docker save -o $DOCKER_IMAGES_DIR/${IMG/:/_}.tar @')
  fi
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
  if [[ $PACKER_BUILDER_TYPE == "googlecompute" ]]; then
      yum -y install cloud-utils-growpart

      root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
      growpart $root_fs_device 1 || :
      xfs_growfs / || :
  fi
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

#Add sudo rights to OS_USER, needs to be removed after a new base image is used
grant_sudo_to_os_user() {
    echo "$OS_USER ALL=NOPASSWD: ALL" > /etc/sudoers.d/$OS_USER
    chmod o-r /etc/sudoers.d/$OS_USER
}

main() {
  init
  extend_rootfs
  configure_cloud_init
  modify_waagent
  grant_sudo_to_os_user
  start_docker
  docker_pull_images "$@"
  systemctl enable docker.service
  reset_docker
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
