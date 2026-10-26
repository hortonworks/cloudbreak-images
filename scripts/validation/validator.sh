#!/bin/bash

set -ex

echo Setting up SaltStack files...
mv /tmp/saltstack-validator /opt/validation-scripts/saltstack

echo Launching SaltStack highstate...
${SALT_PATH}/bin/salt-call --no-color --local state.highstate saltenv=validation -l info --log-file=/tmp/salt-validator.log --log-file-level=info --config-dir=/opt/validation-scripts/saltstack/config
