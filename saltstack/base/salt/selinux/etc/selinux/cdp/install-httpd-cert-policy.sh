#!/bin/bash

set -e

SELINUX_CDP_DIR=/etc/selinux/cdp

checkmodule -M -m -o $SELINUX_CDP_DIR/httpd_cert_policy.mod $SELINUX_CDP_DIR/httpd_cert_policy.te
semodule_package -o $SELINUX_CDP_DIR/httpd_cert_policy.pp -m $SELINUX_CDP_DIR/httpd_cert_policy.mod
semodule -i $SELINUX_CDP_DIR/httpd_cert_policy.pp

mkdir -p /etc/certs

semanage fcontext -a -t httpd_cert_t '/etc/certs(/.*)?'
restorecon -Rv /etc/certs