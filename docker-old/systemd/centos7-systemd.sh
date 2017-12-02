#!/bin/bash

# set -eiuo pipefail

## Cloudbreak related setup
if [[ -f "/etc/cloudbreak-config.props" ]]; then
    set -x
    source /etc/cloudbreak-config.props

    mkdir -p /home/${sshUser}/.ssh
    chmod 700 /home/${sshUser}/.ssh
    echo "${sshPubKey}" >> /home/${sshUser}/.ssh/authorized_keys
    chown -R ${sshUser}:${sshUser} /home/${sshUser}

    echo "${userData}" | base64 -d > /usr/bin/cb-init.sh
    chmod +x /usr/bin/cb-init.sh
    /usr/bin/cb-init.sh
fi

env | sort > /env-at-init.log

cp /etc/resolv.conf.ycloud /etc/resolv.conf

exec -l /usr/lib/systemd/systemd --system
