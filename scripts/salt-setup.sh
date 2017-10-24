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

function highstate_base {
  sudo mkdir -p /srv/salt/base /srv/pillar/base
  sudo mv /tmp/saltstack/base/salt/* /srv/salt/base
  sudo mv /tmp/saltstack/base/pillar/* /srv/pillar/base
  salt-call --local state.highstate saltenv=base --retcode-passthrough -l info --log-file=/tmp/salt-build.log --config-dir=/tmp/saltstack/config
}

function highstate_hortonworks {
  sudo mkdir -p /srv/salt/hortonworks /srv/pillar/hortonworks
  sudo mv /tmp/saltstack/hortonworks/salt/* /srv/salt/hortonworks
  sudo mv /tmp/saltstack/hortonworks/pillar/* /srv/pillar/hortonworks
  salt-call --local state.highstate saltenv=hortonworks --retcode-passthrough -l info --log-file=/tmp/salt-build.log --config-dir=/tmp/saltstack/config
}

: ${CUSTOM_IMAGE_TYPE:=$1}

case ${CUSTOM_IMAGE_TYPE} in
  base|"")
   echo "Running highstate for Base.."
   prepare
   highstate_base
   ;;
 hortonworks)
   echo "Running highstate for Base and Hortonworks.."
   prepare
   highstate_base
   highstate_hortonworks
   ;;
 *)
  echo "Unsupported CUSTOM_IMAGE_TYPE:" ${CUSTOM_IMAGE_TYPE}
  exit 1
  ;;
esac
