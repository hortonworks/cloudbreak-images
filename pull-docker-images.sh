#!/bin/bash

[[ "$TRACE" ]] && set -x || :
set -eo pipefail

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

init() {
  : ${DEBUG:=1}
}

extend_rootfs() {
  if [[ $PACKER_BUILDER_TYPE == "googlecompute" ]]; then
      yum -y install cloud-utils-growpart

      root_fs_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed s/1//g)
      growpart $root_fs_device 1 || :
      xfs_growfs / || :
  fi
}

docker_pull_images() {
  time (echo ${IMAGES:? required} | xargs -n 1 | sort -u | xargs -n1 -P 20  docker pull)
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


main() {
  init
  extend_rootfs
  start_docker
  docker_pull_images "$@"
  reset_docker
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
