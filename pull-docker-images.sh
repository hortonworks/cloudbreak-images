#!/bin/bash

set -eo pipefail
[[ "$TRACE" ]] && set -x || :

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

start_docker() {
  service docker start
}

reset_docker() {
  service docker stop
  echo "Deleting key.json in order to avoid swarm conflicts"
  rm -vf /etc/docker/key.json
}


main() {
  init
  start_docker
  docker_pull_images "$@"
  reset_docker
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || :
