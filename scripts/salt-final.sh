#!/bin/bash

: ${DEBUG:=1}
: ${DRY_RUN:-1}

set -ex -o pipefail -o errexit

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
  ${SALT_PATH}/bin/salt-call --no-color --local state.highstate saltenv=${saltenv} -l info --log-file=/tmp/salt-build-${saltenv}.log --log-file-level=info --config-dir=/tmp/saltstack/config
}

echo "Running validation and cleanup"
highstate "final"
