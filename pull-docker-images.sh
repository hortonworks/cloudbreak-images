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

main() {
  init
  docker_pull_images "$@"
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@" || :
