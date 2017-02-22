#!/usr/bin/env bash

set -e -o pipefail

# pull in default settings
[ -e /etc/default/node_exporter ] && . /etc/default/node_exporter

/usr/local/bin/node_exporter $DAEMON_ARGS &
echo $! >| /var/run/node_exporter.pid