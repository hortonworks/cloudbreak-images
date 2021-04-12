#!/bin/bash -ux
#
# Copyright (C) 2020 Cloudera, Inc.
#

SCRIPT=`basename "$0"`
LOG_PATH="/var/log/ccmv2-inverting-proxy-agent.log"
CONFIG_FILE="/cdp/bin/ccmv2/config.toml"

exec /cdp/bin/ccmv2/inverting-proxy-agent -config-file ${CONFIG_FILE} >> "$LOG_PATH" 2>&1
