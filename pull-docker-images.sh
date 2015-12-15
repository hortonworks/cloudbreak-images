#!/bin/bash

[[ "$TRACE" ]] && set -x || :
set -eo pipefail

debug() {
  [[ "$DEBUG" ]] && echo "-----> $*" 1>&2
}

init() {
  : ${DEBUG:=1}
}

docker_pull_images() {
  time (echo ${IMAGES:? required} | xargs -n1 -P 20  docker pull)
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


main() {
  init
  reinstall_docker
  start_docker
  docker_pull_images "$@"
  reset_docker
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
