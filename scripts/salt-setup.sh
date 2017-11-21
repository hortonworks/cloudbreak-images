#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}
: ${ORACLE_JDK8_URL_RPM:="http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm"}
export ORACLE_JDK8_URL_RPM

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

function copy_resources {
  local saltenv=${1}
  sudo mkdir -p /srv/salt/${saltenv} /srv/pillar/${saltenv}
  sudo cp -R /tmp/saltstack/${saltenv}/salt/* /srv/salt/${saltenv}
  if [ -d "/tmp/saltstack/${saltenv}/pillar" ]
  then
    sudo cp -R /tmp/saltstack/${saltenv}/pillar/* /srv/pillar/${saltenv}
  fi
}

function highstate {
  local saltenv=${1}
  copy_resources ${saltenv}
  salt-call --local state.highstate saltenv=${saltenv} --retcode-passthrough -l info --log-file=/tmp/salt-build-${saltenv}.log --config-dir=/tmp/saltstack/config
}

function apply_optional_states {
  if [ -n "${OPTIONAL_STATES}" ]
  then
    local saltenv="optional"
    copy_resources ${saltenv}
    echo "Running applying optional states: ${OPTIONAL_STATES}"
    salt-call --local state.sls ${OPTIONAL_STATES} saltenv=${saltenv} --retcode-passthrough -l info --log-file=/tmp/salt-build-${saltenv}.log --config-dir=/tmp/saltstack/config
  fi
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

apply_optional_states

echo "Running validation and cleanup"
highstate "final"
