#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -e -o pipefail -o errexit

#run function
function run {
  debug "$@";
  if [ "${DRY_RUN}" != "--dry-run" ]; then "$@"; fi;
}

#debug function
function debug {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@";
}

function prepare {
  sudo chown -R root:root /tmp/saltstack
}

function highstate {
  local saltenv=${1}
  sudo mkdir -p /srv/salt/${saltenv} /srv/pillar/${saltenv}
  sudo mv /tmp/saltstack/${saltenv}/salt/* /srv/salt/${saltenv}
  sudo mv /tmp/saltstack/${saltenv}/pillar/* /srv/pillar/${saltenv}
  salt-call --local state.highstate saltenv=${saltenv} --retcode-passthrough -l info --log-file=/tmp/salt-build-${saltenv}.log --config-dir=/tmp/saltstack/config
}

: ${CUSTOM_IMAGE_TYPE:=$1}

case ${CUSTOM_IMAGE_TYPE} in
  base|"")
   echo "Running highstate for Base.."
   prepare
   highstate "base"
   ;;
 hortonworks)
   echo "Running highstate for Base and Hortonworks.."
   prepare
   highstate "base"
   highstate "hortonworks"
   ;;
 *)
  echo "Unsupported CUSTOM_IMAGE_TYPE:" ${CUSTOM_IMAGE_TYPE}
  exit 1
  ;;
esac