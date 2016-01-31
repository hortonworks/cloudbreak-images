#!/bin/bash

set -eo pipefail

[[ "$TRACE" ]] && set -x

: ${DEBUG:=1}

debug() {
    [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

reset_hostname() {
  echo "Avoid pre-assigned hostname"
  rm -vf /etc/hostname
}

reset_docker() {
  service docker stop
  echo "Deleting key.json in order to avoid swarm conflicts"
  rm -vf /etc/docker/key.json
}

reset_fstab() {
  echo "Removing ephemeral /dev/xvdb from fstab"
  cat /etc/fstab
  sed -i "/dev\/xvdb/ d" /etc/fstab
}

main() {
  reset_hostname
  reset_docker
  reset_fstab
  yum clean all
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
