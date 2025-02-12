#!/bin/bash

set -e

SELINUX_CDP_DIR=/etc/selinux/cdp

checkmodule -M -m -o $SELINUX_CDP_DIR/hostname_policy.mod $SELINUX_CDP_DIR/hostname_policy.te
semodule_package -o $SELINUX_CDP_DIR/hostname_policy.pp -m $SELINUX_CDP_DIR/hostname_policy.mod
semodule -i $SELINUX_CDP_DIR/hostname_policy.pp
